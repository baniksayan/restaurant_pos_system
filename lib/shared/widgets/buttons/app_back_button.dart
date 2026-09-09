import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color color;
  final IconData icon;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color = AppColors.textPrimary,
    this.icon = Icons.arrow_back_ios_new,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: () async {
        await HapticHelper.triggerFeedback();
        if (!context.mounted) return;
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
    );
  }
}
