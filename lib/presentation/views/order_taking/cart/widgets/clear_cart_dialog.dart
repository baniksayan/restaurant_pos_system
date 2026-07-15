import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.red[600], size: 28),
          const SizedBox(width: 12),
          const Text(
            'Clear Cart',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to remove all items from your cart? This will clear all pending order selections.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Clear All',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
