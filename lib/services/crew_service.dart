import 'package:fhir/r5.dart' as r5;
import '../models/mock_data.dart';
import 'backend_service.dart';

class CrewService {
  CrewService._internal() {
    _items = List<Map<String, String>>.from(MockData.crew);
    _practitionerResources = <r5.Practitioner>[];
  }

  static final CrewService instance = CrewService._internal();

  late List<Map<String, String>> _items;
  // Original FHIR resources kept in the same order as [_items]
  late List<r5.Practitioner> _practitionerResources;

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
      _practitionerResources = practitioners;
      final serverData =
          practitioners.map((p) => _practitionerToMap(p)).toList();
      _items = List<Map<String, String>>.from(serverData);
      return serverData;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _practitionerToMap(r5.Practitioner p) {
    final name =
        p.name?.isNotEmpty == true ? p.name!.first : r5.HumanName();

    final given = name.given?.isNotEmpty == true
        ? name.given!.join(' ')
        : '';
    final family = name.family ?? '';

    // FHIR logical ID (useful to reference the practitioner elsewhere)
    final id = p.id?.toString() ?? '';

    // Extract primary identifier value (e.g. staff number or role code)
    String primaryIdentifier = '';
    String role = 'Paramedic';
    if (p.identifier != null && p.identifier!.isNotEmpty) {
      for (var identifier in p.identifier!) {
        final identifierValue = identifier.value?.toString() ?? '';
        if (primaryIdentifier.isEmpty && identifierValue.isNotEmpty) {
          primaryIdentifier = identifierValue;
        }

        // Derive role from well-known codes if present
        if (identifierValue == 'driver') {
          role = 'Driver';
        } else if (identifierValue == 'medic') {
          role = 'Paramedic';
        } else if (identifierValue == 'physician') {
          role = 'Doctor';
        }
      }
    }


    // Extract group (if available in an identifier or extension)
    // For now, default to 'A' so the UI always has a value.
    String group = 'A';

    return {
      'id': id,
      'group': group,
      'name': given,
      'surname': family,
      'role': role,
      'identifier': primaryIdentifier,
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

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) {
      // Ohne ID können wir nicht sauber updaten – dann nur lokal anpassen.
      final copy = Map<String, String>.from(value);
      final next = List<Map<String, String>>.from(_items);
      next[index] = copy;
      _items = next;
      return;
    }

    // Versuche, das originale Practitioner-JSON zu nehmen, damit keine Felder verloren gehen.
    Map<String, dynamic> practitionerJson;
    if (_practitionerResources.length == _items.length &&
        _practitionerResources[index].id?.toString() == id) {
      practitionerJson = Map<String, dynamic>.from(
          _practitionerResources[index].toJson());
    } else {
      practitionerJson = _mapToPractitioner(value).toJson();
      practitionerJson['id'] = id;
    }

    // Name aktualisieren
    practitionerJson['name'] = [
      {
        'given': [value['name'] ?? ''],
        'family': value['surname'] ?? '',
      }
    ];

    // Identifier aus der Role-Auswahl ableiten
    final roleCode = _roleToCode(value['role'] ?? 'Paramedic');
    practitionerJson['identifier'] = [
      {'value': roleCode}
    ];

    final statusCode = await BackendService.updateResource(
      practitionerJson,
      'Practitioner',
      id,
    );

    if (statusCode == 200 || statusCode == 201) {
      final updated = await getAll();
      _items = List<Map<String, String>>.from(updated);
    }
  }

  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;

    if (BackendService.isFakeMode) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      return;
    }

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) {
      // Fallback: nur lokal löschen, wenn keine ID vorhanden ist.
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      return;
    }

    final statusCode = await BackendService.deleteResource(
      'Practitioner',
      id,
    );

    if (statusCode == 200 || statusCode == 204) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      // Liste aus dem Server neu laden, um konsistent zu bleiben
      await getAll();
    }
  }
}

