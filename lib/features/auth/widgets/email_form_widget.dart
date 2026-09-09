import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/app_validators.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/fade_in_animation.dart';
import 'package:restaurant_pos_system/shared/widgets/buttons/animated_button.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

import 'package:restaurant_pos_system/shared/widgets/forms/custom_text_field.dart';

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
            CustomTextField(
              label: AppStrings.auth.emailAddress,
              hintText: AppStrings.auth.enterEmailAddress,
              controller: emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: AppValidators.email,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: AnimatedButton(
                text: AppStrings.auth.sendResetEmail,
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
