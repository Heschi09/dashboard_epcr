import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';

class CrewView extends StatelessWidget {
  const CrewView({
    super.key,
    required this.crew,
  });

  final List<Map<String, String>> crew;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: DashboardCard(
        title: 'Crew',
        width: double.infinity,
        child: SimpleTable(
          headers: const ['Group', 'Name', 'Surname', 'Role'],
          rows: crew.map((item) => [
            item['group']!,
            item['name']!,
            item['surname']!,
            item['role']!,
          ]).toList(),
        ),
      ),
    );
  }
}
