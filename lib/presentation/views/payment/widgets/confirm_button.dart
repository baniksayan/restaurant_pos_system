import 'package:flutter/material.dart';

class ConfirmButton extends StatelessWidget {
  final bool processing;
  final VoidCallback? onPressed;
  const ConfirmButton({super.key, required this.processing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: processing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.verified),
        label: Text(processing ? 'Processing...' : 'Confirm Payment Received'),
      ),
    );
  }
}
