import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import 'jwt_token_locator.dart';

/// Preferencias no sensibles (perfil/cache local). JWT: [JwtTokenLocator].
class StorageService {
  static const String tokenKey = StorageKeys.authToken;
  static const String userKey = StorageKeys.userData;

  /// Compatibilidad: lee JWT seguro (+ migración legacy).
  static Future<String?> getToken() async => JwtTokenLocator.instance.read();

  static Future<void> saveToken(String token) =>
      JwtTokenLocator.instance.write(token);

  static Future<void> clearToken() async =>
      JwtTokenLocator.instance.clear();

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }

  /// Limpia sesión (JWT + usuario en prefs).
  static Future<void> clearAll() async {
    await JwtTokenLocator.instance.clear();
    await clearUser();
  }
}
