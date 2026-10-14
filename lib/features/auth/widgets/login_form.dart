import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/app_validators.dart';
import '../providers/auth_provider.dart';
import 'package:restaurant_pos_system/shared/widgets/forms/custom_text_field.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/fade_in_animation.dart';
import 'package:restaurant_pos_system/shared/widgets/buttons/animated_button.dart';
import 'package:restaurant_pos_system/features/menu/views/standalone_menu_view.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/dashboard_provider.dart';
import 'package:restaurant_pos_system/features/chef/providers/chef_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/url_helper.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/access_denied_dialog.dart';
import 'package:restaurant_pos_system/shared/widgets/feedback/app_message_banner.dart';

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
  bool _agreeToTerms = true;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_clearErrorOnTyping);
    _passwordController.addListener(_clearErrorOnTyping);
  }

  void _clearErrorOnTyping() {
    final auth = context.read<AuthProvider>();
    if (auth.errorMessage != null) {
      auth.clearError();
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_clearErrorOnTyping);
    _passwordController.removeListener(_clearErrorOnTyping);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_agreeToTerms) return;
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

      if (!mounted) return;

      // Show blocking dialog if the access-denied flag was set by the provider.
      if (authProvider.accessDenied) {
        await _showAccessDeniedDialog(authProvider);
        return;
      }

      if (success && mounted) {
        final apiLocations = HiveService.getLocations();

        // If authenticated user is a Chef, navigate to Chef KDS
        if (HiveService.isChefLoggedIn()) {
          if (apiLocations.isNotEmpty && mounted) {
            await context.read<ChefProvider>().updateLocationsFromApi(apiLocations);
          }
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/chef');
          }
          return;
        }
        // Update DashboardProvider with the freshly received locations
        if (apiLocations.isNotEmpty && mounted) {
          context.read<DashboardProvider>().updateLocationsFromApi(apiLocations);
        }

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
      }
    }
  }

  /// Shows a premium glassmorphic modal dialog explaining that this account
  /// does not have access to WhizEats Pro. The flag is cleared once dismissed.
  Future<void> _showAccessDeniedDialog(AuthProvider authProvider) async {
    await AccessDeniedDialog.show(
      context,
      onDismiss: () {
        authProvider.clearAccessDenied();
      },
    );
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
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final error = auth.errorMessage;
                if (error == null || error.isEmpty) {
                  return const SizedBox.shrink();
                }
                return AppMessageBanner(
                  message: error,
                  type: MessageBannerType.error,
                  onDismiss: () => auth.clearError(),
                );
              },
            ),
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
            const SizedBox(height: 14),
            _buildTermsAndPrivacyConsent(),
            const SizedBox(height: 20),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacyConsent() {
    return InkWell(
      onTap: () {
        setState(() {
          _agreeToTerms = !_agreeToTerms;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreeToTerms,
                onChanged: (val) {
                  setState(() {
                    _agreeToTerms = val ?? false;
                  });
                },
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    AppStrings.auth.iAgreeToThe,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => UrlHelper.openUrl(
                      context,
                      AppStrings.termsAndConditionsUrl,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        AppStrings.auth.termsAndConditions,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.auth.and,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => UrlHelper.openUrl(
                      context,
                      AppStrings.privacyPolicyUrl,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        AppStrings.auth.privacyPolicy,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        final isEnabled = _agreeToTerms && !authProvider.isLoading;
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: AnimatedButton(
            text: AppStrings.login,
            onPressed: isEnabled ? _handleLogin : null,
            isEnabled: isEnabled,
            isLoading: authProvider.isLoading,
            backgroundColor: AppColors.primary,
          ),
        );
      },
    );
  }
}
