import 'package:flutter/material.dart';
import '../config/backend_config.dart';
import '../config/general_constants.dart';
import 'backend_service.dart';
import 'package:fhir/r5.dart' as r5;

class PcrService {
  PcrService._internal();

  static final PcrService instance = PcrService._internal();

  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      // Fetch DiagnosticReports (ePCRs)
      String? url = '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.diagnosticReportName}?_sort=-date';
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
    return {
      'id': report.id?.toString(),
      'status': report.status?.toString(),
      'patient': report.subject?.display ?? 'Unknown Patient', // Ideally resolve reference
      'date': report.effectiveDateTime?.toString() ?? '',
    };
  }

  Future<Map<String, dynamic>> getFullReportData(String reportId) async {
      // Load Report and all linked resources (Observations, Procedures, Patient, Encounter)
      String url = '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.diagnosticReportName}?'
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

      // Helper to find Obs by ID
      r5.Observation? findObs(String? ref) {
        if (ref == null) return null;
        final id = ref.split('/').last;
        return observations.firstWhere(
            (o) => o.id?.toString() == id, 
            orElse: () => r5.Observation(
                status: r5.FhirCode('final'), 
                code: r5.CodeableConcept(text: 'Missing'),
                id: r5.FhirId('missing')
            )
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

      // Parse Data
      // Map Patient
      final patientMap = {
        'name': patient?.name?.first.text ?? 'Unknown',
        'birthDate': patient?.birthDate?.toString() ?? '',
        'gender': patient?.gender?.toString() ?? '',
      };

      // Map Crew (from Performer: Medic, Physician, Driver)
      // ePCR App Order: [Medic, Physician, Driver]
      String medic = 'N/A';
      String physician = 'N/A';
      String driver = 'N/A';
      
      if (report.performer != null) {
          if (report.performer!.isNotEmpty) {
             medic = report.performer![0].display ?? report.performer![0].reference ?? 'N/A';
             // Try to resolve name from included Practitioners if possible, but display/reference is usually what's sent directly
          }
          if (report.performer!.length > 1) {
             physician = report.performer![1].display ?? report.performer![1].reference ?? 'N/A';
          }
          if (report.performer!.length > 2) {
             driver = report.performer![2].display ?? report.performer![2].reference ?? 'N/A';
          }
      }

      // Map Location (License Plate) from Extension
      String licensePlate = 'N/A';
      if (report.extension_ != null && report.extension_!.isNotEmpty) {
          // ePCR App sends one extension with valueReference to Location
           licensePlate = report.extension_!.first.valueReference?.reference?.split('/').last ?? 'N/A';
      }

      // Map Encounter
      final encounterMap = {
        'status': encounter?.status?.toString() ?? 'N/A',
        'startTime': encounter?.actualPeriod?.start?.toString(),
        'endTime': encounter?.actualPeriod?.end?.toString(),
        'medic': medic,
        'physician': physician,
        'driver': driver,
        'licensePlate': licensePlate,
        'vehicle': 'Ambulance', // Default or fetch if needed
      };

      // Parse Sections form Observations
      // ePCR App Order: result[0]=A, [1]=B, [2]=C, [3]=D, [4]=E
      final sections = <String, Map<String, dynamic>>{
        'a': {}, 'b': {}, 'c': {}, 'd': {}, 'e': {}
      };

      void parseSection(String sectionKey, r5.Reference? ref) {
          if (ref == null) return;
          final sectionObs = findObs(ref.reference);
          if (sectionObs == null || sectionObs.id?.toString() == 'missing') return;

           // 1. Members (Findings)
           if (sectionObs.hasMember != null) {
             for (var memberRef in sectionObs.hasMember!) {
               final memberObs = findObs(memberRef.reference);
               if (memberObs != null && memberObs.id.toString() != 'missing') {
                 final key = memberObs.code.text ?? memberObs.code.coding?.first.display ?? 'Observation';
                 final val = memberObs.valueString ?? memberObs.valueBoolean?.toString() ?? memberObs.valueQuantity?.value?.toString() ?? '';
                 sections[sectionKey]![key] = val;
               }
             }
           }
           // 2. PartOf (Procedures)
           if (sectionObs.partOf != null) {
              for (var partRef in sectionObs.partOf!) {
                 if (partRef.reference?.contains('Procedure') ?? false) {
                    final proc = findProc(partRef.reference);
                    if (proc != null) {
                       final key = proc.code?.text ?? proc.code?.coding?.first.display ?? 'Procedure';
                       sections[sectionKey]![key] = 'Performed';
                    }
                 }
              }
           }
           // 3. Value of section itself
           if (sectionObs.valueString != null) {
              sections[sectionKey]!['Main'] = sectionObs.valueString;
           }
      }

      if (report.result != null) {
          if (report.result!.isNotEmpty) parseSection('a', report.result![0]);
          if (report.result!.length > 1) parseSection('b', report.result![1]);
          if (report.result!.length > 2) parseSection('c', report.result![2]);
          if (report.result!.length > 3) parseSection('d', report.result![3]);
          if (report.result!.length > 4) parseSection('e', report.result![4]);
      }

      // Meds and Procedures (aggregated from all lists)
      List<Map<String, String>> medList = meds.map((m) => {
        'name': m.medication.concept?.text ?? 'Unknown Drug',
        'dose': m.dosage?.dose?.value?.toString() ?? '',
        'route': m.dosage?.route?.text ?? '',
        'time': m.occurenceDateTime?.toString() ?? ''
      }).toList();

      List<Map<String, String>> procList = procedures.map((p) => {
        'name': p.code?.text ?? p.code?.coding?.first.display ?? 'Unknown Procedure',
        'time': p.occurrenceDateTime?.toString() ?? ''
      }).toList();

      // Equipment Used (Secondary Query for Observations with SNOMED 246336002)
      List<Map<String, String>> equipmentList = [];
      if (patient != null && patient.id != null) {
        try {
           // Fetch Observations with code 246336002 (Material Used) linked to this patient
           // We limit to recent ones or rely on the fact they are "floating" for this patient
           final equipBundle = await BackendService.getBundle(
              '${BackendConfig.fhirBaseUrl.value}/Observation?patient=${patient.id}&code=246336002&_sort=-date&_count=50'
           );
           
           if (equipBundle.entry != null) {
             for (var entry in equipBundle.entry!) {
               if (entry.resource is r5.Observation) {
                  final obs = entry.resource as r5.Observation;
                  // Attempt to extract Device Name
                  // App puts device ref in 'device' (R4/R5) or 'focus'? App uses DeviceUsage class mapping to Observation. 
                  // If mapped to Observation, 'device' field might be used.
                  String name = 'Unknown Item';
                  String amount = '1';
                  
                  // Try to find name in device display or code text
                  if (obs.device != null) {
                     name = obs.device!.display ?? 'Device ${obs.device!.reference?.split("/").last}';
                     // If display is empty, we might need to fetch the device, but let's hope it's contained or display is set
                  } else if (obs.focus != null && obs.focus!.isNotEmpty) {
                     name = obs.focus!.first.display ?? 'Item';
                  } else {
                     // Fallback: check text text?
                     name = obs.code.text ?? 'Equipment';
                  }

                  // Amount: App puts it in timingTiming.repeat.count -> effectiveTiming.repeat.count in Observation
                  // Or valueQuantity
                  if (obs.effectiveTiming?.repeat?.count != null) {
                     amount = obs.effectiveTiming!.repeat!.count!.value?.toString() ?? '1';
                  } else if (obs.valueQuantity != null) {
                    amount = obs.valueQuantity!.value?.toString() ?? '1';
                  } else if (obs.valueInteger != null) { 
                     amount = obs.valueInteger.toString();
                  } 
                  
                  equipmentList.add({
                    'name': name,
                    'quantity': amount // Changed 'amount' to 'quantity' to match PcrView
                  });
               }
             }
           }
        } catch (e) {
          debugPrint('Error fetching equipment: $e');
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
        'handover': null 
      };
  }
}
