import '../models/mock_data.dart';

class AlertService {
  AlertService._internal() {
    _alerts = List<Map<String, String>>.from(MockData.alerts);
  }

  static final AlertService instance = AlertService._internal();

  late List<Map<String, String>> _alerts;

  Future<List<Map<String, String>>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_alerts);
  }

  Future<void> add(Map<String, String> alert) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _alerts = [..._alerts, Map<String, String>.from(alert)];
  }

  Future<void> addOrderAlert(String orderNr, String message, String time) async {
    // Generate next alert number
    final nextNr = _getNextAlertNumber();
    await add({
      'nr': nextNr.toString(),
      'message': message,
      'time': time,
      'type': 'Order',
    });
  }

  int _getNextAlertNumber() {
    if (_alerts.isEmpty) return 1;
    final numbers = _alerts.map((a) {
      try {
        return int.parse(a['nr'] ?? '0');
      } catch (_) {
        return 0;
      }
    }).toList();
    return (numbers.isEmpty ? 0 : numbers.reduce((a, b) => a > b ? a : b)) + 1;
  }

  void reset() {
    _alerts = List<Map<String, String>>.from(MockData.alerts);
  }
}
