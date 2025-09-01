import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const LoginHeader(),
                  LoginForm(
                    onForgotPassword: () => _navigateToForgotPassword(context),
                    onLoginSuccess: () => _navigateToDashboard(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
