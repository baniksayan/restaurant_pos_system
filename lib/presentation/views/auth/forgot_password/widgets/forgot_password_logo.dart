import 'package:flutter/material.dart';
import '../../../../../shared/widgets/animations/fade_in_animation.dart';
import '../../../../../shared/widgets/animations/scale_animation.dart';

class ForgotPasswordLogo extends StatelessWidget {
  const ForgotPasswordLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: ScaleAnimation(
        duration: const Duration(milliseconds: 800),
        child: Container(
          width: 120,
          height: 120,
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
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/images/logo/wizard_logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
