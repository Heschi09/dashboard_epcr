import 'package:fhir/r5.dart' as r5;
import '../models/mock_data.dart';
import 'backend_service.dart';

class VehicleService {
  VehicleService._internal() {
    _items = List<Map<String, String>>.from(MockData.vehicles);
  }

  static final VehicleService instance = VehicleService._internal();

  late List<Map<String, String>> _items;

  Future<List<Map<String, String>>> getAll() async {
    if (BackendService.isFakeMode) {
      return List<Map<String, String>>.unmodifiable(_items);
    }

    try {
      final locations = await BackendService.getAllLocations();
      if (locations.isEmpty) {
        return [];
      }
      return locations.map((l) => _locationToMap(l)).toList();
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  Map<String, String> _locationToMap(r5.Location location) {
    final name = location.name ?? '';
    final status = location.status?.toString() ?? 'Available';
    
    // Extract license plate from identifier or name
    String plate = '';
    if (location.identifier != null && location.identifier!.isNotEmpty) {
      plate = location.identifier!.first.value?.toString() ?? '';
    }

    return {
      'vehicle': name,
      'plate': plate,
      'status': status,
    };
  }

  Future<void> reset() async {
    _items = List<Map<String, String>>.from(MockData.vehicles);
  }

  Future<void> create(Map<String, String> value) async {
    if (BackendService.isFakeMode) {
      _items = [..._items, Map<String, String>.from(value)];
      return;
    }

    // TODO: Create FHIR Location resource for vehicle
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

    // TODO: Update FHIR Location (would need Location ID)
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

    // TODO: Delete FHIR Location (would need Location ID)
    // For now, just update local list
    final next = List<Map<String, String>>.from(_items)..removeAt(index);
    _items = next;
  }
}

