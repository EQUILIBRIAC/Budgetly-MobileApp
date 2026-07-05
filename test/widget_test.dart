import 'package:budgetly_app/app/app.dart';
import 'package:budgetly_app/core/storage/jwt_token_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Muestra login cuando no hay sesión', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    JwtTokenLocator.replaceWith(MemoryJwtTokenStore());

    addTearDown(() {
      JwtTokenLocator.resetAfterTest();
    });

    await tester.pumpWidget(const ProviderScope(child: BudgetlyApp()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final loginTitle = find.text('¡Bienvenido de nuevo!');
    final loginTitleEn = find.text('Welcome back!');
    expect(loginTitle.evaluate().isNotEmpty || loginTitleEn.evaluate().isNotEmpty, isTrue);
  });
}
