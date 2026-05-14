/// Errores de red / API normalizados (capa de datos).
class NetworkException implements Exception {
  final int? statusCode;
  final String message;
  final String responseBody;

  NetworkException(
    this.message, {
    this.statusCode,
    this.responseBody = '',
  });

  @override
  String toString() => message;
}
@Deprecated('Use NetworkException')
typedef ApiException = NetworkException;
