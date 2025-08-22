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
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/logo/wizard_logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.auto_awesome,
                      size: 60,
                      color: AppColors.primary,
                    );
                  },
                ),
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
