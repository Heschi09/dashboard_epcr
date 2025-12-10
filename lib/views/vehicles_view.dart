import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';

class VehiclesView extends StatelessWidget {
  const VehiclesView({
    super.key,
    required this.vehicles,
  });

  final List<Map<String, String>> vehicles;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DashboardCard(
        title: 'Vehicles',
        width: double.infinity,
        child: SimpleTable(
          headers: const ['Vehicle', 'License plate', 'Status'],
          rows: vehicles.map((item) => [
            item['vehicle']!,
            item['plate']!,
            item['status']!,
          ]).toList(),
        ),
      ),
    );
  }
}

