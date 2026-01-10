import '../models/mock_data.dart';

class PcrService {
  PcrService._internal() {
    _encounters = List<Map<String, dynamic>>.from(MockData.pcrEncounters);
  }

  static final PcrService instance = PcrService._internal();

  late List<Map<String, dynamic>> _encounters;

  Future<List<Map<String, dynamic>>> getAll() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_encounters);
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _encounters.firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(
      _encounters.where((e) {
        final encounter = e['encounter'] as Map<String, dynamic>?;
        return encounter?['status'] == status;
      }).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getOpen() async {
    return getByStatus('in-progress');
  }

  Future<List<Map<String, dynamic>>> getClosed() async {
    return getByStatus('finished');
  }

  void reset() {
    _encounters = List<Map<String, dynamic>>.from(MockData.pcrEncounters);
  }

  // For future use: add, update, delete methods
  // These will be implemented when we connect to FHIR server
  Future<void> add(Map<String, dynamic> encounter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _encounters = [..._encounters, Map<String, dynamic>.from(encounter)];
  }

  Future<void> update(String id, Map<String, dynamic> encounter) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _encounters.indexWhere((e) => e['id'] == id);
    if (index >= 0) {
      final next = List<Map<String, dynamic>>.from(_encounters);
      next[index] = Map<String, dynamic>.from(encounter);
      _encounters = next;
    }
  }

  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _encounters = _encounters.where((e) => e['id'] != id).toList();
  }
}
