import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../services/pcr_service.dart';
import '../services/pdf_export_service.dart';

class PCRView extends StatefulWidget {
  const PCRView({super.key});

  @override
  State<PCRView> createState() => _PCRViewState();
}

class _PCRViewState extends State<PCRView> {
  bool _isLoading = false;
  Map<String, dynamic>? _pcrData;

  final TextEditingController _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({String? specificId}) async {
    setState(() => _isLoading = true);
    try {
      if (specificId != null && specificId.isNotEmpty) {
        // Load specific ID
        try {
          final specificReport = await PcrService.instance.getFullReportData(specificId);
          if (specificReport.isNotEmpty && specificReport['id'] != null) {
            setState(() => _pcrData = specificReport);
          } else {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ID $specificId not found found.')));
             }
             // Optional: clear data or keep previous? Let's keep previous or set null
             // setState(() => _pcrData = null); 
          }
        } catch (e) {
          debugPrint('ID $specificId error: $e');
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading ID $specificId: $e')));
           }
        }
      } else {
        // Load Latest
        final reports = await PcrService.instance.getAll();
        if (reports.isNotEmpty) {
          final fullData = await PcrService.instance.getFullReportData(reports.first['id']);
          setState(() => _pcrData = fullData);
        } else {
          setState(() => _pcrData = null);
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final encounter = _pcrData;
    final pcr = encounter != null ? (encounter['pcr'] as Map<String, dynamic>? ?? {}) : {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search / Control Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Enter PCR ID',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _loadData(specificId: _idController.text),
                    child: const Text('Load ID'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _loadData(),
                    child: const Text('Load Latest'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pcrData != null ? () => PdfExportService.exportPdf(_pcrData!) : null,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCE1126), // Rwanda Red
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (encounter == null) ...[
             const Center(
               child: Padding(
                 padding: EdgeInsets.all(32.0),
                 child: Text('No PCR data loaded. Enter an ID to view record.'),
               ),
             )
          ] else ...[
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('ePCR Record: ${encounter['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            _buildPatientCard(encounter['patient'] as Map<String, dynamic>? ?? {}),
            const SizedBox(height: 24),
            _buildEncounterCard(encounter['encounter'] as Map<String, dynamic>? ?? {}),
            const SizedBox(height: 24),
            _buildPCRSectionCard('A - Airway', pcr['a'] as Map<String, dynamic>? ?? {}),
            const SizedBox(height: 24),
            _buildPCRSectionCard('B - Breathing', pcr['b'] as Map<String, dynamic>? ?? {}),
            const SizedBox(height: 24),
            _buildPCRSectionCard('C - Circulation', pcr['c'] as Map<String, dynamic>? ?? {}),
            const SizedBox(height: 24),
            _buildPCRSectionCard('D - Disability', pcr['d'] as Map<String, dynamic>? ?? {}),
            const SizedBox(height: 24),
            _buildPCRSectionCard('E - Exposure', pcr['e'] as Map<String, dynamic>? ?? {}),
            const SizedBox(height: 24),
            _buildMedicationsCard(encounter['medications'] as List<dynamic>? ?? []),
            const SizedBox(height: 24),
            _buildProceduresCard(encounter['procedures'] as List<dynamic>? ?? []),
            const SizedBox(height: 24),
            _buildEquipmentCard(encounter['equipmentUsed'] as List<dynamic>? ?? []),
            if (encounter['handover'] != null) ...[
              const SizedBox(height: 24),
              _buildHandoverCard(encounter['handover'] as Map<String, dynamic>),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return DashboardCard(
      title: 'Patient Information',
      width: double.infinity,
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildInfoItem('Name', patient['name'] ?? 'N/A'),
          _buildInfoItem('Age', patient['age'] ?? 'N/A'),
          _buildInfoItem('Sex', patient['sex'] ?? 'N/A'),
          _buildInfoItem('Birth Date', patient['birthDate'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildEncounterCard(Map<String, dynamic> encounter) {
    return DashboardCard(
      title: 'Encounter / Transport',
      width: double.infinity,
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildInfoItem('Status', encounter['status'] ?? 'N/A'),
          _buildInfoItem('Start Time', _formatDateTime(encounter['startTime'])),
          if (encounter['endTime'] != null)
            _buildInfoItem('End Time', _formatDateTime(encounter['endTime'])),
          _buildInfoItem('Vehicle', encounter['vehicle'] ?? 'N/A'),
          _buildInfoItem('License Plate', encounter['licensePlate'] ?? 'N/A'),
          _buildInfoItem('Driver', encounter['driver'] ?? 'N/A'),
          _buildInfoItem('Medic', encounter['medic'] ?? 'N/A'),
          _buildInfoItem('Physician', encounter['physician'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildPCRSectionCard(String title, Map<String, dynamic> data) {
    return DashboardCard(
      title: title,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: data.entries
                .where((entry) => entry.key != 'furtherEvaluation')
                .map((entry) => _buildInfoItem(
                      _formatKey(entry.key),
                      entry.value.toString(),
                    ))
                .toList(),
          ),
          if (data['furtherEvaluation'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Further Evaluation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF8B909A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['furtherEvaluation'],
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationsCard(List<dynamic> medications) {
    if (medications.isEmpty) {
      return DashboardCard(
        title: 'Medications',
        width: double.infinity,
        child: const Text(
          'No medications administered',
          style: TextStyle(color: Color(0xFF8B909A)),
        ),
      );
    }

    return DashboardCard(
      title: 'Medications',
      width: double.infinity,
      child: Column(
        children: medications
            .map((med) => _buildListItem(
                  '${med['name']} - ${med['dose']} (${med['route']})',
                  med['time'] != null ? 'Time: ${med['time']}' : null,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProceduresCard(List<dynamic> procedures) {
    if (procedures.isEmpty) {
      return DashboardCard(
        title: 'Procedures',
        width: double.infinity,
        child: const Text(
          'No procedures performed',
          style: TextStyle(color: Color(0xFF8B909A)),
        ),
      );
    }

    return DashboardCard(
      title: 'Procedures',
      width: double.infinity,
      child: Column(
        children: procedures
            .map((proc) => _buildListItem(
                  proc['name'],
                  proc['time'] != null
                      ? 'Time: ${proc['time']}${proc['location'] != null ? ' | Location: ${proc['location']}' : ''}'
                      : proc['location'] != null
                          ? 'Location: ${proc['location']}'
                          : null,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEquipmentCard(List<dynamic> equipment) {
    if (equipment.isEmpty) {
      return DashboardCard(
        title: 'Equipment Used',
        width: double.infinity,
        child: const Text(
          'No equipment used',
          style: TextStyle(color: Color(0xFF8B909A)),
        ),
      );
    }

    return DashboardCard(
      title: 'Equipment Used',
      width: double.infinity,
      child: Column(
        children: equipment
            .map((eq) => _buildListItem(
                  eq['name'],
                  'Quantity: ${eq['quantity']}',
                ))
            .toList(),
      ),
    );
  }

  Widget _buildHandoverCard(Map<String, dynamic> handover) {
    return DashboardCard(
      title: 'Handover Information',
      width: double.infinity,
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildInfoItem('Destination', handover['destination'] ?? 'N/A'),
          _buildInfoItem('Handed Over To', handover['handedOverTo'] ?? 'N/A'),
          _buildInfoItem('Condition', handover['condition'] ?? 'N/A'),
          if (handover['notes'] != null) ...[
            const SizedBox(width: double.infinity),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF8B909A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    handover['notes'],
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8B909A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildListItem(String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFBF486B),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B909A),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime;
    }
  }

  String _formatKey(String key) {
    return key
        .split(RegExp(r'(?=[A-Z])'))
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
