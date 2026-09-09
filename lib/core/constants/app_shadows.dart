import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  /// Canonical ultra-soft card shadow matching AppColors.cardShadow
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Small subtle elevation (menus, chips, small cards)
  static final List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Medium component elevation (buttons, floating pills, cards)
  static final List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Large prominent elevation (bottom sheets, drawers)
  static final List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  /// Primary button elevation with brand glow
  static final List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Modal dialog elevation
  static final List<BoxShadow> dialog = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
