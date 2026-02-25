import 'package:flutter/material.dart';

/// A generic table widget for displaying structured data.
/// 
/// Supports [headers], [rows], and an optional [trailingBuilder] for action buttons.
class SimpleTable extends StatelessWidget {
  const SimpleTable({
    super.key,
    required this.headers,
    required this.rows,
    this.trailingBuilder,
    this.columnWidths,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final Widget Function(int rowIndex)? trailingBuilder;
  final Map<int, TableColumnWidth>? columnWidths;

  @override
  Widget build(BuildContext context) {
    final effectiveHeaders = trailingBuilder != null
        ? [...headers, '']
        : headers;
    final defaultColumnWidths = <int, TableColumnWidth>{
      for (var i = 0; i < effectiveHeaders.length; i++)
        i: const FlexColumnWidth(),
    };

    return Table(
      columnWidths: columnWidths ?? defaultColumnWidths,
      border: const TableBorder(
        horizontalInside: BorderSide(color: Color(0xFFECEEF3)),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: effectiveHeaders
              .map(
                (header) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    header,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF8B909A),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.asMap().entries.map(
          (entry) => TableRow(
            children: [
              ...entry.value.map(
                (cell) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(cell, style: const TextStyle(fontSize: 13)),
                ),
              ),
              if (trailingBuilder != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: trailingBuilder!(entry.key),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
