import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/navigation_item.dart';
import '../models/mock_data.dart';
import '../widgets/side_menu.dart';
import '../views/dashboard_view.dart';
import '../views/pcr_view.dart';
import '../views/crew_view.dart';
import '../views/vehicles_view.dart';
import '../views/equipment_view.dart';
import '../dialogs/detail_dialog.dart';
import '../dialogs/form_dialog.dart';
import '../services/crew_service.dart';
import '../services/vehicle_service.dart';
import '../services/equipment_service.dart';
import '../services/order_service.dart';
import '../services/alert_service.dart';
import '../services/backend_service.dart';
import '../config/backend_config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  NavigationItem _currentScreen = NavigationItem.dashboard;
  List<Map<String, String>> _crew = const [];
  List<Map<String, String>> _vehicles = const [];
  List<Map<String, String>> _equipment = const [];
  List<Map<String, String>> _alerts = const [];
  List<Map<String, String>> _openOrders = const [];
  final List<Map<String, String>> _newOrders = List.from(MockData.newOrders);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _testServerConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final results = <String>[];
    results.add('Testing Server Connection...');
    results.add('isFakeMode: ${BackendService.isFakeMode}');
    results.add('Server URL: ${BackendConfig.fhirBaseUrl.value}');
    results.add('');

    try {
      results.add('Testing: GET Practitioners...');
      final practitioners = await BackendService.getAllPractitioners();
      results.add('✅ Practitioners: ${practitioners.length} found');
      results.add('');

      results.add('Testing: GET Locations...');
      final locations = await BackendService.getAllLocations();
      results.add('✅ Locations: ${locations.length} found');
      results.add('');

      results.add('Testing: GET Devices...');
      final devices = await BackendService.getAllDevices();
      results.add('✅ Devices: ${devices.length} found');
      results.add('');

      results.add('✅ ALL TESTS PASSED');
    } on SocketException catch (e) {
      results.add('❌ NETWORK ERROR (SocketException):');
      results.add('$e');
      results.add('');
      results.add('💡 Possible causes:');
      results.add('- Server is not reachable');
      results.add('- Network connection issue');
      results.add('- Firewall blocking the connection');
    } on http.ClientException catch (e) {
      results.add('❌ CORS ERROR (ClientException):');
      results.add('$e');
      results.add('');
      results.add('💡 This is a CORS (Cross-Origin) issue!');
      results.add('The browser is blocking the request.');
      results.add('');
      results.add('✅ Solutions:');
      results.add('1. Test on mobile/desktop (no CORS there)');
      results.add('2. Enable CORS on the FHIR server');
      results.add('3. Use a proxy server');
      results.add('');
      results.add('📝 To test on mobile/desktop:');
      results.add('flutter run -d <device-id>');
      results.add('(Get device-id with: flutter devices)');
    } catch (e, stackTrace) {
      results.add('❌ ERROR:');
      results.add('Type: ${e.runtimeType}');
      results.add('Message: $e');
      results.add('');
      results.add('Stack Trace:');
      results.add(stackTrace.toString());
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Connection Test'),
        content: SingleChildScrollView(
          child: Text(
            results.join('\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInitialData() async {
    try {
      final crew = await CrewService.instance.getAll();
      final vehicles = await VehicleService.instance.getAll();
      final equipment = await EquipmentService.instance.getAll();
      final alerts = await AlertService.instance.getAll();
      final openOrders = await OrderService.instance.getOpen();
      
      if (!mounted) return;
      setState(() {
        _crew = crew;
        _vehicles = vehicles;
        _equipment = equipment;
        _alerts = alerts;
        _openOrders = openOrders;
      });
    } catch (e) {
      // Set empty lists on error
      if (mounted) {
        setState(() {
          _crew = [];
          _vehicles = [];
          _equipment = [];
        });
      }
    }
  }

  Future<void> _showAlertsDialog() async {
    final alerts = await AlertService.instance.getAll();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Alerts',
        headers: const ['Number', 'Short Message', 'Time', 'Type'],
        rows: alerts.map((item) => [
          item['nr']!,
          item['message']!,
          item['time']!,
          item['type']!,
        ]).toList(),
      ),
    );
  }

  Future<void> _showOpenDialog() async {
    final openOrders = await OrderService.instance.getOpen();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Open Orders',
        headers: const ['Number', 'Short Message + Type', 'Group / Vehicle', 'Time'],
        rows: openOrders.map((item) => [
          item['nr']!,
          item['title']!,
          item['group']!,
          item['time']!,
        ]).toList(),
      ),
    );
  }

  void _showClosedDialog() {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Closed Orders',
        headers: const ['Number', 'Short Message + Type', 'Group / Vehicle', 'Time'],
        rows: MockData.closedOrders.map((item) => [
          item['nr']!,
          item['title']!,
          item['group']!,
          item['time']!,
        ]).toList(),
      ),
    );
  }

  Future<void> _showNewCrewMemberDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => FormDialog(
        title: 'New Crew Member',
        fields: const [
          {'label': 'Group', 'hint': 'Enter group', 'key': 'group'},
          {'label': 'Name', 'hint': 'Enter name', 'key': 'name'},
          {'label': 'Surname', 'hint': 'Enter surname', 'key': 'surname'},
          {'label': 'Role', 'hint': 'Enter role', 'key': 'role'},
        ],
      ),
    );

    if (result != null) {
      await CrewService.instance.create({
        'group': result['group'] ?? 'New',
        'name': result['name'] ?? '',
        'surname': result['surname'] ?? '',
        'role': result['role'] ?? '',
      });
      final crew = await CrewService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _crew = crew;
      });
    }
  }

  Future<void> _showNewVehicleDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const FormDialog(
        title: 'New Vehicle',
        fields: [
          {'label': 'Vehicle', 'hint': 'e.g. Ambu-05', 'key': 'vehicle'},
          {'label': 'License plate', 'hint': 'e.g. RW-999', 'key': 'plate'},
        ],
      ),
    );

    if (result != null) {
      await VehicleService.instance.create({
        'vehicle': result['vehicle'] ?? '',
        'plate': result['plate'] ?? '',
        'status': 'Available',
      });
      final vehicles = await VehicleService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
      });
    }
  }

  Future<void> _showNewEquipmentDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const FormDialog(
        title: 'New Equipment',
        fields: [
          {'label': 'Name', 'hint': 'e.g. Monitor', 'key': 'name'},
          {'label': 'Quantity', 'hint': 'e.g. 1', 'key': 'qty'},
          {'label': 'Target Quantity', 'hint': 'e.g. 5', 'key': 'target'},
        ],
      ),
    );

    if (result != null) {
      await EquipmentService.instance.create({
        'name': result['name'] ?? '',
        'qty': result['qty'] ?? '0',
        'target': result['target'] ?? '0',
      });
      final equipment = await EquipmentService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _equipment = equipment;
      });
    }
  }

  Future<void> _removeCrewAt(int index) async {
    if (index < 0 || index >= _crew.length) return;
    final confirmed = await _confirmDelete('Delete crew member?');
    if (!confirmed) return;
    await CrewService.instance.deleteAt(index);
    final crew = await CrewService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _crew = crew;
    });
  }

  Future<void> _removeVehicleAt(int index) async {
    if (index < 0 || index >= _vehicles.length) return;
    final confirmed = await _confirmDelete('Delete vehicle?');
    if (!confirmed) return;
    await VehicleService.instance.deleteAt(index);
    final vehicles = await VehicleService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
    });
  }

  Future<void> _removeEquipmentAt(int index) async {
    if (index < 0 || index >= _equipment.length) return;
    final confirmed = await _confirmDelete('Delete equipment?');
    if (!confirmed) return;
    await EquipmentService.instance.deleteAt(index);
    final equipment = await EquipmentService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _equipment = equipment;
    });
  }

  Future<void> _editCrewAt(int index) async {
    if (index < 0 || index >= _crew.length) return;
    final current = _crew[index];
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => FormDialog(
        title: 'Edit Crew Member',
        initialValues: current,
        fields: const [
          {'label': 'Group', 'hint': 'Enter group', 'key': 'group'},
          {'label': 'Name', 'hint': 'Enter name', 'key': 'name'},
          {'label': 'Surname', 'hint': 'Enter surname', 'key': 'surname'},
          {'label': 'Role', 'hint': 'Enter role', 'key': 'role'},
        ],
      ),
    );
    if (result != null) {
      await CrewService.instance.update(index, {
        'group': result['group'] ?? current['group'] ?? '',
        'name': result['name'] ?? current['name'] ?? '',
        'surname': result['surname'] ?? current['surname'] ?? '',
        'role': result['role'] ?? current['role'] ?? '',
      });
      final crew = await CrewService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _crew = crew;
      });
    }
  }

  Future<void> _editVehicleAt(int index) async {
    if (index < 0 || index >= _vehicles.length) return;
    final current = _vehicles[index];
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => FormDialog(
        title: 'Edit Vehicle',
        initialValues: current,
        fields: const [
          {'label': 'Vehicle', 'hint': 'e.g. Ambu-05', 'key': 'vehicle'},
          {'label': 'License plate', 'hint': 'e.g. RW-999', 'key': 'plate'},
          {'label': 'Status', 'hint': 'Available / Maintenance', 'key': 'status'},
        ],
      ),
    );
    if (result != null) {
      await VehicleService.instance.update(index, {
        'vehicle': result['vehicle'] ?? current['vehicle'] ?? '',
        'plate': result['plate'] ?? current['plate'] ?? '',
        'status': result['status'] ?? current['status'] ?? 'Available',
      });
      final vehicles = await VehicleService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
      });
    }
  }

  Future<void> _editEquipmentAt(int index) async {
    if (index < 0 || index >= _equipment.length) return;
    final current = _equipment[index];
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => FormDialog(
        title: 'Edit Equipment',
        initialValues: current,
        fields: const [
          {'label': 'Name', 'hint': 'e.g. Monitor', 'key': 'name'},
          {'label': 'Quantity', 'hint': 'e.g. 1', 'key': 'qty'},
          {'label': 'Target Quantity', 'hint': 'e.g. 5', 'key': 'target'},
        ],
      ),
    );
    if (result != null) {
      await EquipmentService.instance.update(index, {
        'name': result['name'] ?? current['name'] ?? '',
        'qty': result['qty'] ?? current['qty'] ?? '0',
        'target': result['target'] ?? current['target'] ?? '0',
      });
      final equipment = await EquipmentService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _equipment = equipment;
      });
    }
  }

  Future<bool> _confirmDelete(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showNewOrderDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const FormDialog(
        title: 'New Order',
        fields: [
          {'label': 'Number', 'hint': 'Order number', 'key': 'nr'},
          {'label': 'Short Message + Type', 'hint': 'Enter message', 'key': 'title'},
          {'label': 'Time', 'hint': 'HH:MM', 'key': 'time'},
          {'label': 'Group', 'hint': 'Crew group', 'key': 'group'},
        ],
      ),
    );

    if (result != null) {
      // Create order
      await OrderService.instance.create({
        'nr': result['nr'] ?? '',
        'title': result['title'] ?? '',
        'time': result['time'] ?? '',
        'group': result['group'] ?? '',
      });

      // Add alert for new order
      await AlertService.instance.addOrderAlert(
        result['nr'] ?? '',
        result['title'] ?? '',
        result['time'] ?? '',
      );

      // Refresh data
      final alerts = await AlertService.instance.getAll();
      final openOrders = await OrderService.instance.getOpen();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _openOrders = openOrders;
      });
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case NavigationItem.dashboard:
        return DashboardView(
          onAlertsTap: _showAlertsDialog,
          onOpenTap: _showOpenDialog,
          onClosedTap: _showClosedDialog,
          onNewCrewTap: _showNewCrewMemberDialog,
          onNewVehicleTap: _showNewVehicleDialog,
          onNewEquipmentTap: _showNewEquipmentDialog,
          onNewOrderTap: _showNewOrderDialog,
          newOrders: _newOrders,
          alertsCount: _alerts.length,
          openOrdersCount: _openOrders.length,
        );
      case NavigationItem.pcr:
        return const PCRView();
      case NavigationItem.crew:
        return CrewView(
          crew: _crew,
          onDelete: _removeCrewAt,
          onEdit: _editCrewAt,
        );
      case NavigationItem.vehicles:
        return VehiclesView(
          vehicles: _vehicles,
          onDelete: _removeVehicleAt,
          onEdit: _editVehicleAt,
        );
      case NavigationItem.equipment:
        return EquipmentView(
          equipment: _equipment,
          onDelete: _removeEquipmentAt,
          onEdit: _editEquipmentAt,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ePCR Dashboard'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!BackendService.isFakeMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Test Server Connection',
              onPressed: _testServerConnection,
            ),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SideMenu(
              currentScreen: _currentScreen,
              onItemSelected: (item) {
                setState(() {
                  _currentScreen = item;
                });
              },
            ),
            Expanded(
              child: _buildCurrentScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
