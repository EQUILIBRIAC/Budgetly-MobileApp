import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lightGray,
      fontFamily: 'DM Sans',
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.borderGray, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.borderGray, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.lightGray,
        hintStyle: const TextStyle(color: AppColors.placeholder),
        labelStyle: const TextStyle(color: AppColors.navy),
      ),
    );
  }
}
