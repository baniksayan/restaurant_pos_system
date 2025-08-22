import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/animations/fade_in_animation.dart';

class BackToLoginWidget extends StatelessWidget {
  final VoidCallback onBackToLogin;

  const BackToLoginWidget({
    super.key,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Remember your password? ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: onBackToLogin,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Log In',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
