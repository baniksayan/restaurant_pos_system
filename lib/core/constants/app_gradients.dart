import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  /// Primary brand gradient (Indigo to Deep Indigo)
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft primary brand gradient
  static const LinearGradient primaryLight = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// App background slate gradient
  static const LinearGradient background = LinearGradient(
    colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Horizontal background gradient
  static const LinearGradient backgroundHorizontal = LinearGradient(
    colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Emerald success gradient
  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Rose / error gradient
  static const LinearGradient error = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warm accent gradient
  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.accent, Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
