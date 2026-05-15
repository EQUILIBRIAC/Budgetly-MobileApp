import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Persistencia ligera para tema / idioma (alineado con ajustes de cuenta en API).
class UiPrefsStorage {
  static Future<ThemeMode> loadThemeMode() async {
    final p = await SharedPreferences.getInstance();
    final dark = p.getBool(StorageKeys.uiDarkMode);
    if (dark == null) return ThemeMode.light;
    return dark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> saveThemeDark(bool dark) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(StorageKeys.uiDarkMode, dark);
  }

  static Future<Locale?> loadLocale() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(StorageKeys.uiLocale);
    if (code == null) return null;
    if (code == 'es' || code == 'en') return Locale(code);
    return null;
  }

  static Future<void> saveLocaleCode(String languageCode) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(StorageKeys.uiLocale, languageCode);
  }
}
