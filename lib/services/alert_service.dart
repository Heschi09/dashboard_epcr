
import 'package:fhir/r5.dart' as r5;
import '../config/general_constants.dart';
import '../config/backend_config.dart';
import 'backend_service.dart';

class AlertService {
  AlertService._internal() {
    _items = [];
  }

  static final AlertService instance = AlertService._internal();

  List<Map<String, String>> _items = [];
  List<r5.Flag> _flagResources = [];

  Future<List<Map<String, String>>> getAll() async {
    try {
      final resources = await _fetchFlags();
      _flagResources = resources;
      _items = resources.map((f) => _flagToMap(f)).toList();
      return _items;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<r5.Flag>> _fetchFlags() async {
    String? url = '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.flagResourceName}?status=active';
    List<r5.Flag> flags = [];
    while (url != null) {
      final bundle = await BackendService.getBundle(url);
      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.Flag) {
            flags.add(entry.resource as r5.Flag);
          }
        }
      }
      url = BackendService.getNextPageUrl(bundle);
    }
    return flags;
  }
  
  Map<String, String> _flagToMap(r5.Flag flag) {
    String nr = flag.identifier?.isNotEmpty == true
        ? flag.identifier!.first.value ?? ''
        : '';
    // Flag.code is CodeableConcept, text is String?
    String message = flag.code.text ?? '';
    
    String type = 'Info';
    // Flag.category is List<CodeableConcept>
    if (flag.category != null && flag.category!.isNotEmpty) {
      type = flag.category!.first.text ?? 'Info';
    }
    
    String time = '';
    if (flag.period?.start != null) {
       final dt = flag.period!.start!.value?.toLocal();
       if (dt != null) {
         time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
       }
    }

    return {
      'id': flag.id?.toString() ?? '',
      'nr': nr,
      'message': message,
      'type': type,
      'time': time,
    };
  }

  Future<void> reset() async {
    _items = [];
    await getAll();
  }

  Future<void> create(Map<String, String> value) async {
    // Current time
    final now = DateTime.now();
    DateTime startTime = now;
    if (value['time'] != null && value['time']!.contains(':')) {
      final parts = value['time']!.split(':');
      if (parts.length == 2) {
         startTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      }
    }
    
    final Map<String, dynamic> flagJson = {
      'resourceType': 'Flag',
      'status': 'active',
      'subject': {'display': 'Dashboard User'},
      'identifier': [
        {'value': value['nr'] ?? ''}
      ],
      'code': {
        'text': value['message'] ?? ''
      },
      'category': [
        {
          'text': value['type'] ?? 'Info'
        }
      ],
      'period': {
        'start': startTime.toIso8601String()
      }
    };

    final statusCode = await BackendService.postResource(
      flagJson,
      GeneralConstants.flagResourceName,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getAll();
    }
  }

  Future<void> update(int index, Map<String, String> value) async {
    if (index < 0 || index >= _items.length) return;
    
    final currentMap = _items[index];
    final id = currentMap['id'] ?? '';
    if (id.isEmpty) return;

    Map<String, dynamic> flagJson;
    if (_flagResources.length == _items.length && 
        _flagResources[index].id?.toString() == id) {
       flagJson = Map<String, dynamic>.from(_flagResources[index].toJson());
    } else {
       flagJson = {
         'resourceType': 'Flag',
         'id': id,
         'status': 'active',
         'subject': {'display': 'Dashboard User'}
       };
    }

    if (value['nr'] != null) {
      flagJson['identifier'] = [{'value': value['nr']}];
    }
    if (value['message'] != null) {
      flagJson['code'] = {'text': value['message']};
    }
    if (value['type'] != null) {
      flagJson['category'] = [{'text': value['type']}];
    }
    if (value['time'] != null && value['time']!.contains(':')) {
      final now = DateTime.now();
      final parts = value['time']!.split(':');
      if (parts.length == 2) {
         final dt = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
         flagJson['period'] = {'start': dt.toIso8601String()};
      }
    }

    final statusCode = await BackendService.updateResource(
      flagJson,
      GeneralConstants.flagResourceName,
      id,
    );
    
    if (statusCode == 200 || statusCode == 201) {
      await getAll();
    }
  }

  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    final currentMap = _items[index];
    final id = currentMap['id'] ?? '';
    if (id.isEmpty) return;
    
    // "Accept" alert -> delete logic requested by user ("delete all things")
    // Or set to inactive. Let's delete to keep it clean if user wants "delete".
    // Actually typically we flag as inactive. But user said "Remove all mock data, interact with server".
    // "deleteAt" implies removal.
    final statusCode = await BackendService.deleteResource(
       GeneralConstants.flagResourceName,
       id,
    );
    
    if (statusCode == 200 || statusCode == 204) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      await getAll();
    }
  }

  Future<void> addOrderAlert(String orderNr, String message, String time) async {
    // Generate next alert number? 
    // Logic on server side generation is hard without transaction. 
    // We will simple fetch all to find maxnr? Too expensive.
    // Let's just use a random or timestamp based nr, or just "1" if we don't care about uniqueness for now.
    // Or keep logic: fetch all, find max.
    await getAll();
    final nextNr = _getNextAlertNumber();
    
    await create({
      'nr': nextNr.toString(),
      'message': message,
      'time': time,
      'type': 'Order',
    });
  }

  int _getNextAlertNumber() {
    if (_items.isEmpty) return 1;
    final numbers = _items.map((a) {
      try {
        return int.parse(a['nr'] ?? '0');
      } catch (_) {
        return 0;
      }
    }).toList();
    return (numbers.isEmpty ? 0 : numbers.reduce((a, b) => a > b ? a : b)) + 1;
  }
}
