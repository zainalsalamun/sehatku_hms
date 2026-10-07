import 'package:flutter/material.dart';
import 'app_colors.dart';

export 'app_colors.dart';

abstract final class AppTheme {
  static const primary = AppColors.primary;
  static const navy = AppColors.navy;
  static const background = AppColors.background;
  static const success = AppColors.success;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
        bodyLarge: TextStyle(color: AppColors.textSecondary),
        bodyMedium: TextStyle(color: AppColors.textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4EBEF)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
