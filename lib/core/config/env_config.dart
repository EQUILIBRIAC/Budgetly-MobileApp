/// URL API y locale. Preferir compilación:
/// `flutter run --dart-define=API_BASE_URL=https://budgetly-api-dev-dxcfedfvdxeebad5.chilecentral-01.azurewebsites.net`
abstract final class EnvConfig {
  static String get apiBaseUrl {
    const raw = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
    }
    return 'http://10.0.2.2:5070';
  }

  static bool get isHttps => apiBaseUrl.startsWith('https://');

  /// Locale para `intl` / formateos.
  static const String localeDefault = 'es_PE';

  /// Ruta típica de Swagger sobre el mismo host del API (referencia QA).
  static const String swaggerPath = '/swagger';
}
