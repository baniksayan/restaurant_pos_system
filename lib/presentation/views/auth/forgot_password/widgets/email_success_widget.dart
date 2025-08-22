import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/animations/fade_in_animation.dart';
import '../../../../../shared/widgets/buttons/animated_button.dart';

class EmailSuccessWidget extends StatelessWidget {
  final String email;
  final VoidCallback onBackToLogin;
  final VoidCallback onResendEmail;

  const EmailSuccessWidget({
    super.key,
    required this.email,
    required this.onBackToLogin,
    required this.onResendEmail,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.mark_email_read,
              color: AppColors.success,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email sent to:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: AnimatedButton(
              text: 'Back to Login',
              onPressed: onBackToLogin,
              backgroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onResendEmail,
            child: const Text(
              'Resend Email',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
