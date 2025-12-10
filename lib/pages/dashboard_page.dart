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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  NavigationItem _currentScreen = NavigationItem.dashboard;

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

  void _showNewCrewMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => const FormDialog(
        title: 'New Crew Member',
        fields: [
          {'label': 'Name', 'hint': 'Enter name'},
          {'label': 'Surname', 'hint': 'Enter surname'},
          {'label': 'Role', 'hint': 'Enter role'},
          {'label': 'Birthday', 'hint': 'YYYY-MM-DD'},
        ],
      ),
    );
  }

  void _showNewVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => const FormDialog(
        title: 'New Vehicle',
        fields: [
          {'label': 'Vehicle', 'hint': 'e.g. Ambu-05'},
          {'label': 'License plate', 'hint': 'e.g. RW-999'},
        ],
      ),
    );
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
          onNewOrderTap: _showNewOrderDialog,
          newOrders: MockData.newOrders,
        );
      case NavigationItem.pcr:
        return const PCRView();
      case NavigationItem.crew:
        return CrewView(crew: MockData.crew);
      case NavigationItem.vehicles:
        return VehiclesView(vehicles: MockData.vehicles);
      case NavigationItem.equipment:
        return EquipmentView(equipment: MockData.equipment);
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
