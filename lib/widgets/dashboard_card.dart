import 'package:flutter/material.dart';

/// A card widget used to display sections on the dashboard.
/// 
/// Includes a [title] and a [child] widget, with optional [width] and [minHeight].
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.width,
    this.minHeight = 0,
  });

  final String title;
  final Widget child;
  final double? width;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E5EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: card,
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: card,
    );
  }
}