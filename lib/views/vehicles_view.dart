import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';

class VehiclesView extends StatelessWidget {
  const VehiclesView({
    super.key,
    required this.vehicles,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Map<String, String>> vehicles;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DashboardCard(
        title: 'Vehicles',
        width: double.infinity,
        child: SimpleTable(
          headers: const [
            'ID',
            'License plate',
            'Vehicle type',
            'Description',
            'Status',
          ],
          rows: vehicles.map((item) {
            return [
              item['id'] ?? '',
              // Fallback: wenn "plate" leer ist (Mock-Daten), nimm "vehicle"
              item['plate']?.isNotEmpty == true
                  ? item['plate']!
                  : (item['vehicle'] ?? ''),
              item['type'] ?? item['vehicle'] ?? '',
              item['description'] ?? '',
              item['status'] ?? '',
            ];
          }).toList(),
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

