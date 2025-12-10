import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';
import '../widgets/stat_chip.dart';
import '../widgets/quick_action_chip.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.onAlertsTap,
    required this.onOpenTap,
    required this.onClosedTap,
    required this.onNewCrewTap,
    required this.onNewVehicleTap,
    required this.onNewOrderTap,
    required this.newOrders,
  });

  final VoidCallback onAlertsTap;
  final VoidCallback onOpenTap;
  final VoidCallback onClosedTap;
  final VoidCallback onNewCrewTap;
  final VoidCallback onNewVehicleTap;
  final VoidCallback onNewOrderTap;
  final List<Map<String, String>> newOrders;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          _buildSummaryCard(context),
          _buildAverageHandlingCard(),
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
                value: '18',
                onTap: onAlertsTap,
              ),
              StatChip(
                label: 'Open',
                value: '5',
                onTap: onOpenTap,
              ),
              StatChip(
                label: 'Closed',
                value: '13',
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

  Widget _buildAverageHandlingCard() {
    return DashboardCard(
      title: 'Average handling Time',
      width: 400,
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
