import 'package:budgetly_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_test_helpers.dart';

void main() {
  testWidgets('Recuperación: título y vuelta a login sin formulario API', (
    tester,
  ) async {
    await tester.pumpWidget(wrapWithL10n(const ForgotPasswordScreen()));
    await tester.pumpAndSettle();

    final hasEsTitle =
        find.text('Recuperar contraseña').evaluate().isNotEmpty;
    final hasEnTitle = find.text('Reset password').evaluate().isNotEmpty;
    expect(hasEsTitle || hasEnTitle, isTrue);

    final hasBackEs =
        find.text('Volver al inicio de sesión').evaluate().isNotEmpty;
    final hasBackEn = find.text('Back to sign in').evaluate().isNotEmpty;
    expect(hasBackEs || hasBackEn, isTrue);

    expect(find.byType(TextField), findsNothing);
  });
}
