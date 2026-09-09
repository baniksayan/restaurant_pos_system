import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/app_validators.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import '../providers/auth_provider.dart';
import 'package:restaurant_pos_system/shared/widgets/forms/custom_text_field.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/fade_in_animation.dart';
import 'package:restaurant_pos_system/shared/widgets/buttons/animated_button.dart';
import 'package:restaurant_pos_system/features/menu/views/standalone_menu_view.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onForgotPassword;
  final VoidCallback onLoginSuccess;

  const LoginForm({
    super.key,
    required this.onForgotPassword,
    required this.onLoginSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;

      final email = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // CHEF DEMO LOGIN — HARD-CODED ONLY
      // If credentials exactly match wizdemo@gmail.com + 123456789 -> Save Chef Session & Enter Chef Screen
      if (email.toLowerCase() == 'wizdemo@gmail.com' &&
          password == '123456789') {
        await HiveService.setChefSession(true);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/chef');
        }
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(
        context,
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        // Check if we need direct menu navigation
        if (authProvider.shouldNavigateDirectlyToMenu) {
          // Navigate directly to standalone menu view
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => StandaloneMenuView(
                    autoSelectedTableId: authProvider.autoSelectedTableId,
                    autoSelectedTableName: authProvider.autoSelectedTableName,
                  ),
            ),
          );
        } else {
          // Normal navigation to dashboard
          widget.onLoginSuccess();
        }
      } else if (mounted && authProvider.errorMessage != null) {
        AppSnackBar.showError(context, authProvider.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 600),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              label: AppStrings.auth.userName,
              hintText: AppStrings.auth.enterUsername,
              controller: _usernameController,
              prefixIcon: Icons.person_outline,
              validator:
                  (value) => AppValidators.required(value, 'your username'),
            ),
            const SizedBox(height: 18),
            CustomTextField(
              label: AppStrings.auth.password,
              hintText: AppStrings.auth.enterPassword,
              controller: _passwordController,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator:
                  (value) => AppValidators.required(value, 'your password'),
            ),
            // Commented out Remember Me & Forgot Password option per request:
            /*
            const SizedBox(height: 16),
            _buildRememberMeAndForgotPassword(),
            */
            const SizedBox(height: 28),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  /*
  Widget _buildRememberMeAndForgotPassword() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: authProvider.rememberMe,
                  onChanged:
                      (value) => authProvider.setRememberMe(value ?? false),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Text(
                  'Remember Me',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.onForgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  */

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: AnimatedButton(
            text: AppStrings.login,
            onPressed: _handleLogin,
            isLoading: authProvider.isLoading,
            backgroundColor: AppColors.primary,
          ),
        );
      },
    );
  }
}
