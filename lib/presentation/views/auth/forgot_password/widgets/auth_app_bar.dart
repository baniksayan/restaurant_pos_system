import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;

  const AuthAppBar({
    super.key,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
