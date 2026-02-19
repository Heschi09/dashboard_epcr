import 'package:fhir/r5.dart' as r5;
import '../config/general_constants.dart';
import '../config/backend_config.dart';
import 'backend_service.dart';

class TransportService {
  TransportService._internal() {
    _transports = [];
  }

  static final TransportService instance = TransportService._internal();

  List<Map<String, String>> _transports = [];

  Future<List<Map<String, String>>> getAll() async {
    try {
      final resources = await _fetchEncounters();
      _transports = resources.map((e) => _encounterToMap(e)).toList();
      return _transports;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<r5.Encounter>> _fetchEncounters() async {
    // Fetch Encounters (Transporte), sortiert nach Datum
    String? url =
        '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.encounterResourceName}?_sort=-date';
    List<r5.Encounter> encounters = [];
    while (url != null) {
      final bundle = await BackendService.getBundle(url);
      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.Encounter) {
            encounters.add(entry.resource as r5.Encounter);
          }
        }
      }
      url = BackendService.getNextPageUrl(bundle);
    }
    return encounters;
  }

  Map<String, String> _encounterToMap(r5.Encounter encounter) {
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
    String patient =
        encounter.subject?.display ??
        encounter.subject?.reference?.split('/').last ??
        'Unknown Patient';

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
        // Laufender Transport (end == null)
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

    // Prefer Admission.destination (matches your server payload)
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
