import 'package:flutter/material.dart';
import 'package:budgetly_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_test_helpers.dart';

void main() {
  testWidgets('login valida campos obligatorios', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: wrapWithL10n(const LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter your email and password.').evaluate().isNotEmpty ||
          find.text('Completa tu correo y contraseña.').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
