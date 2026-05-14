import 'dart:convert';

import 'package:budgetly_app/core/storage/jwt_token_locator.dart';
import 'package:budgetly_app/core/storage/storage_service.dart';
import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    JwtTokenLocator.replaceWith(MemoryJwtTokenStore());
  });

  tearDown(() async {
    await JwtTokenLocator.instance.clear();
    JwtTokenLocator.resetAfterTest();
  });

  test('AuthController bootstrap sin sesión queda unauthenticated', () async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    final auth = container.read(authControllerProvider);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.isAuthenticated, isFalse);
    container.dispose();
  });

  test('AuthController bootstrap con sesión válida queda authenticated', () async {
    await StorageService.saveToken('fake_token');

    SharedPreferences.setMockInitialValues({
      'user_data': jsonEncode({
        'id': 'u-1',
        'email': 'rep@test.com',
        'role': 'representative',
        'householdId': 'h-1',
        'isNewUser': false,
        'plan': 'FREE',
      }),
    });

    final container = ProviderContainer();
    final auth = container.read(authControllerProvider);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.email, 'rep@test.com');
    expect(auth.role, 'representative');
    container.dispose();
  });
}
