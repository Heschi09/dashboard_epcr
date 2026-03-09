import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final endpoints = [
    'http://10.25.6.2:8084/fhir/Practitioner',
    'http://10.25.6.2:8084/fhir/Location',
    'http://10.25.6.2:8084/fhir/Device',
    'http://10.25.6.2:8084/fhir/Encounter?_sort=-date',
    'http://10.25.6.2:8084/fhir/DiagnosticReport?_sort=-date',
    'http://10.25.6.2:8084/fhir/Task?status=requested,accepted,in-progress',
  ];

  for (var url in endpoints) {
    try {
      final res = await http.get(Uri.parse(url));
      print('--- GET $url ---');
      print('Status: ${res.statusCode}');
      print(
        'Body: ${res.body.length > 500 ? res.body.substring(0, 500) + '...' : res.body}',
      );
    } catch (e) {
      print('Error on $url: $e');
    }
  }
}
