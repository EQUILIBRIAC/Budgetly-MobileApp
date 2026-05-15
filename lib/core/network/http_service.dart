import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/session_revoker.dart';
import '../config/api_config.dart';
import '../config/env_config.dart';
import 'network_exception.dart';

class HttpService {
  HttpService({
    required this.baseUrl,
  });

  final String baseUrl;
  String? _token;

  void setToken(String token) => _token = token;

  void clearToken() => _token = null;

  Future<http.Response> _postRaw(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      ...ApiConfig.defaultHeaders,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    return _withRetry(
      () => http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout),
    );
  }

  Future<http.Response> _getRaw(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      ...ApiConfig.defaultHeaders,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    return _withRetry(
      () =>
          http.get(url, headers: headers).timeout(ApiConfig.connectionTimeout),
    );
  }

  Future<http.Response> _putRaw(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      ...ApiConfig.defaultHeaders,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    return _withRetry(
      () => http
          .put(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectionTimeout),
    );
  }

  Future<http.Response> _deleteRaw(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      ...ApiConfig.defaultHeaders,
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    return _withRetry(
      () => http.delete(url, headers: headers).timeout(ApiConfig.connectionTimeout),
    );
  }

  void _debugLog(String verb, String endpoint, http.Response response) {
    if (!kDebugMode) return;
    final raw = response.body;
    final snippet =
        raw.length > 220 ? '${raw.substring(0, 220)}…' : raw;
    debugPrint(
      '[HTTP] $verb $endpoint → ${response.statusCode} (${raw.length} B) '
      '${snippet.replaceAll(RegExp(r'\s+'), ' ')}',
    );
  }

  void _onUnauthorized(int statusCode) {
    if (statusCode != 401 && statusCode != 403) return;
    if (_token == null || _token!.isEmpty) return;
    unawaited(SessionRevoker.revokeAsync());
  }

  /// Interpreta JSON de respuesta: mapa raíz o lista (`{ "data": [...] }`).
  Map<String, dynamic> _decodeJsonMap(String rawBody, {required String verb}) {
    final body = rawBody.trim();
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is List<dynamic>) {
        return <String, dynamic>{'data': decoded};
      }
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      throw NetworkException(
        'La respuesta no es JSON válido ($verb). ¿La URL ${EnvConfig.apiBaseUrl} '
        'apunta al API correcto?',
        responseBody:
            rawBody.length > 400 ? '${rawBody.substring(0, 400)}…' : rawBody,
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _postRaw(endpoint, body: body);
      _debugLog('POST', endpoint, response);
      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        return _decodeJsonMap(response.body, verb: 'POST $endpoint');
      }
      _onUnauthorized(code);
      throw _toNetworkException(code, response.body);
    } on NetworkException {
      rethrow;
    } on http.ClientException catch (e) {
      throw _connectionException(e.message);
    } on TimeoutException {
      throw NetworkException(
        'Tiempo de espera al contactar ${EnvConfig.apiBaseUrl}',
      );
    } catch (_) {
      throw NetworkException('Fallo inesperado en POST $endpoint');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _putRaw(endpoint, body: body);
      _debugLog('PUT', endpoint, response);
      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        return _decodeJsonMap(response.body, verb: 'PUT $endpoint');
      }
      _onUnauthorized(code);
      throw _toNetworkException(code, response.body);
    } on NetworkException {
      rethrow;
    } on http.ClientException catch (e) {
      throw _connectionException(e.message);
    } on TimeoutException {
      throw NetworkException(
        'Tiempo de espera al contactar ${EnvConfig.apiBaseUrl}',
      );
    } catch (_) {
      throw NetworkException('Fallo inesperado en PUT $endpoint');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _getRaw(endpoint);
      _debugLog('GET', endpoint, response);
      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        return _decodeJsonMap(response.body, verb: 'GET $endpoint');
      }
      _onUnauthorized(code);
      throw _toNetworkException(code, response.body);
    } on NetworkException {
      rethrow;
    } on http.ClientException catch (e) {
      throw _connectionException(e.message);
    } on TimeoutException {
      throw NetworkException(
        'Tiempo de espera al contactar ${EnvConfig.apiBaseUrl}',
      );
    } catch (_) {
      throw NetworkException('Fallo inesperado en GET $endpoint');
    }
  }

  /// DELETE: admite 204 sin cuerpo JSON.
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _deleteRaw(endpoint);
      _debugLog('DELETE', endpoint, response);
      final code = response.statusCode;
      if (code >= 200 && code < 300) {
        final raw = response.body.trim();
        if (raw.isEmpty) return <String, dynamic>{};
        return _decodeJsonMap(response.body, verb: 'DELETE $endpoint');
      }
      _onUnauthorized(code);
      throw _toNetworkException(code, response.body);
    } on NetworkException {
      rethrow;
    } on http.ClientException catch (e) {
      throw _connectionException(e.message);
    } on TimeoutException {
      throw NetworkException(
        'Tiempo de espera al contactar ${EnvConfig.apiBaseUrl}',
      );
    } catch (_) {
      throw NetworkException('Fallo inesperado en DELETE $endpoint');
    }
  }

  NetworkException _connectionException([String? detail]) {
    final base =
        'Sin conexión o el servidor no está disponible. Revisa Wi‑Fi/VPN y que '
        'el API responda. URL base: ${EnvConfig.apiBaseUrl}';
    if (detail != null && detail.trim().isNotEmpty) {
      return NetworkException('$base\n Detalle: $detail');
    }
    return NetworkException(base);
  }

  /// POST sin lanzar por estado HTTP (p. ej. sign-in donde 500 puede ir sin body).
  Future<http.Response> postReturningResponse(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _postRaw(endpoint, body: body);
    _onUnauthorized(response.statusCode);
    return response;
  }

  NetworkException _toNetworkException(int statusCode, String body) {
    String serverMessage = 'Error de red.';
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        serverMessage =
            decoded['message']?.toString() ??
            decoded['title']?.toString() ??
            serverMessage;
      }
    } catch (_) {}

    switch (statusCode) {
      case 401:
        return NetworkException(
          serverMessage.isNotEmpty && serverMessage != 'Error de red.'
              ? serverMessage
              : 'Sesión inválida.',
          statusCode: statusCode,
          responseBody: body,
        );
      case 403:
        return NetworkException(
          serverMessage.isNotEmpty ? serverMessage : 'Sin permiso.',
          statusCode: statusCode,
          responseBody: body,
        );
      case 404:
        return NetworkException(
          serverMessage.isNotEmpty ? serverMessage : 'Recurso no encontrado.',
          statusCode: statusCode,
          responseBody: body,
        );
      case 422:
        return NetworkException(
          serverMessage.isNotEmpty ? serverMessage : 'Datos inválidos.',
          statusCode: statusCode,
          responseBody: body,
        );
      default:
        return NetworkException(
          serverMessage,
          statusCode: statusCode,
          responseBody: body,
        );
    }
  }

  Future<http.Response> _withRetry(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on TimeoutException {
      return request();
    }
  }
}
