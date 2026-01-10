import '../models/mock_data.dart';

class AlertService {
  AlertService._internal() {
    _items = List<Map<String, String>>.from(MockData.alerts);
  }

  static final AlertService instance = AlertService._internal();

  late List<Map<String, String>> _items;

  Future<List<Map<String, String>>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_items);
  }

  Future<void> reset() async {
    _items = List<Map<String, String>>.from(MockData.alerts);
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

  Future<void> addOrderAlert(String orderNr, String message, String time) async {
    // Generate next alert number
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
