import 'package:fhir/r5.dart' as r5;
import '../models/mock_data.dart';
import 'backend_service.dart';

class EquipmentService {
  EquipmentService._internal() {
    _items = List<Map<String, String>>.from(MockData.equipment);
  }

  static final EquipmentService instance = EquipmentService._internal();

  late List<Map<String, String>> _items;

  Future<List<Map<String, String>>> getAll() async {
    if (BackendService.isFakeMode) {
      return List<Map<String, String>>.unmodifiable(_items);
    }

    try {
      final devices = await BackendService.getAllDevices();
      if (devices.isEmpty) {
        return [];
      }
      return devices.map((d) => _deviceToMap(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _deviceToMap(r5.Device device) {
    final name = device.type?.isNotEmpty == true
        ? device.type!.first.text ?? device.type!.first.coding?.firstOrNull?.display ?? 'Unknown'
        : 'Unknown';
    
    // For equipment, we might need to aggregate quantities
    // For now, use default values
    return {
      'name': name,
      'qty': '0',
      'target': '0',
    };
  }

  Future<void> reset() async {
    _items = List<Map<String, String>>.from(MockData.equipment);
  }

  Future<void> create(Map<String, String> value) async {
    if (BackendService.isFakeMode) {
      _items = [..._items, Map<String, String>.from(value)];
      return;
    }

    // TODO: Create FHIR Device resource for equipment
    // For now, just add to local list
    _items = [..._items, Map<String, String>.from(value)];
  }

  Future<void> update(int index, Map<String, String> value) async {
    if (index < 0 || index >= _items.length) return;

    if (BackendService.isFakeMode) {
      final copy = Map<String, String>.from(value);
      final next = List<Map<String, String>>.from(_items);
      next[index] = copy;
      _items = next;
      return;
    }

    // TODO: Update FHIR Device (would need Device ID)
    // For now, just update local list
    final copy = Map<String, String>.from(value);
    final next = List<Map<String, String>>.from(_items);
    next[index] = copy;
    _items = next;
  }

  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;

    if (BackendService.isFakeMode) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      return;
    }

    // TODO: Delete FHIR Device (would need Device ID)
    // For now, just update local list
    final next = List<Map<String, String>>.from(_items)..removeAt(index);
    _items = next;
  }
}

