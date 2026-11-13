// lib/shared/widgets/cards/app_status_card.dart

import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';

enum AppStatusTone {
  success,
  warning,
  error,
  info,
  neutral,
}

/// Standardized card for displaying contextual status messages, notices,
/// and order/billing states.
class AppStatusCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final AppStatusTone tone;
  final Widget? badge;
  final Widget? action;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const AppStatusCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.tone = AppStatusTone.info,
    this.badge,
    this.action,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margin,
  });

  Color get _primaryColor => switch (tone) {
        AppStatusTone.success => AppColors.success,
        AppStatusTone.warning => AppColors.warning,
        AppStatusTone.error => AppColors.error,
        AppStatusTone.info => AppColors.info,
        AppStatusTone.neutral => AppColors.textSecondary,
      };

  Color get _backgroundColor => switch (tone) {
        AppStatusTone.success => const Color(0xFFF0FDF4),
        AppStatusTone.warning => const Color(0xFFFFFBEB),
        AppStatusTone.error => const Color(0xFFFEF2F2),
        AppStatusTone.info => const Color(0xFFF0F9FF),
        AppStatusTone.neutral => const Color(0xFFF8FAFC),
      };

  Color get _borderColor => switch (tone) {
        AppStatusTone.success => const Color(0xFFBBF7D0),
        AppStatusTone.warning => const Color(0xFFFDE68A),
        AppStatusTone.error => const Color(0xFFFECACA),
        AppStatusTone.info => const Color(0xFFBAE6FD),
        AppStatusTone.neutral => AppColors.border,
      };

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: _primaryColor),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge!,
                    ],
                  ],
                ),
                if (description != null && description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: card,
        ),
      );
    }

    return card;
  }
}
