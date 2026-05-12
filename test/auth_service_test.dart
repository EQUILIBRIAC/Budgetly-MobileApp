import 'package:budgetly_app/services/auth_service.dart';
import 'package:budgetly_app/services/http_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService.decodeRoleFromToken', () {
    test('retorna null para token inválido', () {
      final service = AuthService(httpService: HttpService(baseUrl: 'http://localhost'));
      expect(service.decodeRoleFromToken('invalid'), isNull);
    });

    test('parsea role del payload', () {
      final service = AuthService(httpService: HttpService(baseUrl: 'http://localhost'));
      const payload = 'eyJyb2xlIjoibWVtYmVyIn0'; // {"role":"member"}
      const token = 'aaa.$payload.bbb';
      expect(service.decodeRoleFromToken(token), 'member');
    });
  });
}
