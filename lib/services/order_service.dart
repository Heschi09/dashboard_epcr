
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
  // We might not need to keep closed resources in memory for now, just the summary list

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
    String? url = '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.serviceRequestResourceName}?status=$status';
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
    String nr = request.identifier?.isNotEmpty == true
        ? request.identifier!.first.value ?? ''
        : '';
    // ServiceRequest.code is CodeableReference, has concept (CodeableConcept) -> text
    // ServiceRequest.note is Annotation, text is Markdown -> needs toString()
    String title = request.code?.concept?.text ?? request.note?.firstOrNull?.text?.toString() ?? 'Order';
    
    // ServiceRequest.performer is List<Reference>, display is String?
    String group = '';
    if (request.performer?.isNotEmpty == true) {
      group = request.performer!.first.display ?? '';
    }
        
    // Use occurrenceDateTime or authoredOn
    String time = '';
    if (request.authoredOn != null) {
      final dt = request.authoredOn!.value?.toLocal();
      if (dt != null) {
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    return {
      'id': request.id?.toString() ?? '',
      'nr': nr,
      'title': title,
      'group': group,
      'time': time,
    };
  }

  Future<void> create(Map<String, String> value) async {
    // Current time
    final now = DateTime.now();
    // Parse time string HH:MM if provided, to update today's date
    DateTime authoredOn = now;
    if (value['time'] != null && value['time']!.contains(':')) {
      final parts = value['time']!.split(':');
      if (parts.length == 2) {
         authoredOn = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      }
    }

    final Map<String, dynamic> requestJson = {
      'resourceType': 'ServiceRequest',
      'status': 'active',
      'intent': 'order',
      'subject': {'display': 'Dashboard User'},
      'identifier': [
        {'value': value['nr'] ?? ''}
      ],
      'code': {
        'concept': {
          'text': value['title'] ?? ''
        }
      },
      'performer': [
        {
          'reference': {
            'display': value['group'] ?? ''
          }
        }
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

  // Alias for DashboardPage compatibility
  Future<void> createOpenOrder(Map<String, String> value) async {
    await create(value);
  }

  Future<void> updateOpenOrder(int index, Map<String, String> value) async {
    if (index < 0 || index >= _openOrders.length) return;
    final currentMap = _openOrders[index];
    final id = currentMap['id'] ?? '';
    if (id.isEmpty) return;

    // Retrieve original resource if possible to preserve other fields
    Map<String, dynamic> requestJson;
    if (_openOrderResources.length == _openOrders.length && 
        _openOrderResources[index].id?.toString() == id) {
       requestJson = Map<String, dynamic>.from(_openOrderResources[index].toJson());
    } else {
       // Minimal fallback
       requestJson = {
         'resourceType': 'ServiceRequest',
         'id': id,
         'status': 'active',
         'intent': 'order',
         'subject': {'display': 'Dashboard User'}
       };
    }
    
    // Update fields
    if (value['nr'] != null) {
      requestJson['identifier'] = [{'value': value['nr']}];
    }
    if (value['title'] != null) {
      requestJson['code'] = {'concept': {'text': value['title']}};
    }
    if (value['group'] != null) {
      requestJson['performer'] = [{'reference': {'display': value['group']}}];
    }
    
    // Time update is tricky without date, assume today
    if (value['time'] != null && value['time']!.contains(':')) {
      final now = DateTime.now();
      final parts = value['time']!.split(':');
      if (parts.length == 2) {
         final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
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

    // To "accept" (close) order, we set status to completed
    // We can fetch the resource first to be safe or just PATCH/PUT
    // Let's rely on updateResource with status change
    
    // Need full resource to PUT validly usually, or at least required fields
    Map<String, dynamic> requestJson;
    if (_openOrderResources.length == _openOrders.length && 
        _openOrderResources[index].id?.toString() == id) {
       requestJson = Map<String, dynamic>.from(_openOrderResources[index].toJson());
    } else {
       // Fetching single resource would be safer but let's try with minimal + status
       // Actually for PUT we need the whole thing.
       // Let's assume list is in sync.
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
  
  // Method used for "closing" existing mock orders in logic
  Future<void> close(String orderNr) async {
    // Find ID from list
    // This method signature is from old mock logic where we only had nr
    // We should probably rely on index or ID.
    // Let's implement looking up by nr locally
    final item = _openOrders.where((o) => o['nr'] == orderNr).firstOrNull;
    if (item != null && item['id'] != null) {
      final index = _openOrders.indexOf(item);
      if (index != -1) {
         await acceptOpenOrder(index);
      }
    }
  }

  Future<void> reset() async {
    _openOrders = [];
    _closedOrders = [];
    await getOpenOrders();
    await getClosedOrders();
  }
} // OrderService
