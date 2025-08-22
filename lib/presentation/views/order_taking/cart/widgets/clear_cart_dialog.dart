import 'package:flutter/material.dart';
import '../../../../../core/utils/haptic_helper.dart';

class ClearCartDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ClearCartDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clear Cart'),
      content: const Text('Remove all items from cart?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await HapticHelper.triggerFeedback();
            Navigator.pop(context);
            onConfirm();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cart cleared'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text(
            'Clear All',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
