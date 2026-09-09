import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';
import 'package:restaurant_pos_system/core/constants/app_shadows.dart';
import 'package:restaurant_pos_system/core/constants/app_spacing.dart';

/// Canonical application card container with standardized padding, border radius, and shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardLg,
    this.margin,
    this.color = Colors.white,
    this.borderRadius = AppRadius.md,
    this.boxShadow,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = boxShadow ?? AppShadows.card;

    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: effectiveShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}
