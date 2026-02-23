import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static const PdfColor rwandaRed = PdfColor.fromInt(0xFFCE1126); 
  static const PdfColor darkGrey = PdfColor.fromInt(0xFF333333);

  static Future<void> exportPdf(Map<String, dynamic> pcrData) async {
    final pdf = pw.Document();
    
    // Load Logo
    final logoData = await rootBundle.load('lib/assets/rc_logo.png'); // Ensure path matches pubspec
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());

    final patient = pcrData['patient'] ?? {};
    final encounter = pcrData['encounter'] ?? {};
    final pcr = pcrData['pcr'] ?? {};
    final meds = pcrData['medications'] as List? ?? [];
    final procs = pcrData['procedures'] as List? ?? [];
    final equip = pcrData['equipmentUsed'] as List? ?? [];
    final handover = pcrData['handover'] ?? {};

    // Page 1: Patient, Encounter, Crew
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader('Patient Care Report', logo),
          _buildSectionHeader('Patient Information'),
          _buildInfoTable({
            'Name': patient['name'],
            'Birth Date': patient['birthDate'],
            'Gender': patient['gender'],
            'Age': patient['age'], // If available
          }),
          pw.SizedBox(height: 20),
          _buildSectionHeader('Encounter / Transport'),
          _buildInfoTable({
            'Date': encounter['startTime']?.split(' ')?.first, // Naive parse
            'Time': '${encounter['startTime']?.split(' ')?.last} - ${encounter['endTime']?.split(' ')?.last}',
            'Vehicle': encounter['vehicle'],
            'License Plate': encounter['licensePlate'],
          }),
          pw.SizedBox(height: 10),
          _buildSectionHeader('Crew'),
          _buildInfoTable({
             'Medic': encounter['medic'],
             'Physician': encounter['physician'],
             'Driver': encounter['driver'],
          }),
          pw.SizedBox(height: 20),
          _buildSectionHeader('Clinical Assessment'),
           // A-E Sections
          _buildSubHeader('A - Airway'),
          _buildKeyValueTable(pcr['a'] ?? {}),
          pw.SizedBox(height: 10),
          _buildSubHeader('B - Breathing'),
          _buildKeyValueTable(pcr['b'] ?? {}),
          pw.SizedBox(height: 10),
          _buildSubHeader('C - Circulation'),
          _buildKeyValueTable(pcr['c'] ?? {}),
           pw.SizedBox(height: 10),
          _buildSubHeader('D - Disability'),
          _buildKeyValueTable(pcr['d'] ?? {}),
           pw.SizedBox(height: 10),
          _buildSubHeader('E - Exposure'),
          _buildKeyValueTable(pcr['e'] ?? {}),
        ],
      ),
    );

    // Page 2: Interventions, Equipment, Handover
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
           _buildHeader('Patient Care Report (Cont.)', logo),
           _buildSectionHeader('Interventions'),
           _buildSubHeader('Medications'),
           meds.isNotEmpty 
             ? _buildListTable(meds, ['Name', 'Dose', 'Route', 'Time'], ['name', 'dose', 'route', 'time'])
             : pw.Text('No medications administered.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
           pw.SizedBox(height: 10),
           _buildSubHeader('Procedures'),
           procs.isNotEmpty
             ? _buildListTable(procs, ['Procedure', 'Time'], ['name', 'time'])
             : pw.Text('No procedures performed.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
           pw.SizedBox(height: 20),

           _buildSectionHeader('Logistics'),
           _buildSubHeader('Equipment Used'),
           equip.isNotEmpty
             ? _buildListTable(equip, ['Item', 'Quantity'], ['name', 'quantity'])
             : pw.Text('No equipment used.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
           
           pw.SizedBox(height: 20),
           if (handover.isNotEmpty) ...[
             _buildSectionHeader('Handover'),
             _buildInfoTable({
               'Destination': handover['destination'],
               'Handed Over To': handover['handedOverTo'],
               'Condition': handover['condition'],
             }),
             if (handover['notes'] != null) ...[
               pw.SizedBox(height: 5),
               pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
               pw.Text(handover['notes'], style: const pw.TextStyle(fontSize: 10)),
             ]
           ],
           
           pw.Spacer(),
           _buildFooter(encounter['id'] ?? 'Unknown ID'),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'PCR_${pcrData['id'] ?? 'Report'}.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, pw.MemoryImage logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: rwandaRed)),
          pw.Image(logo, width: 40, height: 40),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
    );
  }

  static pw.Widget _buildSubHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 5, bottom: 2),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
    );
  }

  static pw.Widget _buildInfoTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(e.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildKeyValueTable(Map<String, dynamic> data) {
    if (data.isEmpty) return pw.Text('No data recorded', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey));
    
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headers: ['Investigation', 'Result'],
      data: data.entries.where((e) => e.key != 'furtherEvaluation' && e.key != 'Main').map((e) => [
        _formatKey(e.key),
        e.value.toString()
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: rwandaRed),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  static pw.Widget _buildListTable(List<dynamic> items, List<String> headers, List<String> fields) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headers: headers,
      data: items.map((item) {
        return fields.map((field) => item[field]?.toString() ?? '').toList();
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: rwandaRed),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  static pw.Widget _buildFooter(String id) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text('Report ID: $id | Generated by Dashboard', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
    );
  }

  static String _formatKey(String key) {
     return key.replaceAllMapped(RegExp(r'(?<!^)(?=[A-Z])'), (m) => ' ${m.group(0)}').replaceFirst(key[0], key[0].toUpperCase());
  }
}
