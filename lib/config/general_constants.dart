class GeneralConstants {
  // FHIR Resource Names
  static const String patientResourceName = 'Patient';
  static const String practitionerResourceName = 'Practitioner';
  static const String locationResourceName = 'Location';
  static const String deviceResourceName = 'Device';
  static const String medicationResourceName = 'Medication';
  static const String encounterResourceName = 'Encounter';
  static const String observationResourceName = 'Observation';
  static const String diagnosticReportName = 'DiagnosticReport';

  // FHIR URIs
  static const String patientUri = 'Patient/';
  static const String practitionerUri = 'Practitioner/';
  static const String locationURI = 'Location/';
  static const String deviceUri = 'Device/';
  static const String observationUri = 'Observation/';
  static const String diagnosticReportUri = 'DiagnosticReport/';
  static const String encounterURI = 'Encounter/';

  // HTTP Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String accept = 'Accept';
  static const String applicationJsonValue = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
  static const String xCustomEndpoint = 'X-Custom-Endpoint';

  // Auth
  static const String refreshToken = 'refresh_token';
  static const String openid = 'openid';
  static const String offlineAccess = 'offline_access';

  // Status
  static const String active = 'active';
  static const String next = 'next';
  static const String https = 'https';

  // Role Codes
  static const String driverCode = 'driver';
  static const String medicCode = 'medic';
  static const String physicianCode = 'physician';
  static const String ambulanceCode = 'AMB';
  static const String codeSystemRoleCode = 'http://terminology.hl7.org/CodeSystem/v3-RoleCode';

  // SNOMED
  static const String snomedConceptUri = 'http://snomed.info/sct';

  // Bundle
  static const String transactionStatement = 'transaction';
  static const String postRequest = 'POST';
}
