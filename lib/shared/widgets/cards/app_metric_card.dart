// lib/shared/widgets/cards/app_metric_card.dart

import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';
import 'package:restaurant_pos_system/core/constants/app_shadows.dart';
import 'package:restaurant_pos_system/core/constants/app_spacing.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';

/// A standardized FAANG-grade hero metric card for WhizEats.
///
/// Features:
/// - Prominent numeric display formatted with currency or custom string.
/// - Status pill badge (e.g. Paid in Full, Partially Paid, Payment Pending).
/// - Optional contextual illustration / icon.
/// - Built-in skeleton loading state.
/// - Fully responsive & accessible typography.
class AppMetricCard extends StatelessWidget {
  final String label;
  final double amount;
  final String? customAmountText;
  final String? statusText;
  final Color? statusColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget? trailing;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const AppMetricCard({
    super.key,
    required this.label,
    required this.amount,
    this.customAmountText,
    this.statusText,
    this.statusColor,
    this.backgroundColor,
    this.borderColor,
    this.trailing,
    this.icon,
    this.isLoading = false,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 130,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLoader.rectangular(
                  height: 18,
                  width: 120,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                AppSpacing.vSm,
                SkeletonLoader.rectangular(
                  height: 34,
                  width: 170,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                AppSpacing.vSm,
                SkeletonLoader.rectangular(
                  height: 16,
                  width: 90,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ],
            ),
            const SkeletonLoader.circular(size: 64),
          ],
        ),
      );
    }

    final effectiveBg = backgroundColor ?? AppColors.surface;
    final effectiveBorder = borderColor ?? AppColors.border;
    final effectiveStatusColor = statusColor ?? AppColors.primary;
    final displayAmount = customAmountText ?? amount.toCurrency();

    Widget cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: effectiveBorder, width: 1.2),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top status row / label
                if (statusText != null && statusText!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 15, color: effectiveStatusColor),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        statusText!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: effectiveStatusColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),

                // Main Amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayAmount,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom badge pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveStatusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.round),
                    border: Border.all(
                      color: effectiveStatusColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: effectiveStatusColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 14),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
