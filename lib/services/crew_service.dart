import 'package:fhir/r5.dart' as r5;
import 'backend_service.dart';

class CrewService {
  CrewService._internal() {
    _items = [];
    _practitionerResources = <r5.Practitioner>[];
  }

  static final CrewService instance = CrewService._internal();

  late List<Map<String, String>> _items;
  // Original FHIR resources kept in the same order as [_items]
  late List<r5.Practitioner> _practitionerResources;

  Future<List<Map<String, String>>> getAll() async {
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
    r5.HumanName name = r5.HumanName();
    if (p.name != null && p.name!.isNotEmpty) {
       // Prioritize 'official' name, then 'usual', otherwise take the first
       name = p.name!.firstWhere(
        (n) => n.use == r5.HumanNameUse.official,
        orElse: () => p.name!.firstWhere(
          (n) => n.use == r5.HumanNameUse.usual,
          orElse: () => p.name!.first,
        ),
      );
    }

    final position = name.given?.isNotEmpty == true
        ? name.given!.join(' ')
        : '';
    final family = name.family ?? '';

    // FHIR logical ID (useful to reference the practitioner elsewhere)
    final id = p.id?.toString() ?? '';

    // Extract primary identifier value
    String primaryIdentifier = '';
    String role = 'Paramedic';
    String group = 'A';

    if (p.identifier != null && p.identifier!.isNotEmpty) {
      for (var identifier in p.identifier!) {
        final identifierValue = identifier.value?.toString() ?? '';
        final identifierSystem = identifier.system?.toString();

        if (identifierSystem == 'group') {
          group = identifierValue;
          continue;
        }

        if (primaryIdentifier.isEmpty &&
            identifierValue.isNotEmpty &&
            identifierSystem != 'group') {
          primaryIdentifier = identifierValue;
        }

        // Derive role from well-known codes if present
        final valLower = identifierValue.toLowerCase();
        if (valLower == 'driver') {
          role = 'Driver';
        } else if (valLower == 'medic') {
          role = 'Paramedic';
        } else if (valLower == 'physician') {
          role = 'Doctor';
        }
      }
    }

    return {
      'id': id,
      'group': group,
      'position': position,
      'name': position,
      'surname': family,
      'role': role,
      'identifier': primaryIdentifier,
    };
  }

  Future<void> reset() async {
     // No mock data reset anymore
     _items = [];
     await getAll();
  }

  Future<void> create(Map<String, String> value) async {
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
          given: [map['position'] ?? map['name'] ?? ''],
          family: map['surname'] ?? '',
        )
      ],
      identifier: [
        r5.Identifier(value: roleCode),
        if (map['group'] != null)
          r5.Identifier(value: map['group'], system: r5.FhirUri('group')),
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

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) {
      return;
    }


    Map<String, dynamic> practitionerJson;
    if (_practitionerResources.length == _items.length &&
        _practitionerResources[index].id?.toString() == id) {
      practitionerJson = Map<String, dynamic>.from(
          _practitionerResources[index].toJson());
    } else {
      practitionerJson = _mapToPractitioner(value).toJson();
      practitionerJson['id'] = id;
    }
    
    // Remove meta to avoid version conflicts
    practitionerJson.remove('meta');

    // Name aktualisieren
    practitionerJson['name'] = [
      {
        'given': [value['position'] ?? value['name'] ?? ''],
        'family': value['surname'] ?? '',
      }
    ];

    // Identifier aus der Role-Auswahl ableiten
    final roleCode = _roleToCode(value['role'] ?? 'Paramedic');
    final identifiers = [
      {'value': roleCode}
    ];
    if (value['group'] != null) {
      identifiers.add({'value': value['group']!, 'system': 'group'});
    }
    practitionerJson['identifier'] = identifiers;

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

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) {
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

