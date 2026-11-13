// lib/shared/widgets/cards/app_tile_card.dart

import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';
import 'package:restaurant_pos_system/core/constants/app_shadows.dart';

/// Standardized interactive tile card for list items, orders, tables, and bills.
class AppTileCard extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? statusBadge;
  final List<Widget>? metadata;
  final Widget? expandedContent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Border? border;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const AppTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.statusBadge,
    this.metadata,
    this.expandedContent,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.backgroundColor = AppColors.surface,
    this.border,
    this.borderRadius = AppRadius.lg,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ?? Border.all(color: AppColors.border, width: 1.0);
    final effectiveShadow = boxShadow ?? AppShadows.card;

    Widget cardBody = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: title),
                        if (statusBadge != null) ...[
                          const SizedBox(width: 8),
                          statusBadge!,
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          if (metadata != null && metadata!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: metadata!,
            ),
          ],
          if (expandedContent != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 10),
            expandedContent!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: effectiveBorder,
          boxShadow: effectiveShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: cardBody,
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: cardBody,
    );
  }
}
