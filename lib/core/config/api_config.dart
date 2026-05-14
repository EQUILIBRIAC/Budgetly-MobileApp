/// Timeouts y cabeceras. Las rutas son relativas a [EnvConfig.apiBaseUrl] (véase `HttpService`).
class ApiConfig {
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Rutas REST (sin host)
  static const String pathSignUp = '/api/v1/authentication/sign-up';
  static const String pathSignIn = '/api/v1/authentication/sign-in';
}

/// Solo metadatos; no URL del API aquí para evitar hardcode disperso.
class EnvironmentInfo {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static bool get isDevelopment => !isProduction;
  static const String appVersion = '1.0.0';
}
