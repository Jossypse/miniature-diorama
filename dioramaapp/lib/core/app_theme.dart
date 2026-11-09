// lib/core/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.pageDark,
      primaryColor: AppColors.green,
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.lineBorder,
      fontFamily: 'System', // Flutter defaults to system fonts, matching your UI
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.green,
        secondary: AppColors.gold,
        surface: AppColors.bgDark,
        error: AppColors.red,
        onPrimary: AppColors.cream,
        onSecondary: AppColors.bgDark,
        onSurface: AppColors.textDark,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textDark, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textDark, fontSize: 15),
        labelSmall: TextStyle(color: AppColors.gold, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.bold),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark, 
          fontSize: 17, 
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.cream,
          backgroundColor: AppColors.red, // Default to red buttons as per prototype
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: AppColors.red.withValues(alpha: 0.35),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}