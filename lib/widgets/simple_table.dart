import 'package:flutter/material.dart';

class SimpleTable extends StatelessWidget {
  const SimpleTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{
      for (var i = 0; i < headers.length; i++) i: const FlexColumnWidth(),
    };

    return Table(
      columnWidths: columnWidths,
      border: const TableBorder(
        horizontalInside: BorderSide(color: Color(0xFFECEEF3)),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: headers
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
        ...rows.map(
              (row) => TableRow(
            children: row
                .map(
                  (cell) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  cell,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
                .toList(),
          ),
        ),
      ],
    );
  }
}
