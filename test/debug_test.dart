import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_epcr/services/pcr_service.dart';
import 'package:dashboard_epcr/services/transport_service.dart';
import 'package:dashboard_epcr/services/order_service.dart';
import 'package:dashboard_epcr/services/vehicle_service.dart';
import 'package:dashboard_epcr/services/crew_service.dart';
import 'package:dashboard_epcr/services/equipment_service.dart';

void main() {
  test('Find the exception in loadInitialData logic', () async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final crew = await CrewService.instance.getAll();
      final vehicles = await VehicleService.instance.getAll();
      final equipment = await EquipmentService.instance.getAll();
      final transports = await TransportService.instance.getAll();
      final openOrders = await OrderService.instance.getOpenOrders();
      final closedOrders = await OrderService.instance.getClosedOrders();
      final recentReports = await PcrService.instance.getRecentReports(5);

      final List<Map<String, String>> newOrders = [];
      if (recentReports.isNotEmpty) {
        for (var report in recentReports) {
          String formattedDate = report['date'] ?? '';
          try {
            if (formattedDate.isNotEmpty) {
              final dt = DateTime.parse(formattedDate).toLocal();
              String twoDigits(int n) => n.toString().padLeft(2, '0');
              formattedDate =
                  '${twoDigits(dt.day)}.${twoDigits(dt.month)}.${dt.year} ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}';
            }
          } catch (_) {}

          newOrders.add({
            'id': report['id'] ?? '',
            'patient': report['patient'] ?? 'Unknown',
            'date': formattedDate,
            'vehicle': report['vehicle'] ?? 'N/A',
            'crew': report['driver'] ?? 'N/A',
          });
        }
      }

      print(
        'Data fetched: Crew: ${crew.length}, Vehicles: ${vehicles.length}, Transports: ${transports.length}, OpenOrders: ${openOrders.length}, ClosedOrders: ${closedOrders.length}, RecentReports: ${recentReports.length}',
      );

      // calculateChartData
      final validTransports = transports.where((t) {
        final hasStart = t['startIso'] != null && t['startIso']!.isNotEmpty;
        final dur = double.tryParse(t['duration'] ?? '') ?? 0;
        return hasStart && dur > 0;
      }).toList();

      validTransports.sort((a, b) {
        final dA = DateTime.tryParse(a['startIso']!) ?? DateTime(0);
        final dB = DateTime.tryParse(b['startIso']!) ?? DateTime(0);
        return dA.compareTo(dB);
      });

      final historyCount = 20;
      final startIndex = validTransports.length > historyCount
          ? validTransports.length - historyCount
          : 0;
      final viewData = validTransports.sublist(startIndex).map((t) {
        return {
          'id': t['id'] ?? 'Unknown',
          'patient': t['patient'] ?? 'Unknown',
          'date': t['date'] ?? '',
          'duration': double.tryParse(t['duration'] ?? '') ?? 0.0,
          'status': t['status'] ?? '',
        };
      }).toList();
      print('Chart data calculated: ${viewData.length}');
    } catch (e, st) {
      print('EXCEPTION CAUGHT: $e');
      print(st);
      fail('Exception thrown');
    }
  });
}
