import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import 'jwt_token_store.dart';

/// JWT en almacenamiento seguro. Migra `auth_token` legacy desde prefs.
class FlutterSecureJwtStore implements JwtTokenStore {
  FlutterSecureJwtStore({
    FlutterSecureStorage? secure,
  }) : _secure = secure ?? _defaultStorage;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FlutterSecureStorage _secure;
  static const _secureKey = 'budgetly_auth_jwt_v1';

  @override
  Future<String?> read() async {
    final fromSecure = await _secure.read(key: _secureKey);
    if (fromSecure != null && fromSecure.isNotEmpty) {
      return fromSecure;
    }
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(StorageKeys.authToken);
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.remove(StorageKeys.authToken);
      await write(legacy);
      return legacy;
    }
    return null;
  }

  @override
  Future<void> write(String token) async {
    await _secure.write(key: _secureKey, value: token);
  }

  @override
  Future<void> clear() async {
    await _secure.delete(key: _secureKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.authToken);
  }
}
