import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/menu_provider.dart';

class CartFooter extends StatelessWidget {
  final VoidCallback onPlaceOrder;

  const CartFooter({
    super.key,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.cart.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.cardShadow, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${menuProvider.totalCartItems} items',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${menuProvider.calculateTotal().toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onPlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
