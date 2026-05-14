/// Backend Azure desarrollo por defecto (HTTPS).
///
/// Sobrescribe con compilación cuando quieras otra URL, p. ej. API local emulador:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5070`
const String _azureDevApiBaseUrl =
    'https://budgetly-api-dev-dxcfedfvdxeebad5.chilecentral-01.azurewebsites.net';

/// URL API y locale.
abstract final class EnvConfig {
  /// Misma cadena por defecto que usa la app cuando no hay `dart-define`.
  static const String defaultBackendBaseUrl = _azureDevApiBaseUrl;

  static String get apiBaseUrl {
    const raw = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _azureDevApiBaseUrl,
    );
    final trimmed = raw.trim().isEmpty ? _azureDevApiBaseUrl : raw.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static bool get isHttps => apiBaseUrl.startsWith('https://');

  /// Locale para `intl` / formateos.
  static const String localeDefault = 'es_PE';

  /// Ruta típica de Swagger sobre el mismo host del API (referencia QA).
  static const String swaggerPath = '/swagger';
}
