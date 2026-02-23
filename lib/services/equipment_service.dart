import 'package:fhir/r5.dart' as r5;
import '../config/general_constants.dart';
import 'backend_service.dart';

class EquipmentService {
  EquipmentService._internal() {
    _items = [];
  }

  static final EquipmentService instance = EquipmentService._internal();

  late List<Map<String, String>> _items;

  Future<List<Map<String, String>>> getAll() async {
    try {
      final devices = await BackendService.getAllDevices();
      if (devices.isEmpty) {
        _items = [];
        return [];
      }
      _deviceResources = devices; // Store original resources
      final serverData = devices.map((d) => _deviceToMap(d)).toList();
      _items = List<Map<String, String>>.from(serverData);
      return serverData;
    } catch (e) {
      rethrow;
    }
  }

  // Original FHIR resources kept in the same order as [_items]
  late List<r5.Device> _deviceResources;

  Map<String, String> _deviceToMap(r5.Device device) {
    String name = 'Equipment';
    // Use 'name' getter as per original file, assuming it maps to deviceName
    // Use '.value' on the item, assuming it maps to the name string
    if (device.name != null && device.name!.isNotEmpty) {
      name = device.name!.first.value ?? '';
    }

    String qty = '0';
    String target = '0';
    


    // Parse qty and target from note if available
    if (device.note != null && device.note!.isNotEmpty) {
      // Look for a note that looks like our JSON structure
      for (final annotation in device.note!) {
        final text = annotation.text?.toString() ?? '';
        if (text.startsWith('{') && text.contains('"qty"')) {
          try {
             final qtyMatch = RegExp(r'"qty"\s*:\s*"([^"]+)"').firstMatch(text);
             final targetMatch = RegExp(r'"target"\s*:\s*"([^"]+)"').firstMatch(text);
             
             if (qtyMatch != null) qty = qtyMatch.group(1) ?? '0';
             if (targetMatch != null) target = targetMatch.group(1) ?? '0';
          } catch (e) {
          }
        }
      }
    }

    return {
      'id': device.id?.toString() ?? '',
      'name': name,
      'qty': qty,
      'target': target,
    };
  }

  Future<void> reset() async {
    _items = [];
    await getAll();
  }

  Future<void> create(Map<String, String> value) async {
    final noteJson = '{"qty":"${value['qty'] ?? '0'}","target":"${value['target'] ?? '0'}"}';
    
    final Map<String, dynamic> deviceJson = {
      'resourceType': 'Device',
      'status': 'active',
      'deviceName': [
        {
          'name': value['name'] ?? 'Equipment',
          'type': 'user-friendly-name'
        }
      ],
      'note': [
        {'text': noteJson}
      ]
    };

    final statusCode = await BackendService.postResource(
      deviceJson,
      GeneralConstants.deviceResourceName,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getAll();
    }
  }

  Future<void> update(int index, Map<String, String> value) async {
    if (index < 0 || index >= _items.length) return;

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) return;

    Map<String, dynamic> deviceJson;
    if (_deviceResources.length == _items.length &&
        _deviceResources[index].id?.toString() == id) {
      deviceJson = Map<String, dynamic>.from(_deviceResources[index].toJson());
    } else {
       deviceJson = {
        'resourceType': 'Device',
        'id': id,
      };
    }

    // Update fields
    deviceJson['deviceName'] = [
      {
        'name': value['name'] ?? 'Equipment',
        'type': 'user-friendly-name'
      }
    ];

    final noteJson = '{"qty":"${value['qty'] ?? '0'}","target":"${value['target'] ?? '0'}"}';
    deviceJson['note'] = [
      {'text': noteJson}
    ];

    final statusCode = await BackendService.updateResource(
      deviceJson,
      GeneralConstants.deviceResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getAll();
    }
  }

  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) return;

    final statusCode = await BackendService.deleteResource(
      GeneralConstants.deviceResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 204) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      await getAll();
    }
  }
}

