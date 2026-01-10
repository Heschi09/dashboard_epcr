import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fhir/r5.dart' as r5;
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import '../config/keycloak_config.dart';
import '../config/general_constants.dart';

const FlutterAppAuth appAuth = FlutterAppAuth();
const FlutterSecureStorage secureStorage = FlutterSecureStorage();

class BackendService {
  // Entwicklungsmodus: FakeMode für lokale Dummy-Daten
  // Setze auf false, um echte Server-Calls zu machen
  static const bool isFakeMode = true;

  static String? getNextPageUrl(r5.Bundle bundle) {
    String? url;
    if (bundle.link != null &&
        bundle.link!.length > 1 &&
        bundle.link!.any((l) {
          return l.relation != null && l.relation!.value == GeneralConstants.next;
        })) {
      url = bundle.link!
          .firstWhere((l) {
        return l.relation != null && l.relation!.value == GeneralConstants.next;
      }).url.toString();
    } else {
      url = null;
    }
    return url;
  }

  static Future<int> postResourceWithAuth(
      var fhirResource, var fhirResourceType) async {
    if (isFakeMode) return 200;
    final String? storedRefreshToken =
        await secureStorage.read(key: GeneralConstants.refreshToken);
    if (storedRefreshToken == null) {
      return 401;
    }
    try {
      final TokenResponse response = await appAuth.token(TokenRequest(
        KeycloakConfig.clientId.value,
        KeycloakConfig.redirectUri.value,
        issuer: KeycloakConfig.issuer.value,
        refreshToken: storedRefreshToken,
        scopes: <String>[
          GeneralConstants.openid,
          GeneralConstants.offlineAccess
        ],
        allowInsecureConnections:
            KeycloakConfig.scheme.value != GeneralConstants.https,
      ));
      String accessToken = response.accessToken!;
      final http.Response responseFhir = await http.post(
        Uri.parse(BackendConfig.backendUrl.value),
        headers: <String, String>{
          GeneralConstants.authorization:
              '${GeneralConstants.bearer} $accessToken',
          GeneralConstants.contentTypeHeader: GeneralConstants.applicationJsonValue,
          GeneralConstants.xCustomEndpoint: fhirResourceType,
        },
        body: jsonEncode(fhirResource),
      );
      return responseFhir.statusCode;
    } on Exception catch (e, s) {
      debugPrint('error on refresh token: $e - stack: $s');
      return 500;
    }
  }

  static Future<int> postResource(var fhirResource, var fhirResourceType) async {
    if (isFakeMode) return 200;
    try {
      final http.Response responseFhir = await http.post(
        Uri.parse('${BackendConfig.fhirBaseUrl.value}/$fhirResourceType'),
        headers: <String, String>{
          GeneralConstants.contentTypeHeader: GeneralConstants.applicationJsonValue,
          GeneralConstants.accept: GeneralConstants.applicationJsonValue,
          GeneralConstants.xCustomEndpoint: fhirResourceType,
        },
        body: jsonEncode(fhirResource),
      );
      return responseFhir.statusCode;
    } on Exception catch (e, s) {
      debugPrint('error on post resource: $e - stack: $s');
      return 500;
    }
  }

  static Future<int> postBundle(r5.Bundle fhirBundle) async {
    if (isFakeMode) return 200;
    try {
      final http.Response responseFhir = await http.post(
        Uri.parse(BackendConfig.fhirBaseUrl.value),
        headers: <String, String>{
          GeneralConstants.contentTypeHeader: GeneralConstants.applicationJsonValue,
        },
        body: jsonEncode(fhirBundle),
      );
      return responseFhir.statusCode;
    } on Exception catch (e, s) {
      debugPrint('error on post bundle: $e - stack: $s');
      return HttpStatus.internalServerError;
    }
  }

  static Future<r5.Bundle> getBundle(String url) async {
    if (isFakeMode) {
      return r5.Bundle(type: r5.FhirCode('searchset'), entry: []);
    }
    try {
      final http.Response response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          GeneralConstants.contentTypeHeader: GeneralConstants.applicationJsonValue,
        },
      );
      return r5.Bundle.fromJson(jsonDecode(response.body));
    } on Exception catch (e, s) {
      debugPrint('error on get bundle: $e - stack: $s');
      return r5.Bundle(type: r5.FhirCode('searchset'), entry: []);
    }
  }

  static Future<List<r5.Practitioner>> getAllPractitioners() async {
    if (isFakeMode) {
      return [];
    }
    String? url =
        '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.practitionerResourceName}';
    List<r5.Practitioner> practitioners = [];
    while (url != null) {
      final bundle = await getBundle(url);
      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.Practitioner) {
            practitioners.add(entry.resource as r5.Practitioner);
          }
        }
      }
      url = getNextPageUrl(bundle);
    }
    return practitioners;
  }

  static Future<List<r5.Location>> getAllLocations() async {
    if (isFakeMode) {
      return [];
    }
    String? url =
        '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.locationResourceName}';
    List<r5.Location> locations = [];
    while (url != null) {
      final bundle = await getBundle(url);
      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.Location) {
            final location = entry.resource as r5.Location;
            // Filter for active ambulance locations
            if (location.status != null &&
                location.status.toString() == GeneralConstants.active &&
                location.type != null &&
                location.type!.any((t) {
                  return t.coding != null &&
                      t.coding!.any((c) {
                        return (c.code != null &&
                                c.code!.value == GeneralConstants.ambulanceCode &&
                                c.system != null &&
                                c.system!.value.toString() ==
                                    GeneralConstants.codeSystemRoleCode);
                      });
                })) {
              locations.add(location);
            }
          }
        }
      }
      url = getNextPageUrl(bundle);
    }
    return locations;
  }

  static Future<List<r5.Device>> getAllDevices() async {
    if (isFakeMode) {
      return [];
    }
    String? url =
        '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.deviceResourceName}';
    List<r5.Device> devices = [];
    while (url != null) {
      final bundle = await getBundle(url);
      if (bundle.entry != null) {
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.Device) {
            devices.add(entry.resource as r5.Device);
          }
        }
      }
      url = getNextPageUrl(bundle);
    }
    return devices;
  }
}
