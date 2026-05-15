import 'dart:convert';

import 'network_exception.dart';

/// Fallo de aplicación/red con mensaje listo para mostrar en UI (es‑PE por defecto vía EnvConfig).
abstract class ApiFailure implements Exception {
  const ApiFailure();

  /// Texto UX en español.
  String get messageEs;

  @override
  String toString() => messageEs;

  factory ApiFailure.invalidCredentials({String? backendDetail}) =>
      ApiFailureInvalidCredentials(detail: backendDetail);

  factory ApiFailure.transientBackend() => const ApiFailureTransientBackend();

  factory ApiFailure.generic(String backendMessage) =>
      ApiFailureGeneric(backendMessage);

  factory ApiFailure.householdNotFound() =>
      const ApiFailureHouseholdNotFound();

  factory ApiFailure.enumOrValidation(String backendMessage) =>
      ApiFailureBackendMessage(backendMessage);

  factory ApiFailure.network() => const ApiFailureNetwork();

  /// Convierte excepción de capa inferior a fallo UX.
  static ApiFailure wrap(Object error) {
    if (error is ApiFailure) return error;
    if (error is NetworkException) {
      return ApiFailure.networkFromStatus(
        statusCode: error.statusCode ?? 0,
        body: error.responseBody,
        fallbackMessage: error.message,
      );
    }
    return ApiFailure.generic(error.toString().replaceFirst('Exception: ', ''));
  }

  factory ApiFailure.networkFromStatus({
    required int statusCode,
    required String body,
    String? fallbackMessage,
  }) {
    String serverMsg = fallbackMessage ?? 'Error del servidor.';
    if (body.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          serverMsg =
              decoded['message']?.toString() ??
              decoded['title']?.toString() ??
              serverMsg;
        }
      } catch (_) {}
    }

    if (statusCode == 401) {
      return ApiFailure.invalidCredentials(backendDetail: serverMsg);
    }
    if (statusCode == 403) {
      return ApiFailureForbidden(serverMsg);
    }
    if (statusCode == 404) {
      if (_looksLikeHouseholdNotFound(serverMsg)) {
        return const ApiFailureHouseholdNotFound();
      }
      return ApiFailure.generic(serverMsg);
    }
    if (statusCode == 422) {
      return ApiFailure.enumOrValidation(
        serverMsg.isNotEmpty ? serverMsg : 'Datos inválidos.',
      );
    }
    if (statusCode >= 500 && statusCode < 600) {
      if (_isEmptyOrMeaninglessBody(body)) {
        return const ApiFailureTransientBackend();
      }
      return ApiFailure.generic(
        serverMsg.isNotEmpty ? serverMsg : 'Error temporal en el servidor.',
      );
    }
    return ApiFailure.generic(
      serverMsg.isNotEmpty ? serverMsg : 'Error de red ($statusCode).',
    );
  }

  static bool _isEmptyOrMeaninglessBody(String body) =>
      body.trim().isEmpty;

  static bool _looksLikeHouseholdNotFound(String m) =>
      m.toLowerCase().contains('household') &&
      (m.toLowerCase().contains('not found'));
}

class ApiFailureInvalidCredentials implements ApiFailure {
  const ApiFailureInvalidCredentials({this.detail});

  final String? detail;

  @override
  String get messageEs {
    if (detail != null && detail!.isNotEmpty) {
      return 'Credenciales inválidas o error temporal.\nDetalle: $detail';
    }
    return 'Credenciales inválidas o error temporal del servidor.\nIntenta de nuevo en un momento.';
  }
}

class ApiFailureTransientBackend implements ApiFailure {
  const ApiFailureTransientBackend();

  @override
  String get messageEs =>
      'No pudimos iniciar sesión (respuesta vacía del servidor). '
      'Comprueba email y contraseña o intenta más tarde.';
}

class ApiFailureGeneric implements ApiFailure {
  ApiFailureGeneric(this.message);

  final String message;

  @override
  String get messageEs => message.isNotEmpty ? message : 'Ocurrió un error.';
}

class ApiFailureHouseholdNotFound implements ApiFailure {
  const ApiFailureHouseholdNotFound();

  @override
  String get messageEs =>
      'No se encontró el hogar. Verifica el ID con tu representante.';
}

class ApiFailureBackendMessage implements ApiFailure {
  const ApiFailureBackendMessage(this.backend);

  final String backend;

  @override
  String get messageEs => backend.isNotEmpty ? backend : 'Datos no válidos.';
}

class ApiFailureNetwork implements ApiFailure {
  const ApiFailureNetwork();

  @override
  String get messageEs => 'Error de red o tiempo de espera agotado.';
}

class ApiFailureForbidden implements ApiFailure {
  const ApiFailureForbidden(this.backend);

  final String backend;

  @override
  String get messageEs =>
      backend.isNotEmpty ? backend : 'No tienes permisos para esta acción.';
}
