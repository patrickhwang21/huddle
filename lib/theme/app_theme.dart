import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLight = Color(0xFFC7D2FE);
  static const primaryMid = Color(0xFF818CF8);
  static const surface = Color(0xFFF7F7FA);
  static const cardBorder = Color(0xFFF0F0F3);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFFBEB);
  static const danger = Color(0xFFE11D48);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
    );
  }
}
