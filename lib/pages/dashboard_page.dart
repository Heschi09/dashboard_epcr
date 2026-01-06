import 'package:flutter/material.dart';
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
  final List<Map<String, String>> _newOrders = List.from(MockData.newOrders);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final crew = await CrewService.instance.getAll();
    final vehicles = await VehicleService.instance.getAll();
    final equipment = await EquipmentService.instance.getAll();
    if (!mounted) return;
    setState(() {
      _crew = crew;
      _vehicles = vehicles;
      _equipment = equipment;
    });
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Alerts',
        headers: const ['Number', 'Short Message', 'Time', 'Type'],
        rows: MockData.alerts.map((item) => [
          item['nr']!,
          item['message']!,
          item['time']!,
          item['type']!,
        ]).toList(),
      ),
    );
  }

  void _showOpenDialog() {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        title: 'Open Orders',
        headers: const ['Number', 'Short Message + Type', 'Group / Vehicle', 'Time'],
        rows: MockData.openOrders.map((item) => [
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

  void _showNewOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => const FormDialog(
        title: 'New Order',
        fields: [
          {'label': 'Number', 'hint': 'Order number'},
          {'label': 'Short Message + Type', 'hint': 'Enter message'},
          {'label': 'Time', 'hint': 'HH:MM'},
          {'label': 'Group', 'hint': 'Crew group'},
          {'label': 'Vehicle', 'hint': 'Vehicle ID'},
        ],
      ),
    );
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
