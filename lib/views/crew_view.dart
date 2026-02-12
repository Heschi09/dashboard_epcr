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
          headers: const [
            'ID',
            'Name',
            'Surname',
            'Role',
          ],
          rows: crew.map((item) {
            return [
              item['id'] ?? '',
              item['name'] ?? '',
              item['surname'] ?? '',
              // In der "Role"-Spalte soll jetzt der Identifier angezeigt werden
              item['identifier'] ?? '',
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
