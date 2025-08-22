import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add items from menu to see them here',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
