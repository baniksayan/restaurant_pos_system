import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: AppColors.backgroundEnd,
      fontFamily: 'Roboto',

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 20),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
          letterSpacing: -0.5,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200 border
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textHint,
          disabledBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      // Text Theme with system fonts and hierarchy
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontWeight: FontWeight.bold, letterSpacing: -1.0),
        displayMedium: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineSmall: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        titleSmall: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontFamily: 'Roboto', color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontFamily: 'Roboto', color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
