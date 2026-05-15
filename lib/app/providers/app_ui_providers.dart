import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tema Material (claro/oscuro) desde ajustes locales + API.
final appThemeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// null = seguir locale del sistema hasta que el usuario elija idioma en Ajustes.
final appLocaleProvider = StateProvider<Locale?>((ref) => null);
