import 'package:budgetly_app/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forgot password renderiza título y botón', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(find.text('Enviar enlace'), findsOneWidget);
  });

  testWidgets('forgot password valida correo inválido', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    await tester.enterText(find.byType(TextField), 'correo_invalido');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
  });
}
