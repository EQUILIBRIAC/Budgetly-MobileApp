import 'package:budgetly_app/core/network/http_service.dart';
import 'package:budgetly_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRemoteDataSource.decodeRoleFromToken', () {
    test('retorna null para token inválido', () {
      final ds = AuthRemoteDataSource(HttpService(baseUrl: 'http://localhost'));
      expect(ds.decodeRoleFromToken('invalid'), isNull);
    });

    test('parsea role del payload', () {
      final ds = AuthRemoteDataSource(HttpService(baseUrl: 'http://localhost'));
      const payload = 'eyJyb2xlIjoibWVtYmVyIn0'; // {"role":"member"}
      const token = 'aaa.$payload.bbb';
      expect(ds.decodeRoleFromToken(token), 'member');
    });
  });
}
