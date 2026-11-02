import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/features/dashboard/views/main_navigation.dart';
import '../widgets/login_form.dart';
import '../widgets/login_header.dart';
import 'forgot_password_view.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/permissions/app_permission_service.dart';
import 'package:restaurant_pos_system/core/localization/widgets/language_selection_dialog.dart';
import 'package:restaurant_pos_system/core/localization/extensions/localization_extension.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppPermissionService.checkInitialPermissions(context);
      }
    });
  }

  void _navigateToForgotPassword(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordView()));
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEEF2FF), // Indigo 50
                Color(0xFFF8FAFC), // Slate 50
                Color(0xFFE0E7FF), // Indigo 100
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient glowing background orbs matching SplashView
              _buildAmbientGlowOrbs(),

              // Top right language switcher
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildLanguageSelector(context),
                  ),
                ),
              ),

              // Main Glassmorphism Content Card matching SplashView
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 36,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LoginHeader(),
                                LoginForm(
                                  onForgotPassword:
                                      () => _navigateToForgotPassword(context),
                                  onLoginSuccess:
                                      () => _navigateToDashboard(context),
                                ),
                                const SizedBox(height: 28),
                                _buildBottomBranding(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientGlowOrbs() {
    return Stack(
      children: [
        // Top-left ambient indigo glow
        Positioned(
          left: -60,
          top: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ),
        // Bottom-right ambient accent glow
        Positioned(
          right: -80,
          bottom: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryDark.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBranding() {
    return Column(
      children: [
        Text(
          AppStrings.poweredBy,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          AppStrings.solutionTagline,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final currentLang = context.currentLanguage;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => LanguageSelectionDialog.show(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.translate_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                currentLang.nativeName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
