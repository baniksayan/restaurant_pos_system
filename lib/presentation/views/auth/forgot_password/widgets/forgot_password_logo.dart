import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../shared/widgets/animations/fade_in_animation.dart';
import '../../../../../shared/widgets/animations/scale_animation.dart';

class ForgotPasswordLogo extends StatelessWidget {
  const ForgotPasswordLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: ScaleAnimation(
        duration: const Duration(milliseconds: 800),
        child: Container(
          width: 120,
          height: 120,
          child: Image.asset(
            'assets/images/logo/wizard_logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
