import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/session_revoker.dart';
import '../config/api_config.dart';
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

  void _onUnauthorized(int statusCode) {
    if (statusCode != 401 && statusCode != 403) return;
    if (_token == null || _token!.isEmpty) return;
    unawaited(SessionRevoker.revokeAsync());
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _postRaw(endpoint, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _onUnauthorized(response.statusCode);
      throw _toNetworkException(response.statusCode, response.body);
    } on NetworkException {
      rethrow;
    } catch (_) {
      throw NetworkException('Error de red.');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _getRaw(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _onUnauthorized(response.statusCode);
      throw _toNetworkException(response.statusCode, response.body);
    } on NetworkException {
      rethrow;
    } catch (_) {
      throw NetworkException('Error de red.');
    }
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
