enum BackendConfig {
  backendUrl,
  patient,
  fhirBaseUrl,
}

extension BackendConfigValues on BackendConfig {
  String get value {
    const String backendUrl = 'http://10.25.6.2:8011/private';
    // For web/browser: Use a proxy to avoid CORS issues
    // For mobile/desktop: Use direct URL
    // Option 1: Direct URL (works on mobile/desktop, CORS issues on web)
    const String fhirBaseUrlDirect = 'http://10.25.6.2:8084/fhir';
    // Option 2: Proxy URL (if you have a proxy server set up)
    // const String fhirBaseUrlProxy = 'http://localhost:8080/proxy/fhir';
    const String fhirBaseUrl = fhirBaseUrlDirect; // Change this if using proxy
    const String patient = 'Patient';

    switch (this) {
      case BackendConfig.backendUrl:
        return backendUrl;
      case BackendConfig.patient:
        return patient;
      case BackendConfig.fhirBaseUrl:
        return fhirBaseUrl;
    }
  }
}
