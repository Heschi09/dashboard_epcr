import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';
import '../widgets/stat_chip.dart';
import '../widgets/quick_action_chip.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.transports,
    required this.openOrders,
    required this.closedOrders,
    required this.onTransportsTap,
    required this.onOpenTap,
    required this.onClosedTap,
    required this.onNewCrewTap,
    required this.onNewVehicleTap,
    required this.onNewEquipmentTap,
    required this.onNewOrderTap,
    required this.newOrders,
    required this.openOrdersCount,
    required this.transportViewData,
    this.onTransportPcrTap,
  });

  final List<Map<String, String>> transports;
  final List<Map<String, String>> openOrders;
  final List<Map<String, String>> closedOrders;
  final VoidCallback onTransportsTap;
  final VoidCallback onOpenTap;
  final VoidCallback onClosedTap;
  final VoidCallback onNewCrewTap;
  final VoidCallback onNewVehicleTap;
  final VoidCallback onNewEquipmentTap;
  final VoidCallback onNewOrderTap;
  final List<Map<String, String>> newOrders;
  final int openOrdersCount;
  final void Function(String pcrId)? onTransportPcrTap;

  final List<Map<String, dynamic>> transportViewData;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ScrollController _transportScrollController = ScrollController();

  @override
  void dispose() {
    _transportScrollController.dispose();
    super.dispose();
  }

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
                  Expanded(
                    flex: 3,
                    child: _buildSummaryCard(context),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildTransportsCard(context),
                        const SizedBox(height: 24),
                        _buildTransportHistoryCard(),
                      ],
                    ),
                  ),
                ],
              ),
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
                value: widget.transports.length.toString(),
                onTap: widget.onTransportsTap,
              ),
              StatChip(
                label: 'Open',
                value: widget.openOrdersCount.toString(),
                onTap: widget.onOpenTap,
              ),
              StatChip(
                label: 'Closed',
                value: '${widget.closedOrders.length}',
                onTap: widget.onClosedTap,
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Latest PCR',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SimpleTable(
            headers: const ['ID', 'Patient', 'Date', 'Vehicle', 'Crew'],
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FlexColumnWidth(1.2),
              2: FixedColumnWidth(160),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            rows: widget.newOrders
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
                onTap: widget.onNewCrewTap,
              ),
              QuickActionChip(
                icon: Icons.local_shipping_outlined,
                label: 'Register new vehicle',
                onTap: widget.onNewVehicleTap,
              ),
              QuickActionChip(
                icon: Icons.medical_services_outlined,
                label: 'Register equipment',
                onTap: widget.onNewEquipmentTap,
              ),
              QuickActionChip(
                icon: Icons.assignment_add,
                label: 'Create new order',
                onTap: widget.onNewOrderTap,
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
          if (widget.transports.isEmpty)
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
                controller: _transportScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _transportScrollController,
                  shrinkWrap: true,
                  itemCount: widget.transports.length,
                  itemBuilder: (context, index) {
                    final item = widget.transports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.local_shipping,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          item['pcrId'] != null && item['pcrId']!.isNotEmpty
                              ? 'Transport: ${item['id']} | PCR: ${item['pcrId']}'
                              : 'Transport: ${item['id'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient: ${item['patient']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${item['date']} • ${item['destination']} • ${item['time']}',
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            item['status']?.toUpperCase() ?? 'UNK',
                            style: const TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          if (item['pcrId'] != null &&
                              item['pcrId']!.isNotEmpty &&
                              widget.onTransportPcrTap != null) {
                            widget.onTransportPcrTap!(item['pcrId']!);
                          }
                        },
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
    final data = widget.transportViewData;
    final hasData = data.isNotEmpty;
    double maxY = 10;
    if (hasData) {
      final maxDur = data.fold<double>(
        0,
        (m, t) => math.max(m, (t['duration'] as num).toDouble()),
      );
      maxY = (maxDur * 1.2).clamp(10, 9999).toDouble();
    }

    return DashboardCard(
      title: 'Transport Duration History (Last ${data.length})',
      width: double.infinity,
      child: SizedBox(
        height: 200,
        child:
            !hasData
                ? const Center(child: Text('Insufficient data for history'))
                : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return const Text('', style: TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups:
                        data.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: (entry.value['duration'] as num).toDouble(),
                                color: Colors.blueAccent,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
      ),
    );
  }
}
