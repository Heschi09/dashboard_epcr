import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';
import '../widgets/stat_chip.dart';
import '../widgets/quick_action_chip.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.transports,
    required this.openOrders,
    required this.closedOrders,
    // required this.onEditAlert, // Removed
    // required this.onAcceptAlert, // Removed
    required this.onEditOpenOrder,
    required this.onAcceptOpenOrder,
    required this.onTransportsTap,
    required this.onOpenTap,
    required this.onClosedTap,
    required this.onNewCrewTap,
    required this.onNewVehicleTap,
    required this.onNewEquipmentTap,
    required this.onNewOrderTap,
    required this.newOrders,
    // required this.alertsCount, // Removed
    required this.openOrdersCount,
    required this.transportViewData,
  });

  final List<Map<String, String>> transports;
  final List<Map<String, String>> openOrders;
  final List<Map<String, String>> closedOrders;
  // final ValueChanged<int> onEditAlert;
  // final ValueChanged<int> onAcceptAlert;
  final ValueChanged<int> onEditOpenOrder;
  final ValueChanged<int> onAcceptOpenOrder;
  final VoidCallback onTransportsTap;
  final VoidCallback onOpenTap;
  final VoidCallback onClosedTap;
  final VoidCallback onNewCrewTap;
  final VoidCallback onNewVehicleTap;
  final VoidCallback onNewEquipmentTap;
  final VoidCallback onNewOrderTap;
  final List<Map<String, String>> newOrders;
  // final int alertsCount;
  final int openOrdersCount;

  final List<Map<String, dynamic>> transportViewData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildSummaryCard(context)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildTransportHistoryCard()),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTransportsCard(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildOpenOrdersCard(context)),
                ],
              ),
              const SizedBox(height: 24),
              _buildClosedOrdersCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return DashboardCard(
      title: 'ePCR Dashboard',
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatChip(
                label: 'Transports',
                value: transports.length.toString(),
                onTap: onTransportsTap,
              ),
              StatChip(
                label: 'Open',
                value: openOrdersCount.toString(),
                onTap: onOpenTap,
              ),
              StatChip(
                label: 'Closed',
                value: '${closedOrders.length}',
                onTap: onClosedTap,
              ),
              // Removed StatChip for Avg Handling Time as data is gone
            ],
          ),

          // ...
          const SizedBox(height: 24),
          const Text(
            'Latest PCR',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SimpleTable(
            headers: const ['ID', 'Patient', 'Date', 'Vehicle', 'Crew'],
            columnWidths: const {
              0: FixedColumnWidth(60), // ID
              1: FlexColumnWidth(1.2), // Patient (Less space than before)
              2: FixedColumnWidth(
                160,
              ), // Date (More space to push Vehicle right)
              3: FlexColumnWidth(1), // Vehicle
              4: FlexColumnWidth(1), // Crew
            },
            rows: newOrders
                .map(
                  (item) => [
                    item['id']!,
                    item['patient']!,
                    item['date']!,
                    item['vehicle']!,
                    item['crew']!,
                  ],
                )
                .toList(),
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

  Widget _buildTransportsCard(BuildContext context) {
    return DashboardCard(
      title: 'Transports',
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No active transports',
                style: TextStyle(color: Color(0xFF8B909A)),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: transports.length,
                  itemBuilder: (context, index) {
                    final item = transports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.local_shipping,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          item['id'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item['date']} • ${item['destination']} • ${item['time']}',
                        ),
                        trailing: Chip(
                          label: Text(
                            item['status']?.toUpperCase() ?? 'UNK',
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
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
              child: Text(
                'No open orders',
                style: TextStyle(color: Color(0xFF8B909A)),
              ),
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
                    final priority = order['priority']?.toUpperCase() ?? '';
                    final isUrgent = priority == 'STAT' || priority == 'URGENT';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUrgent
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.1),
                          child: Icon(
                            isUrgent ? Icons.warning : Icons.assignment,
                            color: isUrgent ? Colors.red : Colors.blue,
                          ),
                        ),
                        title: Text(
                          '${order['title']} ${priority.isNotEmpty ? "($priority)" : ""}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order['patient'] != null &&
                                order['patient'] != 'Unknown')
                              Text(
                                'Patient: ${order['patient']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            Text('${order['location']} • ${order['time']}'),
                            if (order['licensePlate'] != null &&
                                order['licensePlate']!.isNotEmpty)
                              Text(
                                'License Plate: ${order['licensePlate']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => onEditOpenOrder(index),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              onPressed: () => onAcceptOpenOrder(index),
                              tooltip: 'Complete',
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
              child: Text(
                'No closed orders',
                style: TextStyle(color: Color(0xFF8B909A)),
              ),
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
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(order['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order['patient'] != null &&
                                order['patient'] != 'Unknown')
                              Text('Patient: ${order['patient']}'),
                            Text('${order['location']} • ${order['time']}'),
                          ],
                        ),
                        isThreeLine: true,
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

  Widget _buildTransportHistoryCard() {
    final data = transportViewData;
    final hasData = data.isNotEmpty;
    // Calculate maxY for nice scaling
    double maxY = 10;
    if (hasData) {
      final maxDur = data.fold<double>(0, (m, t) => math.max(m, t['duration']));
      maxY = (maxDur * 1.2).clamp(10, 9999).toDouble();
    }

    return DashboardCard(
      title: 'Transport Duration History (Last ${data.length})',
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 250,
            padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE3E5EA)),
            ),
            child: !hasData
                ? const Center(
                    child: Text(
                      'No transport history with valid duration',
                      style: TextStyle(color: Color(0xFF8B909A)),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: 0,
                      barGroups: List.generate(data.length, (index) {
                        final item = data[index];
                        final dur = item['duration'] as double;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: dur,
                              color: Colors.blueAccent,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) {
                                return const SizedBox.shrink();
                              }
                              // Determine interval to avoid overlapping
                              // e.g., if 20 items, show every 2nd or 3rd?
                              // For now, let's show date string rotated or just index?
                              // Showing date might be too crowded.
                              // Let's show formatted date if we have few items,
                              // or just a dot/index if many.

                              final item = data[index];
                              final dateStr = item['date'] as String;
                              // "DD.MM. HH:mm" -> get "DD.MM"
                              final shortDate = dateStr.length > 5
                                  ? dateStr.substring(0, 5)
                                  : dateStr;

                              return SideTitleWidget(
                                meta: meta,
                                space: 4,
                                child: Text(
                                  shortDate,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF7589A2),
                                  ),
                                ),
                              );
                            },
                            reservedSize: 20,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                '${value.toInt()}m',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7589A2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 5,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color(0xFFE3E5EA),
                          strokeWidth: 1,
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.blueGrey,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final index = group.x.toInt();
                            if (index < 0 || index >= data.length) return null;
                            final item = data[index];
                            return BarTooltipItem(
                              '${item['id']}\n'
                              '${item['date']}\n'
                              '${rod.toY.round()} min',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
