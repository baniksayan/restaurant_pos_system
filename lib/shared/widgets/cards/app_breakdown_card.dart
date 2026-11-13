// lib/shared/widgets/cards/app_breakdown_card.dart

import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';
import 'package:restaurant_pos_system/core/constants/app_shadows.dart';
import 'package:restaurant_pos_system/core/constants/app_spacing.dart';

/// Single item line inside an [AppBreakdownCard].
class AppBreakdownItem {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final bool isHighlighted;
  final bool isDivider;

  const AppBreakdownItem({
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.isHighlighted = false,
    this.isDivider = false,
  });

  /// Factory for a clean horizontal divider item
  const AppBreakdownItem.divider()
      : label = '',
        value = '',
        icon = null,
        color = null,
        isHighlighted = false,
        isDivider = true;
}

/// Standardized card for displaying line-item breakdowns (subtotals, taxes,
/// amount paid, amount due, discounts).
class AppBreakdownCard extends StatelessWidget {
  final String? title;
  final Widget? headerTrailing;
  final List<AppBreakdownItem> items;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppBreakdownCard({
    super.key,
    this.title,
    this.headerTrailing,
    required this.items,
    this.footer,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor = AppColors.surface,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ?? Border.all(color: AppColors.border, width: 1.0);
    final effectiveShadow = boxShadow ?? AppShadows.card;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional Header
          if (title != null && title!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (headerTrailing != null) headerTrailing!,
              ],
            ),
            AppSpacing.vSm,
            const Divider(height: 1, color: AppColors.borderLight),
            AppSpacing.vSm,
          ],

          // Breakdown Items
          for (int i = 0; i < items.length; i++) ...[
            if (items[i].isDivider)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.borderLight),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    if (items[i].icon != null) ...[
                      Icon(
                        items[i].icon,
                        size: 16,
                        color: items[i].color ?? AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: items[i].isHighlighted ? 13.5 : 13,
                          fontWeight: items[i].isHighlighted
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: items[i].color ??
                              (items[i].isHighlighted
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                    Text(
                      items[i].value,
                      style: TextStyle(
                        fontSize: items[i].isHighlighted ? 16 : 14,
                        fontWeight: items[i].isHighlighted
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: items[i].color ?? AppColors.textPrimary,
                        letterSpacing: items[i].isHighlighted ? -0.3 : 0,
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Optional Footer
          if (footer != null) ...[
            const SizedBox(height: 10),
            footer!,
          ],
        ],
      ),
    );
  }
}
