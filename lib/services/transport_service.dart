import 'package:fhir/r5.dart' as r5;
import '../config/general_constants.dart';
import '../config/backend_config.dart';
import 'backend_service.dart';

/// Service for managing patient transports (Encounters in FHIR).
///
/// Handles fetching and mapping of transport history and active missions.
class TransportService {
  TransportService._internal() {
    _transports = [];
  }

  static final TransportService instance = TransportService._internal();

  List<Map<String, String>> _transports = [];

  /// Fetches all transport encounters and maps them for UI display.
  Future<List<Map<String, String>>> getAll() async {
    try {
      String? encounterUrl =
          '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.encounterResourceName}?_sort=-date&_include=Encounter:subject';
      List<r5.Encounter> encounters = [];
      Map<String, r5.Patient> patients = {};

      while (encounterUrl != null) {
        final bundle = await BackendService.getBundle(encounterUrl);
        if (bundle.entry != null) {
          for (var entry in bundle.entry!) {
            if (entry.resource is r5.Encounter) {
              encounters.add(entry.resource as r5.Encounter);
            } else if (entry.resource is r5.Patient) {
              final p = entry.resource as r5.Patient;
              if (p.id != null) patients[p.id.toString()] = p;
            }
          }
        }
        encounterUrl = BackendService.getNextPageUrl(bundle);
      }

      String? pcrUrl =
          '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.diagnosticReportName}?_sort=-date';
      Map<String, String> patientToPcrId = {};

      while (pcrUrl != null) {
        final bundle = await BackendService.getBundle(pcrUrl);
        if (bundle.entry != null) {
          for (var entry in bundle.entry!) {
            if (entry.resource is r5.DiagnosticReport) {
              final report = entry.resource as r5.DiagnosticReport;
              final subjectRef = report.subject?.reference;
              if (subjectRef != null && report.id != null) {
                if (!patientToPcrId.containsKey(subjectRef)) {
                  patientToPcrId[subjectRef] = report.id.toString();
                }
              }
            }
          }
        }
        pcrUrl = BackendService.getNextPageUrl(bundle);
      }

      _transports = encounters.map((e) {
        final map = _encounterToMapWithPatients(e, patients);
        final patientRef = e.subject?.reference;
        final pcrId = patientRef != null ? patientToPcrId[patientRef] : null;
        map['pcrId'] = pcrId ?? '';
        return map;
      }).toList();

      return _transports;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _encounterToMapWithPatients(
    r5.Encounter encounter,
    Map<String, r5.Patient> patientsMap,
  ) {
    String id = encounter.id?.toString() ?? '';

    DateTime? parseFhirDateTime(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return DateTime.tryParse(raw);
      if (raw is Map && raw['value'] is String) {
        return DateTime.tryParse(raw['value'] as String);
      }
      final asString = raw.toString();
      return DateTime.tryParse(asString);
    }

    // Encounter in the wild can be R4-style ("period") or R5-style ("actualPeriod").
    // We read from JSON to be resilient across servers and FHIR versions.
    final json = encounter.toJson();
    final dynamic periodJson = json['actualPeriod'] ?? json['period'];
    // Server can also provide plannedStartDate/plannedEndDate on Encounter root.
    final DateTime? startUtcish =
        (periodJson is Map ? parseFhirDateTime(periodJson['start']) : null) ??
        parseFhirDateTime(json['plannedStartDate']);
    final DateTime? endUtcish =
        (periodJson is Map ? parseFhirDateTime(periodJson['end']) : null) ??
        parseFhirDateTime(json['plannedEndDate']);
    final DateTime? start = startUtcish?.toLocal();
    final DateTime? end = endUtcish?.toLocal();

    // Patient
    String patient = 'Unknown Patient';
    if (encounter.subject != null) {
      final pId = encounter.subject!.reference?.split('/').last;
      if (pId != null && patientsMap.containsKey(pId)) {
        final p = patientsMap[pId]!;
        String fullName = 'Unknown';
        if (p.name != null && p.name!.isNotEmpty) {
          final n = p.name!.first;
          final family = n.family ?? '';
          final given = n.given?.join(' ') ?? '';
          final combined = [given, family].where((s) => s.isNotEmpty).join(' ');
          fullName = combined.isNotEmpty ? combined : (n.text ?? 'Unknown');
        }
        patient = '$fullName ($pId)';
      } else {
        patient =
            encounter.subject?.display ??
            pId ??
            'Unknown Patient';
      }
    }

    // Status
    String status = 'unknown';
    if (encounter.status != null) {
      status = encounter.status.toString().split('.').last.replaceAll('_', '-');
    }

    // Infer status if missing or unknown
    if (status == 'unknown' || status == 'null') {
      if (end != null) {
        status = 'completed';
      } else if (start != null) {
        status = 'in-progress';
      } else {
        status = 'planned';
      }
    }

    // Period/Time & Duration
    String time = '';
    String duration = '';
    String startIso = '';
    String endIso = '';
    String date = 'Pending';

    if (start != null) {
      startIso = start.toIso8601String();
      date =
          '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}. ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

      if (end != null) {
        endIso = end.toIso8601String();
        final diff = end.difference(start);
        int mins = diff.inMinutes;
        if (mins < 0) mins = 0;

        // Calculate duration string
        if (mins < 1) {
          time = '< 1 min';
        } else if (mins < 60) {
          time = '$mins min';
        } else {
          final h = mins ~/ 60;
          final m = mins % 60;
          time = '${h}h ${m}min';
        }

        duration = mins.toString();
      } else {
        // In-progress transport (end == null)
        time = 'In Progress';
        duration = '';
        if (status == 'unknown') status = 'in-progress';
      }
    } else {
      time = 'Pending';
      if (status == 'unknown') status = 'planned';
    }

    // Location / Destination
    // Encounter.location is List<EncounterLocation>
    String destination = 'N/A';
    String? destinationRef;

    // Prefer Admission.destination
    final admission = json['admission'];
    if (admission is Map) {
      final dest = admission['destination'];
      if (dest is Map) {
        final disp = dest['display']?.toString();
        final ref = dest['reference']?.toString();
        final isValidDisp =
            disp != null && disp.isNotEmpty && disp.toLowerCase() != 'null';
        final isValidRef =
            ref != null && ref.isNotEmpty && ref.toLowerCase() != 'null';
        if (isValidDisp) destination = disp;
        if (isValidRef) destinationRef = ref;
      }
    }

    // Fallback: use the last location entry (often the final destination)
    if (destination == 'N/A' &&
        encounter.location != null &&
        encounter.location!.isNotEmpty) {
      final last = encounter.location!.last.location;
      final disp = last.display;
      final ref = last.reference;
      if (disp != null && disp.isNotEmpty) destination = disp;
      if (ref != null && ref.isNotEmpty) destinationRef = ref;
      if (destination == 'N/A' && destinationRef != null) {
        destination = destinationRef.split('/').last;
      }
    }

    // Fallback: serviceProvider
    if (destination == 'N/A' && encounter.serviceProvider != null) {
      destination = encounter.serviceProvider!.display ?? 'Hospital';
      destinationRef = encounter.serviceProvider!.reference;
    }

    // Show ID/reference alongside destination if we have one
    if (destinationRef != null && destinationRef.isNotEmpty) {
      final id = destinationRef.contains('/')
          ? destinationRef.split('/').last
          : destinationRef;
      destination = '$destination ($id)';
    }

    // Type (e.g. Emergency, Transfer)
    String type = 'Transport';
    if (encounter.type != null && encounter.type!.isNotEmpty) {
      type =
          encounter.type!.first.text ??
          encounter.type!.first.coding?.first.display ??
          'Transport';
    }

    return {
      'id': id,
      'patient': patient,
      'status': status,
      'time': time,
      'date': date,
      'destination': destination,
      'type': type,
      'duration': duration,
      'startIso': startIso,
      'endIso': endIso,
    };
  }
}
