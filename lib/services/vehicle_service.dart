import 'package:fhir/r5.dart' as r5;
import '../models/mock_data.dart';
import '../config/general_constants.dart';
import 'backend_service.dart';

class VehicleService {
  VehicleService._internal() {
    _items = List<Map<String, String>>.from(MockData.vehicles);
    _locationResources = <r5.Location>[];
  }

  static final VehicleService instance = VehicleService._internal();

  late List<Map<String, String>> _items;
  // Original FHIR resources kept in the same order as [_items]
  late List<r5.Location> _locationResources;

  Future<List<Map<String, String>>> getAll() async {
    if (BackendService.isFakeMode) {
      return List<Map<String, String>>.unmodifiable(_items);
    }

    try {
      final locations = await BackendService.getAllLocations();
      if (locations.isEmpty) {
        _items = [];
        return [];
      }
      _locationResources = locations;
      final serverData = locations.map((l) => _locationToMap(l)).toList();
      _items = List<Map<String, String>>.from(serverData);
      return serverData;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, String> _locationToMap(r5.Location location) {
    // FHIR logical ID of the Location (useful for references)
    final id = location.id?.toString() ?? '';

    // In deinem Beispiel ist die License Plate im "name"-Feld abgelegt
    final name = location.name ?? '';

    // Beschreibung der Ambulanz (falls vorhanden)
    final String description = location.description?.toString() ?? '';

    // Status des Fahrzeugs (z.B. "active")
    final String status = location.status != null
        ? location.status.toString().split('.').last
        : 'active';

    // Typ / Rolle (z.B. Ambulance) aus Location.type.coding
    String typeDisplay = '';
    if (location.type != null && location.type!.isNotEmpty) {
      final coding = location.type!.first.coding?.first;
      if (coding != null) {
        typeDisplay =
            coding.display ?? coding.code?.value ?? '';
      }
    }

    // Für Abwärtskompatibilität behalten wir die bisherigen Keys bei:
    // - "vehicle": generische Fahrzeugbezeichnung
    // - "plate": License Plate
    return {
      'id': id,
      'vehicle': typeDisplay.isNotEmpty ? typeDisplay : 'Ambulance',
      'plate': name,
      'status': status,
      'description': description,
      'type': typeDisplay,
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

    // Erzeuge eine neue FHIR-Location für das Fahrzeug.
    final Map<String, dynamic> locationJson = {
      'resourceType': 'Location',
      'status': value['status'] ?? 'active',
      'name': value['plate'] ?? '',
      'description': value['description'] ?? '',
      'mode': 'instance',
      'type': [
        {
          'coding': [
            {
              'system': GeneralConstants.codeSystemRoleCode,
              'code': GeneralConstants.ambulanceCode,
              'display': value['vehicle'] ?? 'Ambulance',
            }
          ],
        }
      ],
    };

    final statusCode = await BackendService.postResource(
      locationJson,
      GeneralConstants.locationResourceName,
    );

    if (statusCode == 200 || statusCode == 201) {
      // Nach erfolgreichem Anlegen neu vom Server laden
      await getAll();
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

    // Ausgangspunkt ist das ursprüngliche Location-JSON,
    // damit keine Felder verloren gehen.
    Map<String, dynamic> locationJson;
    if (_locationResources.length == _items.length &&
        _locationResources[index].id?.toString() == id) {
      locationJson =
          Map<String, dynamic>.from(_locationResources[index].toJson());
    } else {
      // Fallback: minimale neue Ressource
      locationJson = {
        'resourceType': 'Location',
        'id': id,
      };
    }

    locationJson['name'] = value['plate'] ?? '';
    locationJson['description'] = value['description'] ?? '';

    // Status aus der UI übernehmen, Standard "active"
    final status = (value['status'] ?? '').isNotEmpty
        ? value['status']
        : 'active';
    locationJson['status'] = status;

    // Typ / Fahrzeugart aktualisieren
    final vehicleType = value['vehicle'] ?? 'Ambulance';
    locationJson['type'] = [
      {
        'coding': [
          {
            'system': GeneralConstants.codeSystemRoleCode,
            'code': GeneralConstants.ambulanceCode,
            'display': vehicleType,
          }
        ],
      }
    ];

    final statusCode = await BackendService.updateResource(
      locationJson,
      GeneralConstants.locationResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getAll();
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
      GeneralConstants.locationResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 204) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      await getAll();
    }
  }
}

