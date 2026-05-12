import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class HttpService {
  final String baseUrl;
  String? _token;

  HttpService({required this.baseUrl});

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await _withRetry(
        () => http
            .post(
              url,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(ApiConfig.connectionTimeout),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw _toApiException(response.statusCode, response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      final response = await _withRetry(
        () => http.get(url, headers: headers).timeout(ApiConfig.connectionTimeout),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw _toApiException(response.statusCode, response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  ApiException _toApiException(int statusCode, String body) {
    String serverMessage = 'Error de red.';
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        serverMessage = decoded['message']?.toString() ?? serverMessage;
      }
    } catch (_) {}

    switch (statusCode) {
      case 401:
        return ApiException('Sesión inválida. Inicia sesión nuevamente.', statusCode: statusCode);
      case 403:
        return ApiException('No tienes permisos para esta acción.', statusCode: statusCode);
      case 404:
        return ApiException('Recurso no encontrado.', statusCode: statusCode);
      case 422:
        return ApiException(serverMessage.isNotEmpty ? serverMessage : 'Datos inválidos.', statusCode: statusCode);
      default:
        return ApiException(serverMessage, statusCode: statusCode);
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
