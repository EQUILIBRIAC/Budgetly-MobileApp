import 'package:budgetly_app/app/l10n/app_strings.dart';
import 'package:budgetly_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Recuperación: título y vuelta a login sin formulario API', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    expect(find.text(AppStrings.forgotPasswordTitle), findsOneWidget);
    expect(find.text(AppStrings.forgotPasswordBackToLogin), findsOneWidget);
    expect(find.textContaining('Swagger'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
