import 'dart:convert';

import 'http_service.dart';
import '../models/user_model.dart';

class AuthService {
  final HttpService httpService;

  AuthService({required this.httpService});

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

    final userId = response['id'] as String?;
    final responseEmail = response['email'] as String? ?? normalizedEmail;
    final responseRole = (response['role'] as String?)?.toLowerCase() ??
        decodeRoleFromToken(token) ??
        'representative';
    final authIsNewUser = response['isNewUser'] as bool? ?? false;
    final authHouseholdId = response['householdId'] as String?;
    final authPlan = response['plan'] as String?;

    // Fetch user profile
    final profileResponse = await httpService.get('/api/v1/user/user/$userId');
    final profile = profileResponse;

    final onboardingPending =
        authIsNewUser || profile['isNewUser']?.toString().toLowerCase() == 'true';
    final resolvedHouseholdId = authHouseholdId ?? profile['houseHoldId'] ?? '';
    final resolvedPlan =
        (authPlan ?? profile['plan'] ?? 'FREE').toString().toUpperCase();

    return User(
      id: userId ?? '',
      email: responseEmail,
      role: responseRole,
      householdId: resolvedHouseholdId,
      isNewUser: onboardingPending,
      plan: resolvedPlan,
    );
  }
}
