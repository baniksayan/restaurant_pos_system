import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/fade_in_animation.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/scale_animation.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        FadeInAnimation(
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
        ),
        const SizedBox(height: 40),
        const FadeInAnimation(
          delay: Duration(milliseconds: 400),
          child: Text(
            'Log In',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
