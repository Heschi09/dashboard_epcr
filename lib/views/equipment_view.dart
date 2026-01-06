import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';

class EquipmentView extends StatelessWidget {
  const EquipmentView({
    super.key,
    required this.equipment,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Map<String, String>> equipment;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onEdit;

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
          trailingBuilder: (index) => Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => onEdit(index),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => onDelete(index),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}