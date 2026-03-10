import 'package:flutter/material.dart';
import '../widgets/simple_table.dart';

class DetailDialog extends StatelessWidget {
  const DetailDialog({
    super.key,
    required this.title,
    required this.headers,
    required this.rows,
    this.onRowTap,
    this.trailingBuilder,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final void Function(int rowIndex)? onRowTap;
  final Widget Function(int rowIndex)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: SimpleTable(
                  headers: headers,
                  rows: rows,
                  onRowTap: onRowTap,
                  trailingBuilder: trailingBuilder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
