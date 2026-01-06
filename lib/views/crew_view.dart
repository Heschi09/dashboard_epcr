import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/simple_table.dart';

class CrewView extends StatelessWidget {
  const CrewView({
    super.key,
    required this.crew,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Map<String, String>> crew;
  final ValueChanged<int> onDelete;
  final ValueChanged<int> onEdit;

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
