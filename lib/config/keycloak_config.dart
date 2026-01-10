enum KeycloakConfig {
  domain,
  scheme,
  clientId,
  redirectUri,
  logoutRedirectUri,
  issuer,
  userInfoEndpoint,
}

extension KeycloakConfigValues on KeycloakConfig {
  String get value {
    const String keycloakDomain = 'aai-ehealth.fh-joanneum.at:8089/'; // '10.25.6.2:8089';
    const String keycloakScheme = 'https';
    const String keycloakClientId = 'epcr';
    const String keycloakRedirectUri = 'at.fhjoanneum.epcr://login-callback';
    const String keycloakLogoutRedirectUri = 'at.fhjoanneum.epcr://logout-callback';
    const String keycloakIssuer = '$keycloakScheme://$keycloakDomain/realms/epcr';
    const String keycloakUserInfoEndpoint =
        '$keycloakScheme://$keycloakDomain/realms/epcr/protocol/openid-connect/userinfo';

    switch (this) {
      case KeycloakConfig.domain:
        return keycloakDomain;
      case KeycloakConfig.scheme:
        return keycloakScheme;
      case KeycloakConfig.clientId:
        return keycloakClientId;
      case KeycloakConfig.redirectUri:
        return keycloakRedirectUri;
      case KeycloakConfig.logoutRedirectUri:
        return keycloakLogoutRedirectUri;
      case KeycloakConfig.issuer:
        return keycloakIssuer;
      case KeycloakConfig.userInfoEndpoint:
        return keycloakUserInfoEndpoint;
    }
  }
}
