import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/animations/fade_in_animation.dart';
import '../../../../shared/widgets/buttons/animated_button.dart';

class EmailFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSendResetEmail;

  const EmailFormWidget({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSendResetEmail,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 600),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: AnimatedButton(
                text: 'Send Reset Email',
                onPressed: onSendResetEmail,
                isLoading: isLoading,
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
