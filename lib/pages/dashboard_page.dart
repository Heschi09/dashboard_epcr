import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';
import '../models/navigation_item.dart';
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
import '../services/pcr_service.dart';
import '../services/backend_service.dart';
import '../services/transport_service.dart';

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
  List<Map<String, String>> _transports = const [];
  List<Map<String, String>> _openOrders = const [];
  List<Map<String, String>> _closedOrders = const [];
  final List<Map<String, String>> _newOrders = [];

  // Chart Data
  // Chart Data
  List<Map<String, dynamic>> _transportViewData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _testServerConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final results = <String>[];
    results.add('Testing Server Connection...');
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
      final transports = await TransportService.instance.getAll();
      final openOrders = await OrderService.instance.getOpenOrders();
      final closedOrders = await OrderService.instance.getClosedOrders();
      final recentReports = await PcrService.instance.getRecentReports(5);

      // Populate New Orders with the top 5 most recent ePCR reports
      _newOrders.clear();
      if (recentReports.isNotEmpty) {
        for (var report in recentReports) {
          String formattedDate = report['date'] ?? '';
          try {
            if (formattedDate.isNotEmpty) {
              final dt = DateTime.parse(formattedDate).toLocal();
              String twoDigits(int n) => n.toString().padLeft(2, '0');
              formattedDate =
                  '${twoDigits(dt.day)}.${twoDigits(dt.month)}.${dt.year} ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
            }
          } catch (_) {}

          _newOrders.add({
            'id': report['id'] ?? '',
            'patient': report['patient'] ?? 'Unknown',
            'date': formattedDate,
            'vehicle': report['vehicle'] ?? 'N/A',
            'crew': report['driver'] ?? 'N/A',
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _crew = crew;
        _vehicles = vehicles;
        _equipment = equipment;
        _transports = transports;
        _openOrders = openOrders;
        _closedOrders = closedOrders;
        // Calculate chart data
        _calculateChartData();
      });
    } catch (e) {
      // Set empty lists on error
      if (mounted) {
        setState(() {
          _crew = [];
          _vehicles = [];
          _equipment = [];
          _transports = [];
          _openOrders = [];
          _closedOrders = [];
          _openOrders = [];
          _closedOrders = [];
          _transportViewData = [];
        });
      }
    }
  }

  void _calculateChartData() {
    // Prepare data for Transport Duration History Chart
    // Filter valid transports with duration
    final validTransports = _transports.where((t) {
      final hasStart = t['startIso'] != null && t['startIso']!.isNotEmpty;
      final dur = double.tryParse(t['duration'] ?? '') ?? 0;
      return hasStart && dur > 0;
    }).toList();

    // Sort chronologically (oldest to newest) for the chart
    validTransports.sort((a, b) {
      final dA = DateTime.tryParse(a['startIso']!) ?? DateTime(0);
      final dB = DateTime.tryParse(b['startIso']!) ?? DateTime(0);
      return dA.compareTo(dB);
    });

    // Take last 20 to avoid overcrowding
    final historyCount = 20;
    final startIndex = validTransports.length > historyCount
        ? validTransports.length - historyCount
        : 0;
    _transportViewData = validTransports.sublist(startIndex).map((t) {
      return {
        'id': t['id'] ?? 'Unknown',
        'patient': t['patient'] ?? 'Unknown',
        'date': t['date'] ?? '',
        'duration': double.tryParse(t['duration'] ?? '') ?? 0.0,
        'status': t['status'] ?? '',
      };
    }).toList();
  }


  void _showTransportsDialog() {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Transports',
        headers: const [
          'ID',
          'Patient',
          'Destination',
          'Start',
          'End',
          'Status',
          'Duration',
        ],
        rows: _transports.map((item) {
          String formatTime(String? iso) {
            if (iso == null || iso.isEmpty) return '--:--';
            try {
              final dt = DateTime.parse(iso).toLocal();
              return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {
              return '';
            }
          }

          final start = formatTime(item['startIso']);
          final end = formatTime(item['endIso']);

          return [
            item['id'] ?? '',
            item['patient']!,
            item['destination']!,
            start,
            end,
            item['status']!,
            item['time']!,
          ];
        }).toList(),
      ),
    );
  }

  void _showOpenDialog() {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Open Orders',
        headers: const [
          'ID',
          'Title',
          'Patient',
          'Loc',
          'Priority',
          'Status',
          'License Plate',
          'Time',
        ],
        rows: _openOrders
            .map(
              (item) => [
                item['displayId'] ?? '',
                item['title'] ?? '',
                item['patient'] ?? '',
                item['location'] ?? '',
                item['priority']?.toUpperCase() ?? '',
                item['status'] ?? '',
                item['licensePlate'] ?? '',
                item['time'] ?? '',
              ],
            )
            .toList(),
      ),
    );
  }

  Future<void> _editOpenOrderAt(int index) async {
    if (index < 0 || index >= _openOrders.length) return;
    final current = _openOrders[index];
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => FormDialog(
        title: 'Edit Open Order',
        initialValues: current,
        fields: const [
          {'label': 'ID', 'hint': 'Order ID', 'key': 'displayId'},
          {'label': 'Title', 'hint': 'Enter title', 'key': 'title'},
          {'label': 'Reason', 'hint': 'Specific reason', 'key': 'reason'},
          {'label': 'Patient', 'hint': 'Patient Name', 'key': 'patient'},
          {'label': 'Location', 'hint': 'Address/Sector', 'key': 'location'},
          {
            'label': 'Priority',
            'hint': 'routine, urgent, stat',
            'key': 'priority',
            'type': 'dropdown',
            'options': 'Routine,High Priority,Urgent,Critical,Emergency',
          },
          {
            'label': 'License Plate',
            'hint': 'Enter license plate',
            'key': 'licensePlate',
          },
          {'label': 'Time', 'hint': 'HH:MM', 'key': 'time'},
        ],
      ),
    );
    if (result != null) {
      await OrderService.instance.updateOpenOrder(index, {
        'displayId': result['displayId'] ?? current['displayId'] ?? '',
        'title': result['title'] ?? current['title'] ?? '',
        'reason': result['reason'] ?? current['reason'] ?? '',
        'patient': result['patient'] ?? current['patient'] ?? '',
        'location': result['location'] ?? current['location'] ?? '',
        'priority': result['priority'] ?? current['priority'] ?? 'routine',
        'licensePlate': result['licensePlate'] ?? current['licensePlate'] ?? '',
        'time': result['time'] ?? current['time'] ?? '',
      });
      final openOrders = await OrderService.instance.getOpenOrders();
      if (!mounted) return;
      setState(() {
        _openOrders = openOrders;
      });
    }
  }

  Future<void> _acceptOpenOrderAt(int index) async {
    if (index < 0 || index >= _openOrders.length) return;
    await OrderService.instance.acceptOpenOrder(index);
    final openOrders = await OrderService.instance.getOpenOrders();
    final closedOrders = await OrderService.instance.getClosedOrders();
    if (!mounted) return;
    setState(() {
      _openOrders = openOrders;
      _closedOrders = closedOrders;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order accepted by team')));
  }

  void _showClosedDialog() {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Closed Orders',
        headers: const [
          'ID',
          'Title',
          'Patient',
          'Loc',
          'Priority',
          'Outcome',
          'License Plate',
          'Time',
        ],
        rows: _closedOrders
            .map(
              (item) => [
                item['displayId'] ?? '',
                item['title'] ?? '',
                item['patient'] ?? '',
                item['location'] ?? '',
                item['priority']?.toUpperCase() ?? '',
                'Completed',
                item['licensePlate'] ?? '',
                item['time'] ?? '',
              ],
            )
            .toList(),
      ),
    );
  }

  Future<void> _showNewCrewMemberDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => FormDialog(
        title: 'New Crew Member',
        fields: const [
          {'label': 'Position', 'hint': 'e.g. First', 'key': 'position'},
          {'label': 'Last Name', 'hint': 'e.g. Driver', 'key': 'surname'},
          {
            'label': 'Role',
            'hint': 'Select role',
            'key': 'role',
            'type': 'dropdown',
            'options': 'Driver,Medic,Physician',
          },
        ],
      ),
    );

    if (result != null) {
      await CrewService.instance.create({
        'position': result['position'] ?? '',
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
        title: 'Register new vehicle',
        fields: [
          {'label': 'License plate', 'hint': 'e.g. RW-999', 'key': 'plate'},
          {
            'label': 'Vehicle type',
            'hint': 'e.g. Ambulance, Ambu-05',
            'key': 'vehicle',
          },
          {
            'label': 'Description',
            'hint': 'Optional description',
            'key': 'description',
            'required': 'false',
          },
          {
            'label': 'Status',
            'hint': 'Select status',
            'key': 'status',
            'type': 'dropdown',
            'options': 'Active,On Mission,Maintenance',
          },
        ],
      ),
    );

    if (result != null) {
      await VehicleService.instance.create({
        'plate': result['plate'] ?? '',
        'vehicle': result['vehicle'] ?? 'Ambulance',
        'description': result['description'] ?? '',
        'status': result['status'] ?? 'Active',
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
          {'label': 'Position', 'hint': 'e.g. First', 'key': 'position'},
          {'label': 'Last Name', 'hint': 'e.g. Driver', 'key': 'surname'},
          {
            'label': 'Role',
            'hint': 'Select role',
            'key': 'role',
            'type': 'dropdown',
            'options': 'Driver,Medic,Physician',
          },
        ],
      ),
    );
    if (result != null) {
      await CrewService.instance.update(index, {
        'position': result['position'] ?? current['position'] ?? '',
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
          {
            'label': 'Status',
            'hint': 'Select status',
            'key': 'status',
            'type': 'dropdown',
            'options': 'Active,On Mission,Maintenance',
          },
        ],
      ),
    );
    if (result != null) {
      await VehicleService.instance.update(index, {
        'vehicle': result['vehicle'] ?? current['vehicle'] ?? '',
        'plate': result['plate'] ?? current['plate'] ?? '',
        'status': result['status'] ?? current['status'] ?? 'Active',
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
          {'label': 'ID', 'hint': 'Order ID', 'key': 'displayId'},
          {'label': 'Title', 'hint': 'Enter title', 'key': 'title'},
          {'label': 'Patient', 'hint': 'Patient Name', 'key': 'patient'},
          {'label': 'Location', 'hint': 'Address/Sector', 'key': 'location'},
          {
            'label': 'Priority',
            'hint': 'routine, urgent, stat',
            'key': 'priority',
            'type': 'dropdown',
            'options': 'Routine,High Priority,Urgent,Critical,Emergency',
          },
          {
            'label': 'License Plate',
            'hint': 'Assigned Vehicle',
            'key': 'licensePlate',
          },
          {'label': 'Time', 'hint': 'HH:MM', 'key': 'time'},
        ],
      ),
    );

    if (result != null) {
      // Create order
      await OrderService.instance.create({
        'displayId': result['displayId'] ?? '',
        'title': result['title'] ?? '',
        'patient': result['patient'] ?? '',
        'location': result['location'] ?? '',
        'priority': result['priority'] ?? 'routine',
        'licensePlate': result['licensePlate'] ?? '',
        'time': result['time'] ?? '',
      });

      // Refresh data
      final openOrders = await OrderService.instance.getOpenOrders();
      if (!mounted) return;
      setState(() {
        _openOrders = openOrders;
      });
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case NavigationItem.dashboard:
        return DashboardView(
          transports: _transports,
          openOrders: _openOrders,
          closedOrders: _closedOrders,
          onEditOpenOrder: _editOpenOrderAt,
          onAcceptOpenOrder: _acceptOpenOrderAt,
          onTransportsTap: _showTransportsDialog,
          onOpenTap: _showOpenDialog,
          onClosedTap: _showClosedDialog,
          onNewCrewTap: _showNewCrewMemberDialog,
          onNewVehicleTap: _showNewVehicleDialog,
          onNewEquipmentTap: _showNewEquipmentDialog,
          onNewOrderTap: _showNewOrderDialog,
          newOrders: _newOrders,
          openOrdersCount: _openOrders.length,
          transportViewData: _transportViewData,
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
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Reload data from server',
            onPressed: () async {
              await _loadInitialData();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data reloaded from server')),
              );
            },
          ),
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
            Expanded(child: _buildCurrentScreen()),
          ],
        ),
      ),
    );
  }
}
