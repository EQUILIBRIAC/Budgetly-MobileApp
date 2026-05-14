import 'flutter_secure_jwt_store.dart';
import 'jwt_token_store.dart';

/// En memoria (tests). No usar en release público sin override consciente.
final class MemoryJwtTokenStore implements JwtTokenStore {
  String? _v;

  @override
  Future<void> clear() async => _v = null;

  @override
  Future<String?> read() async => _v;

  @override
  Future<void> write(String token) async => _v = token;
}

/// Punto de acceso singleton al almacén JWT (app + overrides en tests).
abstract final class JwtTokenLocator {
  static JwtTokenStore _store = FlutterSecureJwtStore();

  static JwtTokenStore get instance => _store;

  static void replaceWith(JwtTokenStore store) {
    _store = store;
  }

  static void useSecureDefaultStore() {
    _store = FlutterSecureJwtStore();
  }

  static void resetAfterTest() => useSecureDefaultStore();
}
