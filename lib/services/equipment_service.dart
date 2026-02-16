import 'package:fhir/r5.dart' as r5;

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
      final serverData = devices.map((d) => _deviceToMap(d)).toList();
      _items = List<Map<String, String>>.from(serverData);
      return serverData;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _deviceToMap(r5.Device device) {
    // Check if the device name list is not empty, otherwise use fallback
    final tmp_test = device.name?.isNotEmpty == true
        ? device.name!.first.value ?? 'a'
        : 'b';

    // For equipment, we might need to aggregate quantities
    // For now, use default values
    return {
      'name': tmp_test,
      'qty': '0',
      'target': '0',
    };
  }

  Future<void> reset() async {
    _items = [];
    await getAll();
  }

  Future<void> create(Map<String, String> value) async {
    // TODO: Create FHIR Device resource for equipment
    // For now, load data from server after local add
    _items = [..._items, Map<String, String>.from(value)];

    // Reload from server to sync (once server create is implemented)
    await getAll();
  }

  Future<void> update(int index, Map<String, String> value) async {
    if (index < 0 || index >= _items.length) return;

    // TODO: Update FHIR Device (would need Device ID from server)
    // For now, reload data from server after local update
    final copy = Map<String, String>.from(value);
    final next = List<Map<String, String>>.from(_items);
    next[index] = copy;
    _items = next;

    // Reload from server to sync
    await getAll();
  }

  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;

    // TODO: Delete FHIR Device (would need Device ID from server)
    // For now, reload data from server after local delete
    final next = List<Map<String, String>>.from(_items)..removeAt(index);
    _items = next;

    // Reload from server to sync
    await getAll();
  }
}

