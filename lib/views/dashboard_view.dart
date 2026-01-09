import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';
import '../widgets/stat_chip.dart';
import '../widgets/quick_action_chip.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.alerts,
    required this.openOrders,
    required this.closedOrders,
    required this.onEditAlert,
    required this.onAcceptAlert,
    required this.onEditOpenOrder,
    required this.onAcceptOpenOrder,
    required this.onAlertsTap,
    required this.onOpenTap,
    required this.onClosedTap,
    required this.onNewCrewTap,
    required this.onNewVehicleTap,
    required this.onNewEquipmentTap,
    required this.onNewOrderTap,
    required this.newOrders,
  });

  final List<Map<String, String>> alerts;
  final List<Map<String, String>> openOrders;
  final List<Map<String, String>> closedOrders;
  final ValueChanged<int> onEditAlert;
  final ValueChanged<int> onAcceptAlert;
  final ValueChanged<int> onEditOpenOrder;
  final ValueChanged<int> onAcceptOpenOrder;
  final VoidCallback onAlertsTap;
  final VoidCallback onOpenTap;
  final VoidCallback onClosedTap;
  final VoidCallback onNewCrewTap;
  final VoidCallback onNewVehicleTap;
  final VoidCallback onNewEquipmentTap;
  final VoidCallback onNewOrderTap;
  final List<Map<String, String>> newOrders;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAlertsCard(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildOpenOrdersCard(context)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildClosedOrdersCard(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildAverageHandlingCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return DashboardCard(
      title: 'ePCR Dashboard',
      width: 800,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatChip(
                label: 'Alerts',
                value: '${alerts.length}',
                onTap: onAlertsTap,
              ),
              StatChip(
                label: 'Open',
                value: '${openOrders.length}',
                onTap: onOpenTap,
              ),
              StatChip(
                label: 'Closed',
                value: '${closedOrders.length}',
                onTap: onClosedTap,
              ),
              const StatChip(
                label: 'Avg Handling Time',
                value: '12 min',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'New',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SimpleTable(
            headers: const ['Patient', 'Date', 'Vehicle', 'Crew'],
            rows: newOrders.map((item) => [
              item['patient']!,
              item['date']!,
              item['vehicle']!,
              item['crew']!,
            ]).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              QuickActionChip(
                icon: Icons.person_add_alt,
                label: 'New crew member',
                onTap: onNewCrewTap,
              ),
              QuickActionChip(
                icon: Icons.local_shipping_outlined,
                label: 'Register new vehicle',
                onTap: onNewVehicleTap,
              ),
              QuickActionChip(
                icon: Icons.medical_services_outlined,
                label: 'Register equipment',
                onTap: onNewEquipmentTap,
              ),
              QuickActionChip(
                icon: Icons.assignment_add,
                label: 'Create new order',
                onTap: onNewOrderTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard(BuildContext context) {
    return DashboardCard(
      title: 'Alerts',
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No alerts', style: TextStyle(color: Color(0xFF8B909A))),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(alert['message'] ?? ''),
                        subtitle: Text('${alert['time']} - ${alert['type']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => onEditAlert(index),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              onPressed: () => onAcceptAlert(index),
                              tooltip: 'Accept',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpenOrdersCard(BuildContext context) {
    return DashboardCard(
      title: 'Open Orders',
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (openOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No open orders', style: TextStyle(color: Color(0xFF8B909A))),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: openOrders.length,
                  itemBuilder: (context, index) {
                    final order = openOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(order['title'] ?? ''),
                        subtitle: Text('${order['group']} - ${order['time']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => onEditOpenOrder(index),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              onPressed: () => onAcceptOpenOrder(index),
                              tooltip: 'Accept with team',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClosedOrdersCard(BuildContext context) {
    return DashboardCard(
      title: 'Closed Orders',
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (closedOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No closed orders', style: TextStyle(color: Color(0xFF8B909A))),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: closedOrders.length,
                  itemBuilder: (context, index) {
                    final order = closedOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(order['title'] ?? ''),
                        subtitle: Text('${order['group']} - ${order['time']}'),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAverageHandlingCard() {
    return DashboardCard(
      title: 'Average handling Time',
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'day', label: Text('Day')),
              ButtonSegment(value: 'month', label: Text('Month')),
              ButtonSegment(value: 'year', label: Text('Year')),
            ],
            selected: const {'day'},
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE3E5EA)),
            ),
            child: const Center(
              child: Text('Chart placeholder'),
            ),
          ),
        ],
      ),
    );
  }
}
