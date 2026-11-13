// lib/shared/widgets/cards/app_card.dart

import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';
import 'package:restaurant_pos_system/core/constants/app_shadows.dart';
import 'package:restaurant_pos_system/core/constants/app_spacing.dart';

/// Canonical application card container with standardized padding, border radius, and shadow.
/// Adheres strictly to WhizEats design tokens: [AppColors], [AppRadius], [AppSpacing], and [AppShadows].
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.margin,
    Color? color,
    Color? backgroundColor,
    this.borderRadius = AppRadius.lg,
    List<BoxShadow>? boxShadow,
    List<BoxShadow>? shadow,
    Border? border,
    Color? borderColor,
    double? borderWidth,
    this.gradient,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  })  : color = backgroundColor ?? color ?? AppColors.surface,
        border = border ??
            (borderColor != null
                ? Border.all(color: borderColor, width: borderWidth ?? 1.0)
                : null),
        boxShadow = boxShadow ?? shadow;

  /// Const constructor for compile-time constant instances with pre-formed borders/shadows
  const AppCard.raw({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.margin,
    this.color = AppColors.surface,
    this.borderRadius = AppRadius.lg,
    this.boxShadow,
    this.border,
    this.gradient,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  /// Factory constructor for an outlined card with canonical border
  factory AppCard.outlined({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = AppSpacing.card,
    EdgeInsetsGeometry? margin,
    Color color = AppColors.surface,
    Color? backgroundColor,
    double borderRadius = AppRadius.lg,
    Color borderColor = AppColors.border,
    double borderWidth = 1.0,
    double? width,
    double? height,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      color: backgroundColor ?? color,
      borderRadius: borderRadius,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: const [],
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor for a flat tinted card without shadows
  factory AppCard.flat({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = AppSpacing.card,
    EdgeInsetsGeometry? margin,
    Color color = AppColors.cardBackground,
    Color? backgroundColor,
    double borderRadius = AppRadius.lg,
    Border? border,
    Color? borderColor,
    double? borderWidth,
    double? width,
    double? height,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      color: backgroundColor ?? color,
      borderRadius: borderRadius,
      border: border ??
          Border.all(
            color: borderColor ?? AppColors.borderLight,
            width: borderWidth ?? 1.0,
          ),
      boxShadow: const [],
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory constructor for an elevated card with canonical shadow
  factory AppCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = AppSpacing.card,
    EdgeInsetsGeometry? margin,
    Color color = AppColors.surface,
    Color? backgroundColor,
    double borderRadius = AppRadius.lg,
    Border? border,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? boxShadow,
    List<BoxShadow>? shadow,
    double? width,
    double? height,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding,
      margin: margin,
      color: backgroundColor ?? color,
      borderRadius: borderRadius,
      border: border ??
          (borderColor != null
              ? Border.all(color: borderColor, width: borderWidth ?? 1.0)
              : Border.all(color: AppColors.border, width: borderWidth ?? 1.0)),
      boxShadow: boxShadow ?? shadow ?? AppShadows.card,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveShadow = boxShadow ?? AppShadows.card;

    final decoration = BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
      boxShadow: effectiveShadow,
    );

    if (onTap != null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: decoration,
        clipBehavior: clipBehavior,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
