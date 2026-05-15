import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/http_service.dart';
import '../../../../core/utils/api_value_parsers.dart';
import '../../../../domain/entities/user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._http);

  final HttpService _http;
  String? _lastToken;

  String? get lastToken => _lastToken;

  String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toStringAsFixed(0);
    return value.toString();
  }

  String? decodeRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized + '=' * ((4 - normalized.length % 4) % 4);

      final decoded = utf8.decode(base64Url.decode(padded));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      final roleClaim = json['role'] ?? json['Role'] ?? json['roles']?[0];
      return roleClaim?.toString().toLowerCase();
    } catch (_) {
      return null;
    }
  }

  Future<({User user, String token})> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final http.Response res = await _http.postReturningResponse(
      ApiConfig.pathSignIn,
      body: {
        'email': normalizedEmail,
        'password': password,
      },
    );

    final code = res.statusCode;
    final bodyStr = res.body;

    if (code == 200 || code == 201) {
      Map<String, dynamic> response;
      try {
        response = jsonDecode(bodyStr) as Map<String, dynamic>;
      } catch (_) {
        throw ApiFailure.generic('Respuesta inválida del servidor al iniciar sesión.');
      }

      final token = response['token'] as String?;
      if (token == null || token.isEmpty) {
        throw ApiFailure.invalidCredentials(
          backendDetail: 'No se recibió token de autenticación.',
        );
      }

      _lastToken = token;
      _http.setToken(token);

      final userId = _toString(response['id']) ?? '';

      final profile = await _http.get('/api/v1/user/user/$userId');

      final fromProfileEmail = normalizeApiEmail(profile['email']);
      final fromSignInEmail = normalizeApiEmail(response['email']);
      final responseEmail = fromProfileEmail.isNotEmpty
          ? fromProfileEmail
          : (fromSignInEmail.isNotEmpty ? fromSignInEmail : normalizedEmail);

      final responseRole = (_toString(response['role']) ??
              decodeRoleFromToken(token) ??
              'representative')
          .toLowerCase();
      final authIsNewUser = response['isNewUser'] as bool? ?? false;
      final authHouseholdId = _toString(response['householdId']);
      final authPlan = _toString(response['plan']);

      final onboardingPending = authIsNewUser ||
          profile['isNewUser']?.toString().toLowerCase() == 'true';
      final resolvedHouseholdId =
          authHouseholdId ?? _toString(profile['houseHoldId']) ?? '';
      final resolvedPlan =
          (_toString(authPlan) ?? _toString(profile['plan']) ?? 'FREE')
              .toUpperCase();

      final user = User(
        id: userId,
        email: responseEmail,
        role: responseRole,
        householdId: resolvedHouseholdId,
        isNewUser: onboardingPending,
        plan: resolvedPlan,
      );

      return (user: user, token: token);
    }

    if (code == 401) {
      throw ApiFailure.networkFromStatus(statusCode: code, body: bodyStr);
    }

    // Backend puede responder 500 con body vacío en credenciales inválidas no manejadas.
    if (code >= 500 && code < 600 && bodyStr.trim().isEmpty) {
      throw ApiFailure.transientBackend();
    }

    throw ApiFailure.networkFromStatus(statusCode: code, body: bodyStr);
  }
}
