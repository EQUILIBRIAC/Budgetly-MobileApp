import 'dart:convert';

import 'http_service.dart';
import '../models/user_model.dart';

class AuthService {
  final HttpService httpService;

  AuthService({required this.httpService});

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
      // Add padding if necessary
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

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final response = await httpService.post(
      '/api/v1/authentication/sign-in',
      body: {
        'email': normalizedEmail,
        'password': password,
      },
    );

    final token = response['token'] as String?;
    if (token == null) {
      throw Exception('Token not returned. Please try again.');
    }

    httpService.setToken(token);

    // Handle id as either String or int
    final userId = _toString(response['id']) ?? '';
    final responseEmail = _toString(response['email']) ?? normalizedEmail;
    final responseRole = (_toString(response['role']) ?? decodeRoleFromToken(token) ?? 'representative').toLowerCase();
    final authIsNewUser = response['isNewUser'] as bool? ?? false;
    final authHouseholdId = _toString(response['householdId']);
    final authPlan = _toString(response['plan']);

    // Fetch user profile
    final profileResponse = await httpService.get('/api/v1/user/user/$userId');
    final profile = profileResponse;

    final onboardingPending =
        authIsNewUser || profile['isNewUser']?.toString().toLowerCase() == 'true';
    final resolvedHouseholdId = authHouseholdId ?? _toString(profile['houseHoldId']) ?? '';
    final resolvedPlan =
        (_toString(authPlan) ?? _toString(profile['plan']) ?? 'FREE').toUpperCase();

    return User(
      id: userId,
      email: responseEmail,
      role: responseRole,
      householdId: resolvedHouseholdId,
      isNewUser: onboardingPending,
      plan: resolvedPlan,
    );
  }
}
