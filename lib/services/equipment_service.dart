import 'package:fhir/r5.dart' as r5;
import 'package:flutter/foundation.dart';
import '../config/general_constants.dart';
import 'backend_service.dart';

/// Service for managing medical equipment (Devices in FHIR).
///
/// Handles inventory tracking and CRUD operations for equipment.
class EquipmentService {
  EquipmentService._internal();

  static final EquipmentService instance = EquipmentService._internal();

  List<Map<String, String>> _items = [];
  Future<List<Map<String, String>>> getAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _items.isNotEmpty) {
      return _items;
    }
    try {
      final devices = await BackendService.getAllDevices();
      if (devices.isEmpty) {
        _items = [];
        _deviceResources = [];
        return [];
      }
      _deviceResources = devices;
      final serverData = devices.map((d) => _deviceToMap(d)).toList();
      _items = List<Map<String, String>>.from(serverData);
      return serverData;
    } catch (e) {
      debugPrint('Error fetching equipment: $e');
      return _items; // Return cache on error if available
    }
  }

  // Original FHIR resources kept for updates
  List<r5.Device> _deviceResources = [];

  Map<String, String> _deviceToMap(r5.Device device) {
    String name = 'Equipment';
    final devJson = device.toJson();

    // Strategy 1: R5 name[0].value
    if (devJson['name'] != null && devJson['name'] is List && devJson['name'].isNotEmpty) {
      name = devJson['name'][0]['value'] ?? 'Equipment';
    } 
    // Strategy 2: R4/Fallback deviceName[0].name
    else if (devJson['deviceName'] != null && devJson['deviceName'] is List && devJson['deviceName'].isNotEmpty) {
      name = devJson['deviceName'][0]['name'] ?? 'Equipment';
    }
    // Strategy 3: type.text
    else if (device.type != null && device.type!.isNotEmpty) {
      name = device.type!.first.text ?? device.type!.first.coding?.first.display ?? 'Equipment';
    }
    // Strategy 4: id fallback
    if (name == 'Equipment' && device.id != null) {
      name = 'Item ${device.id}';
    }

    return {
      'id': device.id?.toString() ?? '',
      'name': name,
    };
  }

  /// Resets local equipment state and reloads from server.
  Future<void> reset() async {
    _items = [];
    await getAll();
  }

  /// Creates a new equipment entry (Device) on the server.
  Future<void> create(Map<String, String> value) async {
    final Map<String, dynamic> deviceJson = {
      'resourceType': 'Device',
      'status': 'active',
      'deviceName': [
        {'name': value['name'] ?? 'Equipment', 'type': 'user-friendly-name'},
      ],
    };

    final statusCode = await BackendService.postResource(
      deviceJson,
      GeneralConstants.deviceResourceName,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getAll(forceRefresh: true);
    }
  }

  /// Updates quantity or target levels for an existing piece of equipment.
  Future<void> update(int index, Map<String, String> value) async {
    if (index < 0 || index >= _items.length) {
      return;
    }

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) {
      return;
    }

    Map<String, dynamic> deviceJson;
    if (_deviceResources.length == _items.length &&
        _deviceResources[index].id?.toString() == id) {
      deviceJson = Map<String, dynamic>.from(_deviceResources[index].toJson());
    } else {
      deviceJson = {'resourceType': 'Device', 'id': id};
    }

    // Update fields
    deviceJson['deviceName'] = [
      {'name': value['name'] ?? 'Equipment', 'type': 'user-friendly-name'},
    ];
    // Remove old note if exists
    deviceJson.remove('note');

    final statusCode = await BackendService.updateResource(
      deviceJson,
      GeneralConstants.deviceResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 201) {
      await getAll(forceRefresh: true);
    }
  }

  /// Removes an equipment item from the server.
  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;

    final current = _items[index];
    final id = current['id'] ?? '';
    if (id.isEmpty) return;

    final statusCode = await BackendService.deleteResource(
      GeneralConstants.deviceResourceName,
      id,
    );

    if (statusCode == 200 || statusCode == 204) {
      final next = List<Map<String, String>>.from(_items)..removeAt(index);
      _items = next;
      await getAll();
    }
  }
}
