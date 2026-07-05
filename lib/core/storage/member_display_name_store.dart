import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Nombres visibles cuando el API devuelve `name` / `personName` vacíos.
abstract final class MemberDisplayNameStore {
  static Future<Map<String, String>> loadByUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.memberDisplayNamesByUserId);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveForUserId(String userId, String name) async {
    final trimmed = name.trim();
    if (userId.trim().isEmpty || trimmed.isEmpty) return;
    final map = await loadByUserId();
    map[userId.trim()] = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.memberDisplayNamesByUserId,
      jsonEncode(map),
    );
  }

  static Future<Map<String, String>> loadByEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.memberDisplayNamesByEmail);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString().toLowerCase(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveForEmail(String email, String name) async {
    final emailKey = email.trim().toLowerCase();
    final trimmed = name.trim();
    if (emailKey.isEmpty || trimmed.isEmpty) return;
    final map = await loadByEmail();
    map[emailKey] = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.memberDisplayNamesByEmail,
      jsonEncode(map),
    );
  }
}
