import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';

class EquipmentView extends StatelessWidget {
  const EquipmentView({
    super.key,
    required this.equipment,
  });

  final List<Map<String, String>> equipment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DashboardCard(
        title: 'Equipment',
        width: double.infinity,
        child: SimpleTable(
          headers: const ['Name', 'Quantity', 'Target Quantity'],
          rows: equipment.map((item) => [
            item['name']!,
            item['qty']!,
            item['target']!,
          ]).toList(),
        ),
      ),
    );
  }
}