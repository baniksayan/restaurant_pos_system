import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),

      // Use system fonts
      fontFamily: 'Roboto', // This will use the system Roboto font
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto', // System font
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto', // System font
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textHint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Text Theme with system fonts
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Roboto'),
        displayMedium: TextStyle(fontFamily: 'Roboto'),
        displaySmall: TextStyle(fontFamily: 'Roboto'),
        headlineLarge: TextStyle(fontFamily: 'Roboto'),
        headlineMedium: TextStyle(fontFamily: 'Roboto'),
        headlineSmall: TextStyle(fontFamily: 'Roboto'),
        titleLarge: TextStyle(fontFamily: 'Roboto'),
        titleMedium: TextStyle(fontFamily: 'Roboto'),
        titleSmall: TextStyle(fontFamily: 'Roboto'),
        bodyLarge: TextStyle(fontFamily: 'Roboto'),
        bodyMedium: TextStyle(fontFamily: 'Roboto'),
        bodySmall: TextStyle(fontFamily: 'Roboto'),
        labelLarge: TextStyle(fontFamily: 'Roboto'),
        labelMedium: TextStyle(fontFamily: 'Roboto'),
        labelSmall: TextStyle(fontFamily: 'Roboto'),
      ),
    );
  }
}
