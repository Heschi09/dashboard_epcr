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

/// Service for handling communication with the backend FHIR server.
/// 
/// This class provides static methods for CRUD operations on FHIR resources
/// including authentication handling using Keycloak.
class BackendService {
  /// Extracts the 'next' page URL from a FHIR [Bundle] for pagination.
  static String? getNextPageUrl(r5.Bundle bundle) {
    String? url;
    if (bundle.link != null &&
        bundle.link!.length > 1 &&
        bundle.link!.any((l) {
          return l.relation != null &&
              l.relation!.value == GeneralConstants.next;
        })) {
      url = bundle.link!
          .firstWhere((l) {
            return l.relation != null &&
                l.relation!.value == GeneralConstants.next;
          })
          .url
          .toString();
    } else {
      url = null;
    }
    return url;
  }

  /// Posts a [fhirResource] to the custom backend endpoint with authentication.
  /// 
  /// The [fhirResourceType] is used in the `X-Custom-Endpoint` header.
  static Future<int> postResourceWithAuth(
    var fhirResource,
    var fhirResourceType,
  ) async {
    final String? storedRefreshToken = await secureStorage.read(
      key: GeneralConstants.refreshToken,
    );
    if (storedRefreshToken == null) {
      return 401;
    }
    try {
      final TokenResponse response = await appAuth.token(
        TokenRequest(
          KeycloakConfig.clientId.value,
          KeycloakConfig.redirectUri.value,
          issuer: KeycloakConfig.issuer.value,
          refreshToken: storedRefreshToken,
          scopes: <String>[
            GeneralConstants.openid,
            GeneralConstants.offlineAccess,
          ],
          allowInsecureConnections:
              KeycloakConfig.scheme.value != GeneralConstants.https,
        ),
      );
      String accessToken = response.accessToken!;
      final http.Response responseFhir = await http.post(
        Uri.parse(BackendConfig.backendUrl.value),
        headers: <String, String>{
          GeneralConstants.authorization:
              '${GeneralConstants.bearer} $accessToken',
          GeneralConstants.contentTypeHeader:
              GeneralConstants.applicationJsonValue,
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

  /// Posts a [fhirResource] to the FHIR base URL without specific authentication headers.
  static Future<int> postResource(
    var fhirResource,
    var fhirResourceType,
  ) async {
    try {
      final http.Response responseFhir = await http.post(
        Uri.parse('${BackendConfig.fhirBaseUrl.value}/$fhirResourceType'),
        headers: <String, String>{
          GeneralConstants.contentTypeHeader:
              GeneralConstants.applicationJsonValue,
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

  /// Posts a FHIR [Bundle] to the base FHIR server.
  static Future<int> postBundle(r5.Bundle fhirBundle) async {
    try {
      final http.Response responseFhir = await http.post(
        Uri.parse(BackendConfig.fhirBaseUrl.value),
        headers: <String, String>{
          GeneralConstants.contentTypeHeader:
              GeneralConstants.applicationJsonValue,
        },
        body: jsonEncode(fhirBundle),
      );
      return responseFhir.statusCode;
    } on Exception catch (e, s) {
      debugPrint('error on post bundle: $e - stack: $s');
      return HttpStatus.internalServerError;
    }
  }

  /// Updates an existing FHIR resource by its [id].
  static Future<int> updateResource(
    var fhirResource,
    var fhirResourceType,
    String id,
  ) async {
    try {
      final String? token = await _getAccessToken();
      final Map<String, String> headers = {
        GeneralConstants.contentTypeHeader:
            GeneralConstants.applicationJsonValue,
        GeneralConstants.accept: GeneralConstants.applicationJsonValue,
        GeneralConstants.xCustomEndpoint: fhirResourceType,
      };
      if (token != null) {
        headers[GeneralConstants.authorization] =
            '${GeneralConstants.bearer} $token';
      }

      final http.Response responseFhir = await http.put(
        Uri.parse('${BackendConfig.fhirBaseUrl.value}/$fhirResourceType/$id'),
        headers: headers,
        body: jsonEncode(fhirResource),
      );
      debugPrint(
        'Update response: ${responseFhir.statusCode} ${responseFhir.body}',
      );
      return responseFhir.statusCode;
    } on Exception catch (e, s) {
      debugPrint('error on update resource: $e - stack: $s');
      return 500;
    }
  }

  /// Deletes a FHIR resource by its [id].
  static Future<int> deleteResource(var fhirResourceType, String id) async {
    try {
      final String? token = await _getAccessToken();
      final Map<String, String> headers = {
        GeneralConstants.contentTypeHeader:
            GeneralConstants.applicationJsonValue,
        GeneralConstants.xCustomEndpoint: fhirResourceType,
      };
      if (token != null) {
        headers[GeneralConstants.authorization] =
            '${GeneralConstants.bearer} $token';
      }

      final http.Response responseFhir = await http.delete(
        Uri.parse('${BackendConfig.fhirBaseUrl.value}/$fhirResourceType/$id'),
        headers: headers,
      );
      return responseFhir.statusCode;
    } on Exception catch (e, s) {
      debugPrint('error on delete resource: $e - stack: $s');
      return 500;
    }
  }

  static Future<String?> _getAccessToken() async {
    final String? storedRefreshToken = await secureStorage.read(
      key: GeneralConstants.refreshToken,
    );
    if (storedRefreshToken == null) {
      return null;
    }
    try {
      final TokenResponse? response = await appAuth.token(
        TokenRequest(
          KeycloakConfig.clientId.value,
          KeycloakConfig.redirectUri.value,
          issuer: KeycloakConfig.issuer.value,
          refreshToken: storedRefreshToken,
          scopes: <String>[
            GeneralConstants.openid,
            GeneralConstants.offlineAccess,
          ],
          allowInsecureConnections:
              KeycloakConfig.scheme.value != GeneralConstants.https,
        ),
      );
      return response?.accessToken;
    } on Exception catch (e, s) {
      debugPrint('error on refresh token: $e - stack: $s');
      return null;
    }
  }

  /// Fetches a FHIR [Bundle] from a given [url].
  static Future<r5.Bundle> getBundle(String url) async {
    try {
      final String? token = await _getAccessToken();
      final Map<String, String> headers = {
        GeneralConstants.contentTypeHeader:
            GeneralConstants.applicationJsonValue,
      };
      if (token != null) {
        headers[GeneralConstants.authorization] =
            '${GeneralConstants.bearer} $token';
      }

      final http.Response response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 401) {
        debugPrint('Unauthorized access to $url');
        return r5.Bundle(type: r5.FhirCode('searchset'), entry: []);
      }
      return r5.Bundle.fromJson(jsonDecode(response.body));
    } on Exception catch (e, s) {
      debugPrint('error on get bundle: $e - stack: $s');
      return r5.Bundle(type: r5.FhirCode('searchset'), entry: []);
    }
  }

  /// Fetches a single FHIR resource by its [resourceType] and [id].
  static Future<Map<String, dynamic>?> getResource(
    String resourceType,
    String id,
  ) async {
    try {
      final String? token = await _getAccessToken();
      final Map<String, String> headers = {
        GeneralConstants.contentTypeHeader:
            GeneralConstants.applicationJsonValue,
      };
      if (token != null) {
        headers[GeneralConstants.authorization] =
            '${GeneralConstants.bearer} $token';
      }

      final http.Response response = await http.get(
        Uri.parse('${BackendConfig.fhirBaseUrl.value}/$resourceType/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error fetching $resourceType/$id: ${response.statusCode}');
        return null;
      }
    } on Exception catch (e, s) {
      debugPrint('Error on get resource: $e - stack: $s');
      return null;
    }
  }

  /// Fetches all Practitioners from the FHIR server, handling pagination.
  static Future<List<r5.Practitioner>> getAllPractitioners() async {
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

  /// Fetches all active Locations marked as an ambulance from the FHIR server.
  static Future<List<r5.Location>> getAllLocations() async {
    String? url =
        '${BackendConfig.fhirBaseUrl.value}/${GeneralConstants.locationResourceName}';
    List<r5.Location> locations = [];
    while (url != null) {
      final bundle = await getBundle(url);
      if (bundle.entry != null) {
        debugPrint(
          'Fetched ${bundle.entry!.length} location entries from server.',
        );
        for (var entry in bundle.entry!) {
          if (entry.resource is r5.Location) {
            final location = entry.resource as r5.Location;

            // Debugging: Print candidate location details
            debugPrint(
              'Checking Location: ${location.id}, Status: ${location.status}, Type: ${location.type?.map((t) => t.coding?.map((c) => c.code).toList()).toList()}',
            );

            // Filter for active ambulance locations
            final isActive = location.status == r5.LocationStatus.active;

            final isAmbulance =
                location.type != null &&
                location.type!.any((t) {
                  return t.coding != null &&
                      t.coding!.any((c) {
                        // Check for code 'AMB' (Ambulance)
                        final isAmbCode =
                            c.code != null &&
                            c.code!.value == GeneralConstants.ambulanceCode;
                        return isAmbCode;
                      });
                });

            if (isActive && isAmbulance) {
              locations.add(location);
            } else {
              debugPrint(
                'Location ${location.id} skipped. Active: $isActive, IsAmbulance: $isAmbulance',
              );
            }
          }
        }
      }
      url = getNextPageUrl(bundle);
    }
    debugPrint('Returning ${locations.length} valid ambulance locations.');
    return locations;
  }

  /// Fetches all Device resources from the FHIR server.
  static Future<List<r5.Device>> getAllDevices() async {
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
