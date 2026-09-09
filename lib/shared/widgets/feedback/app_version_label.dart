import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/services/app_version_service.dart';

/// A compact, elegant app version label for display in drawers and footer menus.
class AppVersionLabel extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final TextStyle? style;

  const AppVersionLabel({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final version = AppVersionService.currentVersion;
    if (version.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          version,
          style:
              style ??
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.65),
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}
