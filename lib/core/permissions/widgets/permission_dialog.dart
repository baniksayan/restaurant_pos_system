import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_radius.dart';
import 'package:restaurant_pos_system/core/constants/app_spacing.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final String secondaryButtonText;
  final IconData icon;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText = 'Not Now',
    required this.icon,
    required this.onPrimaryPressed,
    this.onSecondaryPressed,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryButtonText,
    String secondaryButtonText = 'Not Now',
    IconData icon = Icons.security_rounded,
    required VoidCallback onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => PermissionDialog(
            title: title,
            message: message,
            primaryButtonText: primaryButtonText,
            secondaryButtonText: secondaryButtonText,
            icon: icon,
            onPrimaryPressed: () {
              Navigator.of(ctx).pop(true);
              onPrimaryPressed();
            },
            onSecondaryPressed: () {
              Navigator.of(ctx).pop(false);
              onSecondaryPressed?.call();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: AppSpacing.dialog,
      child: Container(
        padding: AppSpacing.dialog,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    HapticHelper.triggerFeedback();
                    if (onSecondaryPressed != null) {
                      onSecondaryPressed!();
                    } else {
                      Navigator.of(context).pop(false);
                    }
                  },
                  child: Text(
                    secondaryButtonText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    HapticHelper.triggerFeedback();
                    onPrimaryPressed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
