import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/animations/fade_in_animation.dart';

class ForgotPasswordHeader extends StatelessWidget {
  final bool emailSent;
  
  const ForgotPasswordHeader({
    super.key,
    required this.emailSent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title
        FadeInAnimation(
          delay: const Duration(milliseconds: 400),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Subtitle
        FadeInAnimation(
          delay: const Duration(milliseconds: 500),
          child: Text(
            emailSent
                ? 'Check your email for reset instructions'
                : 'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
