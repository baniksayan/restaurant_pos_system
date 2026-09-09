import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_assets.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_gradients.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/fade_in_animation.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/scale_animation.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo Container matching SplashView
        FadeInAnimation(
          delay: const Duration(milliseconds: 200),
          child: ScaleAnimation(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                AppAssets.logoTransparent,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Brand Name & Subtitle matching SplashView
        FadeInAnimation(
          delay: const Duration(milliseconds: 400),
          child: Column(
            children: [
              const Text(
                AppStrings.brandName,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                AppStrings.brandSuffix,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 14),

              // Restaurant POS System Tagline Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  AppStrings.posTagline,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Log In Header Title
        FadeInAnimation(
          delay: const Duration(milliseconds: 500),
          child: Text(
            AppStrings.auth.logIn,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
