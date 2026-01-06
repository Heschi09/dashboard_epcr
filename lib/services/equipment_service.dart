import '../models/mock_data.dart';

class EquipmentService {
  EquipmentService._internal() {
    _items = List<Map<String, String>>.from(MockData.equipment);
  }

  static final EquipmentService instance = EquipmentService._internal();

  late List<Map<String, String>> _items;

  Future<List<Map<String, String>>> getAll() async {
    return List<Map<String, String>>.unmodifiable(_items);
  }

  Future<void> reset() async {
    _items = List<Map<String, String>>.from(MockData.equipment);
  }

  Future<void> create(Map<String, String> value) async {
    _items = [..._items, Map<String, String>.from(value)];
  }

  Future<void> update(int index, Map<String, String> value) async {
    if (index < 0 || index >= _items.length) return;
    final copy = Map<String, String>.from(value);
    final next = List<Map<String, String>>.from(_items);
    next[index] = copy;
    _items = next;
  }

  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    final next = List<Map<String, String>>.from(_items)..removeAt(index);
    _items = next;
  }
}

