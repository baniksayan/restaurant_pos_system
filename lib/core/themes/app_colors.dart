import 'package:flutter/material.dart';

// OLD CODE
class AppColors {
  // Primary brand colors - Restaurant theme
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFF4285F4);
  static const Color accent = Color(0xFFFF6B35);
  
  // Background gradient colors
  static const Color backgroundStart = Color(0xFF667eea);
  static const Color backgroundEnd = Color(0xFF764ba2);
  
  // Card and surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFAFAFA);
  static const Color cardShadow = Color(0x1A000000);
  
  // Status colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFF6F00);
  static const Color info = Color(0xFF2196F3);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1D1D1D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  // Table status colors
  static const Color tableAvailable = Color(0xFF10B981);
  static const Color tableOccupied = Color(0xFFEF4444);
  static const Color tableReserved = Color(0xFFF59E0B);
  static const Color tableCleaning = Color(0xFF8B5CF6);
}


//NEW CODE
// Enhanced App Colors for Better UX
// class AppColors {
//   static const Color primary = Color(0xFF2196F3);
//   static const Color primaryDark = Color(0xFF1976D2);
//   static const Color primaryLight = Color(0xFFBBDEFB);
  
//   static const Color secondary = Color(0xFFFF9800);
//   static const Color secondaryDark = Color(0xFFF57C00);
//   static const Color secondaryLight = Color(0xFFFFE0B2);
  
//   static const Color success = Color(0xFF4CAF50);
//   static const Color warning = Color(0xFFFF9800);
//   static const Color error = Color(0xFFF44336);
//   static const Color info = Color(0xFF2196F3);
  
//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color background = Color(0xFFF5F5F5);
//   static const Color cardBackground = Color(0xFFFFFFFF);
  
//   static const Color textPrimary = Color(0xFF212121);
//   static const Color textSecondary = Color(0xFF757575);
//   static const Color textHint = Color(0xFFBDBDBD);
  
//   static const Color border = Color(0xFFE0E0E0);
//   static const Color divider = Color(0xFFBDBDBD);
  
//   // Gradient colors
//   static const Gradient primaryGradient = LinearGradient(
//     colors: [primary, primaryDark],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   static const Gradient successGradient = LinearGradient(
//     colors: [success, Color(0xFF2E7D32)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
// }



// import 'package:flutter/material.dart';

// /// Enhanced App Colors for Better UX and Theming Support
// class AppColors {
//   // Primary brand colors
//   static const Color primary = Color(0xFF2196F3);
//   static const Color primaryDark = Color(0xFF1976D2);
//   static const Color primaryLight = Color(0xFFBBDEFB);
  
//   // Secondary colors
//   static const Color secondary = Color(0xFFFF9800);
//   static const Color secondaryDark = Color(0xFFF57C00);
//   static const Color secondaryLight = Color(0xFFFFE0B2);
  
//   // Status colors
//   static const Color success = Color(0xFF4CAF50);
//   static const Color successDark = Color(0xFF2E7D32);
//   static const Color successLight = Color(0xFFC8E6C9);
  
//   static const Color warning = Color(0xFFFF9800);
//   static const Color warningDark = Color(0xFFF57C00);
//   static const Color warningLight = Color(0xFFFFE0B2);
  
//   static const Color error = Color(0xFFF44336);
//   static const Color errorDark = Color(0xFFD32F2F);
//   static const Color errorLight = Color(0xFFFFCDD2);
  
//   static const Color info = Color(0xFF2196F3);
//   static const Color infoDark = Color(0xFF1976D2);
//   static const Color infoLight = Color(0xFFBBDEFB);
  
//   // Surface and background colors
//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color surfaceDark = Color(0xFFF5F5F5);
//   static const Color background = Color(0xFFF8F9FA);
//   static const Color backgroundDark = Color(0xFFE3F2FD);
//   static const Color cardBackground = Color(0xFFFFFFFF);
  
//   // Text colors
//   static const Color textPrimary = Color(0xFF212121);
//   static const Color textSecondary = Color(0xFF757575);
//   static const Color textHint = Color(0xFFBDBDBD);
//   static const Color textDisabled = Color(0xFF9E9E9E);
//   static const Color textOnPrimary = Color(0xFFFFFFFF);
//   static const Color textOnDark = Color(0xFFFFFFFF);
  
//   // Border and divider colors
//   static const Color border = Color(0xFFE0E0E0);
//   static const Color borderLight = Color(0xFFEEEEEE);
//   static const Color divider = Color(0xFFBDBDBD);
//   static const Color outline = Color(0xFF9E9E9E);
  
//   // Shadow colors
//   static const Color shadow = Color(0x1A000000);
//   static const Color shadowLight = Color(0x0D000000);
//   static const Color shadowDark = Color(0x26000000);
  
//   // Gradient definitions
//   static const Gradient primaryGradient = LinearGradient(
//     colors: [primary, primaryDark],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   static const Gradient secondaryGradient = LinearGradient(
//     colors: [secondary, secondaryDark],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   static const Gradient successGradient = LinearGradient(
//     colors: [success, successDark],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   static const Gradient warningGradient = LinearGradient(
//     colors: [warning, warningDark],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   static const Gradient errorGradient = LinearGradient(
//     colors: [error, errorDark],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   // Background gradients
//   static const Gradient backgroundGradient = LinearGradient(
//     colors: [background, backgroundDark],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter,
//   );
  
//   // Special purpose colors
//   static const Color overlay = Color(0x80000000);
//   static const Color overlayLight = Color(0x40000000);
//   static const Color highlight = Color(0x1A2196F3);
//   static const Color focus = Color(0x332196F3);
  
//   // Dark theme colors (optional - for future dark mode support)
//   static const Color darkSurface = Color(0xFF121212);
//   static const Color darkBackground = Color(0xFF000000);
//   static const Color darkTextPrimary = Color(0xFFFFFFFF);
//   static const Color darkTextSecondary = Color(0xFFBDBDBD);
  
//   // Utility methods
//   static Color withOpacity(Color color, double opacity) {
//     return color.withOpacity(opacity);
//   }
  
//   static Color lighten(Color color, [double amount = 0.1]) {
//     final hsl = HSLColor.fromColor(color);
//     final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
//     return hslLight.toColor();
//   }
  
//   static Color darken(Color color, [double amount = 0.1]) {
//     final hsl = HSLColor.fromColor(color);
//     final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
//     return hslDark.toColor();
//   }
// }

// /// Extension for easy color manipulation
// extension ColorExtension on Color {
//   Color lighten([double amount = 0.1]) => AppColors.lighten(this, amount);
//   Color darken([double amount = 0.1]) => AppColors.darken(this, amount);
// }