import 'dart:convert';

import 'package:budgetly_app/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AuthController bootstrap sin sesión queda unauthenticated', () async {
    SharedPreferences.setMockInitialValues({});

    final controller = AuthController();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.isAuthenticated, isFalse);
  });

  test('AuthController bootstrap con sesión válida queda authenticated', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake_token',
      'user_data': jsonEncode({
        'id': 'u-1',
        'email': 'rep@test.com',
        'role': 'representative',
        'householdId': 'h-1',
        'isNewUser': false,
        'plan': 'FREE',
      }),
    });

    final controller = AuthController();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.status, AuthStatus.authenticated);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.currentUser?.email, 'rep@test.com');
    expect(controller.role, 'representative');
  });
}
