import 'package:fhir/r5.dart' as r5;
import '../models/mock_data.dart';
import 'backend_service.dart';

class CrewService {
  CrewService._internal() {
    _items = List<Map<String, String>>.from(MockData.crew);
  }

  static final CrewService instance = CrewService._internal();

  late List<Map<String, String>> _items;

  Future<List<Map<String, String>>> getAll() async {
    if (BackendService.isFakeMode) {
      return List<Map<String, String>>.unmodifiable(_items);
    }

    try {
      final practitioners = await BackendService.getAllPractitioners();
      if (practitioners.isEmpty) {
        _items = [];
        return [];
      }
      final serverData = practitioners.map((p) => _practitionerToMap(p)).toList();
      _items = List<Map<String, String>>.from(serverData);
      return serverData;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _practitionerToMap(r5.Practitioner p) {
    final name = p.name?.isNotEmpty == true
        ? p.name!.first
        : r5.HumanName();
    final given = name.given?.isNotEmpty == true
        ? name.given!.join(' ')
        : '';
    final family = name.family ?? '';

    // Extract role from identifier
    String role = 'Paramedic';
    if (p.identifier != null) {
      for (var identifier in p.identifier!) {
        final identifierValue = identifier.value ?? '';
        if (identifierValue == 'driver') {
          role = 'Driver';
        } else if (identifierValue == 'medic') {
          role = 'Paramedic';
        } else if (identifierValue == 'physician') {
          role = 'Doctor';
        }
      }
    }

    // Extract group (if available in extension or identifier)
    String group = 'A';

    return {
      'group': group,
      'name': given,
      'surname': family,
      'role': role,
    };
  }

  Future<void> reset() async {
    _items = List<Map<String, String>>.from(MockData.crew);
  }

  Future<void> create(Map<String, String> value) async {
    if (BackendService.isFakeMode) {
      _items = [..._items, Map<String, String>.from(value)];
      return;
    }

    // Create FHIR Practitioner resource
    final practitioner = _mapToPractitioner(value);
    final statusCode = await BackendService.postResource(
      practitioner.toJson(),
      'Practitioner',
    );
    if (statusCode == 200 || statusCode == 201) {
      // Refresh list
      final updated = await getAll();
      _items = List<Map<String, String>>.from(updated);
    }
  }

  r5.Practitioner _mapToPractitioner(Map<String, String> map) {
    final roleCode = _roleToCode(map['role'] ?? 'Paramedic');
    return r5.Practitioner(
      name: [
        r5.HumanName(
          given: [map['name'] ?? ''],
          family: map['surname'] ?? '',
        )
      ],
      identifier: [
        r5.Identifier(value: roleCode),
      ],
    );
  }

  String _roleToCode(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return 'driver';
      case 'doctor':
      case 'physician':
        return 'physician';
      default:
        return 'medic';
    }
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

    // TODO: Update FHIR Practitioner (would need Practitioner ID from server)
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

    if (BackendService.isFakeMode) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      return;
    }

    // TODO: Delete FHIR Practitioner (would need Practitioner ID from server)
    // For now, reload data from server after local delete
    final next = List<Map<String, String>>.from(_items)..removeAt(index);
    _items = next;
    
    // Reload from server to sync
    await getAll();
  }
}

