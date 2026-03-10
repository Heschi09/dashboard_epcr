import 'package:flutter/material.dart';
import '../config/backend_config.dart';
import '../config/general_constants.dart';
import 'backend_service.dart';
import 'package:fhir/r5.dart' as r5;

/// Service for managing Patient Care Reports (ePCRs).
///
/// Interacts with [BackendService] to fetch and map FHIR DiagnosticReports
/// and related clinical data.
class PcrService {
  PcrService._internal();

  static final PcrService instance = PcrService._internal();

  /// Fetches all DiagnosticReports and maps them to a simplified list format.
  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      // Fetch DiagnosticReports (ePCRs)
      String? url =
          '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.diagnosticReportName}?_sort=-date';
      List<r5.DiagnosticReport> reports = [];

      final bundle = await BackendService.getBundle(url);
      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.DiagnosticReport) {
            reports.add(entry.resource as r5.DiagnosticReport);
          }
        }
      }

      List<Map<String, dynamic>> results = [];
      for (var report in reports) {
        results.add(_reportToBasicMap(report));
      }
      return results;
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  Map<String, dynamic> _reportToBasicMap(r5.DiagnosticReport report) {
    // Extract Driver
    String driver = 'N/A';
    if (report.performer != null && report.performer!.length > 2) {
      driver =
          report.performer![2].display ??
          report.performer![2].reference ??
          'N/A';
    }

    // Extract License Plate (Location)
    String licensePlate = 'N/A';
    if (report.extension_ != null && report.extension_!.isNotEmpty) {
      licensePlate =
          report.extension_!.first.valueReference?.reference?.split('/').last ??
          'N/A';
    }

    return {
      'id': report.id?.toString(),
      'status': report.status?.toString(),
      'patient': report.subject?.display ?? 'Unknown Patient',
      'date': report.effectiveDateTime?.toString() ?? '',
      'driver': driver,
      'vehicle': licensePlate,
    };
  }

  /// Fetches a complete report with all its linked resources for detailed viewing.
  ///
  /// Links Observations, Procedures, Medications, and Crew to the DiagnosticReport.
  Future<Map<String, dynamic>> getFullReportData(String reportId) async {
    // Load Report and all linked resources (Observations, Procedures, Patient, Encounter)
    String url =
        '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.diagnosticReportName}?'
        '_id=$reportId'
        '&_include=DiagnosticReport:result' // Root Sections (A,B,C..)
        '&_include:iterate=Observation:has-member' // Findings
        '&_include:iterate=Observation:part-of' // Interventions
        '&_include=DiagnosticReport:patient'
        '&_include=DiagnosticReport:encounter'
        '&_include=DiagnosticReport:performer'; // Crew

    final bundle = await BackendService.getBundle(url);

    r5.DiagnosticReport? report;
    r5.Patient? patient;
    r5.Encounter? encounter;
    List<r5.Observation> observations = [];
    List<r5.Procedure> procedures = [];
    List<r5.MedicationAdministration> meds = [];
    List<r5.Practitioner> practitioners = [];

    if (bundle.entry != null) {
      for (var entry in bundle.entry!) {
        final res = entry.resource;
        if (res is r5.DiagnosticReport) {
          report = res;
        } else if (res is r5.Patient) {
          patient = res;
        } else if (res is r5.Encounter) {
          encounter = res;
        } else if (res is r5.Observation) {
          observations.add(res);
        } else if (res is r5.Procedure) {
          procedures.add(res);
        } else if (res is r5.MedicationAdministration) {
          meds.add(res);
        } else if (res is r5.Practitioner) {
          practitioners.add(res);
        }
      }
    }

    if (report == null) return {};

    // Helper to resolve a full name from a HumanName list
    String resolveName(List<r5.HumanName>? names, String fallback) {
      if (names == null || names.isEmpty) return fallback;
      final name = names.first;
      if (name.text != null && name.text!.isNotEmpty) return name.text!;
      final family = name.family ?? '';
      final given = name.given?.join(' ') ?? '';
      final combined = [given, family].where((s) => s.isNotEmpty).join(' ');
      return combined.isNotEmpty ? combined : fallback;
    }

    // Helper to find Obs by ID
    r5.Observation? findObs(String? ref) {
      if (ref == null) return null;
      final id = ref.split('/').last;
      return observations.firstWhere(
        (o) => o.id?.toString() == id,
        orElse: () => r5.Observation(
          status: r5.FhirCode('final'),
          code: r5.CodeableConcept(text: 'Missing'),
          id: r5.FhirId('missing'),
        ),
      );
    }

    r5.Procedure? findProc(String? ref) {
      if (ref == null) return null;
      final id = ref.split('/').last;
      try {
        return procedures.firstWhere((p) => p.id?.toString() == id);
      } catch (e) {
        return null;
      }
    }

    // Help to find Practitioner by ID
    String resolvePractitioner(r5.Reference? ref) {
      if (ref == null) return 'N/A';
      final id = ref.reference?.split('/').last;
      try {
        final p = practitioners.firstWhere((p) => p.id?.toString() == id);
        return resolveName(p.name, 'N/A');
      } catch (_) {}
      return ref.display ?? ref.reference ?? 'N/A';
    }

    // Map Patient
    String patientName = 'Unknown';
    if (patient != null) {
      patientName = resolveName(patient.name, 'Unknown');
    } else if (report.subject != null) {
      patientName = report.subject!.display ?? report.subject!.reference?.split('/').last ?? 'Unknown';
    }

    String age = 'Unknown';
    if (patient?.birthDate != null) {
      try {
        final bd = DateTime.parse(patient!.birthDate.toString());
        final today = DateTime.now();
        int a = today.year - bd.year;
        if (today.month < bd.month ||
            (today.month == bd.month && today.day < bd.day)) {
          a--;
        }
        age = a.toString();
      } catch (_) {}
    }

    String sex = 'Unknown';
    if (patient?.gender != null) {
      final g = patient!.gender.toString().split('.').last;
      if (g.isNotEmpty) {
        sex = g[0].toUpperCase() + g.substring(1);
      }
    }

    final patientMap = {
      'name': patientName,
      'birthDate': patient?.birthDate?.toString() ?? '',
      'sex': sex,
      'age': age,
    };

    // Map Crew (from Performer: Medic, Physician, Driver)
    String medic = 'N/A';
    String physician = 'N/A';
    String driver = 'N/A';

    if (report.performer != null) {
      if (report.performer!.isNotEmpty) {
        medic = resolvePractitioner(report.performer![0]);
      }
      if (report.performer!.length > 1) {
        physician = resolvePractitioner(report.performer![1]);
      }
      if (report.performer!.length > 2) {
        driver = resolvePractitioner(report.performer![2]);
      }
    }

    // --- DATA RETRIEVAL (Parallel) ---
    r5.Encounter? resolvedEncounter = encounter;
    List<r5.Procedure> fallbackProcedures = [];
    List<r5.MedicationAdministration> fallbackMeds = [];
    List<r5.BundleEntry> allUsageEntries = [];
    List<r5.Observation> equipObs = [];
    List<r5.Device> catalogDevices = [];
    r5.Transport? transport;
    String licensePlate = 'N/A';
    final patientId = patient?.id?.toString();

    await Future.wait<dynamic>([
      // 1. Encounter (if needed)
      if (resolvedEncounter == null && patientId != null)
        BackendService.getBundle('${BackendConfig.fhirBaseUrl.value}/Encounter?subject=$patientId&_sort=-date&_count=1')
            .then((b) {
          if (b.entry?.isNotEmpty ?? false) {
            final res = b.entry!.first.resource;
            if (res is r5.Encounter) {
              resolvedEncounter = res;
            }
          }
          return null;
        }).catchError((e) {
          debugPrint('Error fetching encounter: $e');
          return null;
        }),

      // 2. Transport
      if (patientId != null)
        BackendService.getBundle('${BackendConfig.fhirBaseUrl.value}/Transport?for=$patientId&_sort=-date&_count=1')
            .then((b) {
          if (b.entry?.isNotEmpty ?? false) {
            final res = b.entry!.first.resource;
            if (res is r5.Transport) {
              transport = res;
            }
          }
          return null;
        }).catchError((e) {
          debugPrint('Error fetching transport: $e');
          return null;
        }),

      // 3. Procedures (if empty)
      if (procedures.isEmpty && patientId != null)
        BackendService.getBundle('${BackendConfig.fhirBaseUrl.value}/Procedure?patient=$patientId&_sort=-date&_count=50')
            .then((b) {
          if (b.entry != null) {
            for (var e in b.entry!) {
              if (e.resource is r5.Procedure) {
                fallbackProcedures.add(e.resource as r5.Procedure);
              }
            }
          }
          return null;
        }).catchError((e) {
          debugPrint('Error fetching procedures: $e');
          return null;
        }),

      // 4. Meds (if empty)
      if (meds.isEmpty && patientId != null)
        BackendService.getBundle('${BackendConfig.fhirBaseUrl.value}/MedicationAdministration?patient=$patientId&_sort=-date&_count=50')
            .then((b) {
          if (b.entry != null) {
            for (var e in b.entry!) {
              if (e.resource is r5.MedicationAdministration) {
                fallbackMeds.add(e.resource as r5.MedicationAdministration);
              }
            }
          }
          return null;
        }).catchError((e) {
          debugPrint('Error fetching meds: $e');
          return null;
        }),

      // 5. DeviceUsage Pagination
      if (patientId != null)
        () async {
          String? nextUrl = '${BackendConfig.fhirBaseUrl.value}/DeviceUsage?patient=$patientId&_count=100';
          while (nextUrl != null) {
            final bundle = await BackendService.getBundle(nextUrl);
            if (bundle.entry != null) {
              allUsageEntries.addAll(bundle.entry!);
            }
            nextUrl = BackendService.getNextPageUrl(bundle);
          }
        }().catchError((e) {
          debugPrint('Error fetching device usage: $e');
          return null;
        }),

      // 6. Observation Equip
      if (patientId != null)
        BackendService.getBundle('${BackendConfig.fhirBaseUrl.value}/Observation?patient=$patientId&code=246336002&_sort=-date&_count=50')
            .then((b) {
          if (b.entry != null) {
            for (var e in b.entry!) {
              if (e.resource is r5.Observation) {
                equipObs.add(e.resource as r5.Observation);
              }
            }
          }
          return null;
        }).catchError((e) {
          debugPrint('Error fetching equip obs: $e');
          return null;
        }),

      // 7. License Plate Location
      if (report.extension_ != null && report.extension_!.isNotEmpty)
        () async {
          // Capture report property in a non-nullable way for the check
          final exts = report!.extension_;
          if (exts == null || exts.isEmpty) {
            return;
          }
          final firstExt = exts.first;
          final ref = firstExt.valueReference?.reference;
          if (ref != null) {
            final locId = ref.split('/').last;
            final locJson = await BackendService.getResource('Location', locId);
            if (locJson != null) {
              licensePlate = locJson['name'] ?? locJson['alias']?.first ?? locId;
            } else {
              licensePlate = locId;
            }
          }
        }().catchError((e) {
          debugPrint('Error fetching license plate: $e');
          return null;
        }),

      // 8. All Devices (Catalog)
      BackendService.getAllDevices().then((list) {
        catalogDevices = list;
        return null;
      }).catchError((e) {
        debugPrint('Error fetching device catalog: $e');
        return null;
      }),
    ]);

    // Update aggregated lists
    procedures.addAll(fallbackProcedures);
    meds.addAll(fallbackMeds);

    // --- PROCESSING (Synthesis) ---

    // Helper for robust Location resolution
    Future<String> resolveLocName(String? ref, {String? display}) async {
      if (display != null &&
          display.isNotEmpty &&
          display.toLowerCase() != 'null') {
        return display;
      }
      if (ref == null) return 'N/A';
      final id = ref.split('/').last;
      try {
        final locJson = await BackendService.getResource('Location', id);
        if (locJson != null) {
          final name =
              locJson['name'] ??
              locJson['address']?['text'] ??
              locJson['alias']?.first;
          if (name != null && name.toString().toLowerCase() != 'null') {
            return name.toString();
          }
        }
      } catch (_) {}
      return id;
    }

    String origin = 'N/A';
    String destination = 'N/A';

    // Resolve Origin/Destination from Transport
    if (transport != null) {
      final tJson = transport!.toJson();
      final currLocRef = tJson['currentLocation']?['reference'];
      final reqLocRef = tJson['requestedLocation']?['reference'];
      if (currLocRef != null) {
        origin = await resolveLocName(currLocRef.toString(), display: tJson['currentLocation']?['display']);
      }
      if (reqLocRef != null) {
        destination = await resolveLocName(reqLocRef.toString(), display: tJson['requestedLocation']?['display']);
      }
    }

    // Resolve Origin/Destination Fallback (Encounter Admission)
    final encAdm = resolvedEncounter?.toJson()['admission'];
    if (encAdm is Map) {
      if (origin == 'N/A' && encAdm['origin'] != null) {
        origin = await resolveLocName(encAdm['origin']['reference']?.toString(), display: encAdm['origin']['display']?.toString());
      }
      if (destination == 'N/A' && encAdm['destination'] != null) {
        destination = await resolveLocName(encAdm['destination']['reference']?.toString(), display: encAdm['destination']['display']?.toString());
      }
    }

    // Fallback: Encounter.location
    final locs = resolvedEncounter?.location;
    if (destination == 'N/A' && locs != null && locs.isNotEmpty) {
      final lastLoc = locs.last.location;
      destination = await resolveLocName(lastLoc.reference, display: lastLoc.display);
    }

    // Map Crew & Encounter Status
    if (report.performer != null) {
      if (report.performer!.isNotEmpty) {
        medic = resolvePractitioner(report.performer![0]);
      }
      if (report.performer!.length > 1) {
        physician = resolvePractitioner(report.performer![1]);
      }
      if (report.performer!.length > 2) {
        driver = resolvePractitioner(report.performer![2]);
      }
    }

    String status = 'unknown';
    if (resolvedEncounter?.status != null) {
      status = resolvedEncounter!.status.toString().split('.').last.replaceAll('_', '-');
    }

    final encJson = resolvedEncounter?.toJson() ?? {};
    final dynamic periodJson = encJson['actualPeriod'] ?? encJson['period'];
    DateTime? parseFhirDateTime(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return DateTime.tryParse(raw);
      if (raw is Map && raw['value'] is String) return DateTime.tryParse(raw['value'] as String);
      return DateTime.tryParse(raw.toString());
    }

    final DateTime? startUtc = (periodJson is Map ? parseFhirDateTime(periodJson['start']) : null) ?? parseFhirDateTime(encJson['plannedStartDate']);
    final DateTime? endUtc = (periodJson is Map ? parseFhirDateTime(periodJson['end']) : null) ?? parseFhirDateTime(encJson['plannedEndDate']);

    if (status == 'unknown' || status == 'null') {
      if (endUtc != null) {
        status = 'completed';
      } else if (startUtc != null) {
        status = 'in-progress';
      } else {
        status = 'planned';
      }
    }

    String? startTime = report.effectiveDateTime != null 
        ? (DateTime.tryParse(report.effectiveDateTime.toString())?.toLocal().toString() ?? report.effectiveDateTime.toString())
        : null;
    String? endTime = endUtc != null ? DateTime.tryParse(endUtc.toString())?.toLocal().toString() : null;

    final encounterMap = {
      'status': status,
      'startTime': startTime,
      'endTime': endTime,
      'medic': medic,
      'physician': physician,
      'driver': driver,
      'licensePlate': licensePlate,
      'vehicle': 'Ambulance',
      'origin': origin,
      'destination': destination,
    };

    // Parse Sections from Observations
    final sections = <String, Map<String, dynamic>>{'a': {}, 'b': {}, 'c': {}, 'd': {}, 'e': {}};
    String getObsValue(r5.Observation obs) {
      if (obs.valueString != null) return obs.valueString!;
      if (obs.valueBoolean != null) return obs.valueBoolean.toString();
      if (obs.valueQuantity != null) return obs.valueQuantity!.value?.toString() ?? '';
      if (obs.valueInteger != null) return obs.valueInteger!.toString();
      if (obs.valueCodeableConcept != null) {
        return obs.valueCodeableConcept!.text ?? obs.valueCodeableConcept!.coding?.first.display ?? '';
      }
      return '';
    }

    void extractObsData(r5.Observation obs, Map<String, dynamic> currentTarget) {
      final title = obs.code.text ?? obs.code.coding?.first.display ?? 'Observation';
      final t = title.toLowerCase();

      // Redirect temperature-related data to Exposure section (Section E)
      Map<String, dynamic> target = currentTarget;
      if (t.contains('temperature')) {
        target = sections['e']!;
      }

      final val = getObsValue(obs);
      if (val.isNotEmpty) target[title] = val;
      if (obs.component != null) {
        for (var comp in obs.component!) {
          final cKey = comp.code.text ?? comp.code.coding?.first.display ?? 'Info';
          final cVal = comp.valueString ?? comp.valueQuantity?.value?.toString() ?? comp.valueInteger?.toString() ?? comp.valueCodeableConcept?.text ?? comp.valueCodeableConcept?.coding?.first.display ?? '';
          if (cVal.isNotEmpty) target['$title - $cKey'] = cVal;
        }
      }
      if (obs.hasMember != null) {
        for (var memberRef in obs.hasMember!) {
          final memberObs = findObs(memberRef.reference);
          if (memberObs != null && memberObs.id.toString() != 'missing') {
            extractObsData(memberObs, target);
          }
        }
      }
    }

    if (report.result != null) {
      for (var i = 0; i < report.result!.length; i++) {
        final ref = report.result![i];
        final obs = findObs(ref.reference);
        if (obs == null || obs.id?.toString() == 'missing') continue;

        final title = (obs.code.text ?? obs.code.coding?.first.display ?? '').toLowerCase();

        String key;
        if (title.contains('airway')) {
          key = 'a';
        } else if (title.contains('breathing')) {
          key = 'b';
        } else if (title.contains('circulation')) {
          key = 'c';
        } else if (title.contains('disability') || title.contains('gcs') || title.contains('pupil')) {
          key = 'd';
        } else if (title.contains('exposure') || title.contains('environ') || title.contains('temp')) {
          key = 'e';
        } else if (title.contains('neuro')) {
          // In some apps, a 5th "Neurological" section is used for Exposure data
          if (i == 4) {
            key = 'e';
          } else {
            key = 'd';
          }
        } else {
          // Fallback to positional mapping
          switch (i) {
            case 0: key = 'a'; break;
            case 1: key = 'b'; break;
            case 2: key = 'c'; break;
            case 3: key = 'd'; break;
            case 4: key = 'e'; break;
            default: continue;
          }
        }

        extractObsData(obs, sections[key]!);

        // Link procedures that are "partOf" this observation root
        if (obs.partOf != null) {
          for (var partRef in obs.partOf!) {
            if (partRef.reference?.contains('Procedure') ?? false) {
              final proc = findProc(partRef.reference);
              if (proc != null) {
                final pTitle = proc.code?.text ?? proc.code?.coding?.first.display ?? 'Procedure';
                sections[key]![pTitle] = 'Performed';
              }
            }
          }
        }
      }
    }

    // Equipment Synthesis (Phase 2: Batch fetch Devices in Parallel)
    List<Map<String, String>> equipmentList = [];
    Map<String, String> deviceNames = {};
    for (var dev in catalogDevices) {
      if (dev.id != null) {
        String devName = 'Device';
        final devJson = dev.toJson();
        // R5 style: name[0].value
        if (devJson['name'] != null && devJson['name'] is List && devJson['name'].isNotEmpty) {
          devName = devJson['name'][0]['value'] ?? 'Device';
        }
        // R4 style / Fallback: deviceName[0].name
        else if (devJson['deviceName'] != null && devJson['deviceName'] is List && devJson['deviceName'].isNotEmpty) {
          devName = devJson['deviceName'][0]['name'] ?? 'Device';
        }
        // Fallback: type.text
        else if (dev.type != null && dev.type!.isNotEmpty) {
          devName = dev.type!.first.text ?? dev.type!.first.coding?.first.display ?? 'Device';
        }
        deviceNames[dev.id!.toString()] = devName;
      }
    }

    // Process Meds (async Medication lookup if needed)
    List<Map<String, String>> medList = [];
    for (var m in meds) {
      String name = 'Unknown Drug';
      if (m.medication.concept != null) {
        name = m.medication.concept!.text ?? m.medication.concept!.coding?.first.display ?? 'Unknown Drug';
      } else {
        final medJson = m.medication.toJson();
        String? medId;
        final medRoot = medJson['reference'];
        if (medRoot != null && medRoot['reference'] != null) {
          final refObj = medRoot['reference'];
          if (refObj is Map && refObj['reference'] != null) {
            medId = refObj['reference'].toString().split('/').last;
          } else if (refObj is String) {
            medId = refObj.split('/').last;
          }
        }
        if (medId != null) {
          try {
            final resJson = await BackendService.getResource('Medication', medId);
            if (resJson != null) {
              final coding = resJson['code']?['coding'];
              if (coding is List && coding.isNotEmpty) {
                name = coding[0]['display'] ?? name;
              }
            }
          } catch (_) {}
        }
        if (name == 'Unknown Drug' && m.medication.reference?.display != null) {
          name = m.medication.reference!.display!;
        }
      }
      if (name == 'Unknown Drug' && m.text?.div != null) {
        final plainText = m.text!.div.toString().replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
        if (plainText.isNotEmpty) name = plainText;
      }
      medList.add({
        'name': name,
        'dose': m.dosage?.dose?.value?.toString() ?? '',
        'route': m.dosage?.route?.text ?? m.dosage?.route?.coding?.first.display ?? '',
        'time': m.occurenceDateTime?.toString() ?? '',
      });

      // Extract devices from MedicationAdministration (e.g. syringes for Adrenaline)
      final mJson = m.toJson();
      if (mJson['device'] != null && mJson['device'] is List) {
        for (var d in mJson['device']) {
          String? devId;
          final devRef = d['reference'];
          if (devRef != null && devRef['reference'] != null) {
            devId = devRef['reference'].toString().split('/').last;
          }
          if (devId != null) {
             equipmentList.add({'name': deviceNames[devId] ?? (devId == '516' ? 'Syringe/Injection Device' : 'Item $devId'), 'quantity': '1'});
          }
        }
      }
    }

    List<Map<String, String>> procList = procedures.map((p) {
      String name = 'Unknown Procedure';
      if (p.code != null) name = p.code!.text ?? p.code!.coding?.first.display ?? name;
      if (name == 'Unknown Procedure' && p.text?.div != null) {
        final plainText = p.text!.div.toString().replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
        if (plainText.isNotEmpty) name = plainText;
      }
      return {'name': name, 'time': p.occurrenceDateTime?.toString() ?? ''};
    }).toList();
    for (var proc in procedures) {
      if (proc.focalDevice != null) {
        for (var fd in proc.focalDevice!) {
          final manipulated = fd.manipulated;
          final ref = manipulated.reference;
          if (ref != null) {
            final devId = ref.split('/').last;
            final name = manipulated.display ?? deviceNames[devId] ?? devId;
            if (!equipmentList.any((e) => e['name'] == name)) {
              equipmentList.add({'name': name, 'quantity': '1'});
            }
          }
        }
      }
    }

    // Devices from DeviceUsage (Resolved from pre-fetched Catalog)
    if (allUsageEntries.isNotEmpty) {
      for (var entry in allUsageEntries) {
        if (entry.resource is r5.DeviceUsage) {
          final usage = entry.resource as r5.DeviceUsage;
          String name = 'Unknown Item';
          final usageJson = usage.toJson();
          String? deviceId;
          final devRoot = usageJson['device'];
          if (devRoot != null && devRoot['reference'] != null) {
            final refObj = devRoot['reference'];
            if (refObj is Map && refObj['reference'] != null) {
              deviceId = refObj['reference'].toString().split('/').last;
            } else if (refObj is String) {
              deviceId = refObj.split('/').last;
            }
          }
          if (deviceId != null) {
            name = deviceNames[deviceId] ?? 'Item $deviceId';
          } else if (usage.device.reference?.display != null) {
            name = usage.device.reference!.display!;
          }

          if (!equipmentList.any((e) => e['name'] == name)) {
            equipmentList.add({'name': name, 'quantity': '1'});
          }
        }
      }
    }

    // Equipment from Observations
    for (var obs in equipObs) {
      String name = obs.device?.display ?? (obs.focus?.isNotEmpty == true ? obs.focus!.first.display ?? 'Item' : obs.code.text ?? 'Equipment');
      String amount = obs.effectiveTiming?.repeat?.count?.value?.toString() ?? obs.valueQuantity?.value?.toString() ?? obs.valueInteger?.toString() ?? '1';
      if (!equipmentList.any((e) => e['name'] == name)) {
        equipmentList.add({'name': name, 'quantity': amount});
      }
    }

    return {
      'id': report.id?.toString(),
      'patient': patientMap,
      'encounter': encounterMap,
      'pcr': sections,
      'medications': medList,
      'procedures': procList,
      'equipmentUsed': equipmentList,
      'handover': null,
    };
  }

  /// Fetches the most recent reports with optimized detail fetching.
  Future<List<Map<String, String>>> getRecentReports(int count) async {
    try {
      String url =
          '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.diagnosticReportName}?_sort=-date&_count=$count&_include=DiagnosticReport:patient&_include=DiagnosticReport:performer';

      final bundle = await BackendService.getBundle(url);
      List<r5.DiagnosticReport> reports = [];
      Map<String, r5.Patient> patients = {};
      Map<String, r5.Practitioner> practitioners = {};

      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.DiagnosticReport) {
            reports.add(entry.resource as r5.DiagnosticReport);
          } else if (entry.resource is r5.Patient) {
            if (entry.resource!.id != null) {
              patients[entry.resource!.id!.toString()] =
                  entry.resource as r5.Patient;
            }
          } else if (entry.resource is r5.Practitioner) {
            if (entry.resource!.id != null) {
              practitioners[entry.resource!.id!.toString()] =
                  entry.resource as r5.Practitioner;
            }
          }
        }
      }

      List<Map<String, String>> results = [];
      for (var report in reports) {
        // 1. Patient Name + ID
        // 1. Patient Name + ID
        String patientText = 'Unknown';
        if (report.subject != null) {
          String id = report.subject!.reference?.split('/').last ?? '';
          if (patients.containsKey(id)) {
            final p = patients[id]!;
            // Temporary helper for batch resolution
            String pName(List<r5.HumanName>? n) {
              if (n == null || n.isEmpty) return 'Unknown';
              final first = n.first;
              if (first.text != null && first.text!.isNotEmpty) return first.text!;
              final fam = first.family ?? '';
              final giv = first.given?.join(' ') ?? '';
              final comb = [giv, fam].where((s) => s.isNotEmpty).join(' ');
              return comb.isNotEmpty ? comb : 'Unknown';
            }
            patientText = '${pName(p.name)} ($id)';
          } else {
            patientText = report.subject!.display ?? 'ID: $id';
          }
        }

        // 2. Driver Name + ID (3rd performer)
        String driverText = 'N/A';
        if (report.performer != null && report.performer!.length > 2) {
          final perfRef = report.performer![2];
          String id = perfRef.reference?.split('/').last ?? '';

          if (practitioners.containsKey(id)) {
            final p = practitioners[id]!;
            String dName(List<r5.HumanName>? n) {
              if (n == null || n.isEmpty) return 'Driver';
              final first = n.first;
              if (first.text != null && first.text!.isNotEmpty) return first.text!;
              final fam = first.family ?? '';
              final giv = first.given?.join(' ') ?? '';
              final comb = [giv, fam].where((s) => s.isNotEmpty).join(' ');
              return comb.isNotEmpty ? comb : 'Driver';
            }
            driverText = '${dName(p.name)} ($id)';
          } else {
            driverText = perfRef.display ?? 'ID: $id';
          }
        }

        // 3. Vehicle (License Plate / Location)
        String vehicleText = 'N/A';
        if (report.extension_ != null && report.extension_!.isNotEmpty) {
          final ref = report.extension_!.first.valueReference?.reference;
          if (ref != null) {
            final vehicleId = ref.split('/').last;
            try {
              final vehicleJson = await BackendService.getResource(
                GeneralConstants.locationResourceName,
                vehicleId,
              );
              if (vehicleJson != null) {
                if (vehicleJson['resourceType'] == 'Location') {
                  vehicleText =
                      vehicleJson['name'] ??
                      vehicleJson['alias']?.first ??
                      vehicleId;
                } else if (vehicleJson['resourceType'] == 'Device') {
                  vehicleText =
                      vehicleJson['deviceName']?.first['name'] ?? vehicleId;
                }
              } else {
                vehicleText = 'ID: $vehicleId';
              }
            } catch (e) {
              vehicleText = ref.split('/').last;
            }
          }
        }

        results.add({
          'id': report.id?.toString() ?? '',
          'patient': patientText,
          'date': report.effectiveDateTime?.toString() ?? '',
          'vehicle': vehicleText,
          'driver': driverText,
        });
      }
      return results;
    } catch (e) {
      debugPrint('Error fetching detailed reports: $e');
      return [];
    }
  }
}
