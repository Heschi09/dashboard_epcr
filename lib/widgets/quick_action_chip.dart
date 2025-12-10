import 'package:flutter/material.dart';

class QuickActionChip extends StatelessWidget {
  const QuickActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      side: const BorderSide(color: Color(0xFFE3E5EA)),
      backgroundColor: const Color(0xFFFDFDFD),
      onPressed: onTap,
    );
  }
}
