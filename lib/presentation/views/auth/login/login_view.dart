import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/auth_provider.dart';
import 'package:restaurant_pos_system/presentation/views/auth/login/widgets/login_form.dart';
import 'package:restaurant_pos_system/presentation/views/auth/login/widgets/login_header.dart';
import 'package:restaurant_pos_system/presentation/views/auth/forgot_password/forgot_password_view.dart';
import 'package:restaurant_pos_system/presentation/views/main_navigation.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

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
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                                        () =>
                                            _navigateToForgotPassword(context),
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
    return const Column(
      children: [
        Text(
          'Powered by Wizard Communications Pvt. Ltd.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Advanced Restaurant Management Solution',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
