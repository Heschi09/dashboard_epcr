import 'package:flutter/material.dart';
import '../models/navigation_item.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.currentScreen,
    required this.onItemSelected,
  });

  final NavigationItem currentScreen;
  final ValueChanged<NavigationItem> onItemSelected;

  static const items = [
    (NavigationItem.dashboard, 'Dashboard'),
    (NavigationItem.pcr, 'PCR'),
    (NavigationItem.crew, 'Crew'),
    (NavigationItem.vehicles, 'Vehicles'),
    (NavigationItem.equipment, 'Equipment'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 16, top: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (item, label) in items)
            MenuButton(
              label: label,
              selected: currentScreen == item,
              onTap: () => onItemSelected(item),
            ),
        ],
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: selected ? primary : const Color(0xFFE3E5EA)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}