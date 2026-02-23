import 'package:fhir/r5.dart' as r5;
import '../config/general_constants.dart';
import '../config/backend_config.dart';
import 'backend_service.dart';

class OrderService {
  OrderService._internal() {
    _openOrders = [];
    _closedOrders = [];
  }

  static final OrderService instance = OrderService._internal();

  List<Map<String, String>> _openOrders = [];
  List<Map<String, String>> _closedOrders = [];
  List<r5.ServiceRequest> _openOrderResources = [];

  Future<List<Map<String, String>>> getOpenOrders() async {
    try {
      final resources = await _fetchServiceRequests('active');
      _openOrderResources = resources;
      _openOrders = resources.map((r) => _requestToMap(r)).toList();
      return _openOrders;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getClosedOrders() async {
    try {
      final resources = await _fetchServiceRequests('completed');
      _closedOrders = resources.map((r) => _requestToMap(r)).toList();
      return _closedOrders;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<r5.ServiceRequest>> _fetchServiceRequests(String status) async {
    // Include patient details if possible, but for now we just fetch the ServiceRequest
    // and rely on the subject.display or reference.
    String? url =
        '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.serviceRequestResourceName}?status=$status&_sort=-authored';
    List<r5.ServiceRequest> requests = [];
    while (url != null) {
      final bundle = await BackendService.getBundle(url);
      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.ServiceRequest) {
            requests.add(entry.resource as r5.ServiceRequest);
          }
        }
      }
      url = BackendService.getNextPageUrl(bundle);
    }
    return requests;
  }

  Map<String, String> _requestToMap(r5.ServiceRequest request) {
    String displayId = request.identifier?.isNotEmpty == true
        ? request.identifier!.first.value ?? ''
        : '';
    String title =
        request.code?.concept?.text ??
        request.note?.firstOrNull?.text?.toString() ??
        'Order';

    String licensePlate = '';
    if (request.performer?.isNotEmpty == true) {
      licensePlate =
          request.performer!.first.display ??
          request.performer!.first.reference?.split('/').last ??
          '';
    }

    String time = '';
    if (request.authoredOn != null) {
      final dt = request.authoredOn!.value?.toLocal();
      if (dt != null) {
        time =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }


    String patient =
        request.subject?.display ??
        request.subject?.reference?.split('/').last ??
        'Unknown';
    String location = 'N/A';
    if (request.location != null && request.location!.isNotEmpty) {
      // R5 ServiceRequest.location is List<CodeableReference>
      location =
          request.location!.first.concept?.text ??
          request.location!.first.reference?.display ??
          'Unknown Loc';
    }

    // Handle potential Enum.toString() output (e.g., ServiceRequestPriority.routine -> routine)
    String priority = request.priority?.toString().split('.').last ?? 'routine';

    String reason = 'N/A';
    if (request.reason != null && request.reason!.isNotEmpty) {
      // R5 ServiceRequest.reason is List<CodeableReference>
      reason =
          request.reason!.first.concept?.text ??
          request.reason!.first.concept?.coding?.first.display ??
          '';
    }

    String status = request.status?.toString().split('.').last ?? 'active';

    return {
      'id': request.id?.toString() ?? '',
      'displayId': displayId,
      'title': title,
      'licensePlate': licensePlate,
      'time': time,
      'patient': patient,
      'location': location,
      'priority': priority,
      'reason': reason,
      'status': status,
    };
  }

  Future<void> create(Map<String, String> value) async {
    final now = DateTime.now();
    DateTime authoredOn = now;
    if (value['time'] != null && value['time']!.contains(':')) {
      final parts = value['time']!.split(':');
      if (parts.length == 2) {
        authoredOn = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    }

    final Map<String, dynamic> requestJson = {
      'resourceType': 'ServiceRequest',
      'status': 'active',
      'intent': 'order',
      'priority': value['priority']?.toLowerCase() ?? 'routine',
      'subject': {'display': value['patient'] ?? 'Unknown Patient'},
      'identifier': [
        {'value': value['displayId'] ?? ''},
      ],
      'code': {
        'concept': {'text': value['title'] ?? ''},
      },
      'reason': [
        {
          'concept': {'text': value['reason'] ?? ''},
        },
      ],
      'location': [
        {
          'concept': {'text': value['location'] ?? ''},
        },
      ],
      'performer': [
        {'display': value['licensePlate'] ?? ''},
      ],
      'authoredOn': authoredOn.toIso8601String(),
    };

    final statusCode = await BackendService.postResource(
      requestJson,
      GeneralConstants.serviceRequestResourceName,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getOpenOrders();
    }
  }

  Future<void> createOpenOrder(Map<String, String> value) async {
    await create(value);
  }

  Future<void> updateOpenOrder(int index, Map<String, String> value) async {
    if (index < 0 || index >= _openOrders.length) return;
    final currentMap = _openOrders[index];
    final id = currentMap['id'] ?? '';
    if (id.isEmpty) return;

    Map<String, dynamic> requestJson;
    if (_openOrderResources.length == _openOrders.length &&
        _openOrderResources[index].id?.toString() == id) {
      requestJson = Map<String, dynamic>.from(
        _openOrderResources[index].toJson(),
      );
    } else {
      requestJson = {
        'resourceType': 'ServiceRequest',
        'id': id,
        'status': 'active',
        'intent': 'order',
        'subject': {'display': 'Dashboard User'},
      };
    }

    if (value['displayId'] != null)
      requestJson['identifier'] = [
        {'value': value['displayId']},
      ];
    if (value['title'] != null)
      requestJson['code'] = {
        'concept': {'text': value['title']},
      };
    if (value['licensePlate'] != null)
      requestJson['performer'] = [
        {'display': value['licensePlate']},
      ];
    if (value['patient'] != null)
      requestJson['subject'] = {'display': value['patient']};
    if (value['priority'] != null)
      requestJson['priority'] = value['priority']!.toLowerCase();

    if (value['reason'] != null) {
      requestJson['reason'] = [
        {
          'concept': {'text': value['reason']},
        },
      ];
    }
    if (value['location'] != null) {
      requestJson['location'] = [
        {
          'concept': {'text': value['location']},
        },
      ];
    }

    if (value['time'] != null && value['time']!.contains(':')) {
      final now = DateTime.now();
      final parts = value['time']!.split(':');
      if (parts.length == 2) {
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        requestJson['authoredOn'] = dt.toIso8601String();
      }
    }

    final statusCode = await BackendService.updateResource(
      requestJson,
      GeneralConstants.serviceRequestResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getOpenOrders();
    }
  }

  Future<void> acceptOpenOrder(int index) async {
    if (index < 0 || index >= _openOrders.length) return;
    final currentMap = _openOrders[index];
    final id = currentMap['id'] ?? '';
    if (id.isEmpty) return;


    Map<String, dynamic> requestJson;
    if (_openOrderResources.length == _openOrders.length &&
        _openOrderResources[index].id?.toString() == id) {
      requestJson = Map<String, dynamic>.from(
        _openOrderResources[index].toJson(),
      );
    } else {

      return;
    }

    requestJson['status'] = 'completed';

    final statusCode = await BackendService.updateResource(
      requestJson,
      GeneralConstants.serviceRequestResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getOpenOrders();
      await getClosedOrders();
    }
  }
} // OrderService
