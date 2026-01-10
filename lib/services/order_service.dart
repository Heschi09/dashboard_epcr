import '../models/mock_data.dart';

class OrderService {
  OrderService._internal() {
    _openOrders = List<Map<String, String>>.from(MockData.openOrders);
    _closedOrders = List<Map<String, String>>.from(MockData.closedOrders);
  }

  static final OrderService instance = OrderService._internal();

  late List<Map<String, String>> _openOrders;
  late List<Map<String, String>> _closedOrders;

  Future<List<Map<String, String>>> getOpen() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_openOrders);
  }

  Future<List<Map<String, String>>> getClosed() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_closedOrders);
  }

  Future<List<Map<String, String>>> getOpenOrders() async {
    return List<Map<String, String>>.unmodifiable(_openOrders);
  }

  Future<List<Map<String, String>>> getClosedOrders() async {
    return List<Map<String, String>>.unmodifiable(_closedOrders);
  }

  Future<void> create(Map<String, String> order) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _openOrders = [..._openOrders, Map<String, String>.from(order)];
  }

  Future<void> createOpenOrder(Map<String, String> value) async {
    _openOrders = [..._openOrders, Map<String, String>.from(value)];
  }

  Future<void> updateOpenOrder(int index, Map<String, String> value) async {
    if (index < 0 || index >= _openOrders.length) return;
    final copy = Map<String, String>.from(value);
    final next = List<Map<String, String>>.from(_openOrders);
    next[index] = copy;
    _openOrders = next;
  }

  Future<void> acceptOpenOrder(int index) async {
    if (index < 0 || index >= _openOrders.length) return;
    final order = Map<String, String>.from(_openOrders[index]);
    _openOrders.removeAt(index);
    _closedOrders = [..._closedOrders, order];
  }

  Future<void> close(String orderNr) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final order = _openOrders.firstWhere(
      (o) => o['nr'] == orderNr,
      orElse: () => {},
    );
    if (order.isNotEmpty) {
      _openOrders = _openOrders.where((o) => o['nr'] != orderNr).toList();
      _closedOrders = [..._closedOrders, order];
    }
  }

  Future<void> reset() async {
    _openOrders = List<Map<String, String>>.from(MockData.openOrders);
    _closedOrders = List<Map<String, String>>.from(MockData.closedOrders);
  }
}
