import 'package:flutter/material.dart';
import '../login/login_view.dart';
import 'widgets/auth_app_bar.dart';
import 'widgets/forgot_password_logo.dart';
import 'widgets/forgot_password_header.dart';
import '../widgets/email_form_widget.dart';
import 'widgets/email_success_widget.dart';
import 'widgets/back_to_login_widget.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    }
  }

  void _navigateBackToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  void _handleResendEmail() {
    setState(() {
      _emailSent = false;
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const AuthAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const ForgotPasswordLogo(),
                const SizedBox(height: 40),
                ForgotPasswordHeader(emailSent: _emailSent),
                const SizedBox(height: 40),
                
                if (!_emailSent) ...[
                  EmailFormWidget(
                    formKey: _formKey,
                    emailController: _emailController,
                    isLoading: _isLoading,
                    onSendResetEmail: _handleSendResetEmail,
                  ),
                ] else ...[
                  EmailSuccessWidget(
                    email: _emailController.text,
                    onBackToLogin: _navigateBackToLogin,
                    onResendEmail: _handleResendEmail,
                  ),
                ],
                
                const SizedBox(height: 40),
                
                if (!_emailSent)
                  BackToLoginWidget(onBackToLogin: () => Navigator.of(context).pop()),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
