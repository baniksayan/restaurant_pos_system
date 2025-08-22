import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/haptic_helper.dart';

class CartHeader extends StatelessWidget {
  final bool kotGenerated;
  final String? kotOrderNumber;
  final String? tableName;
  final String? selectedLocation;
  final int totalItems;
  final bool hasItems;
  final VoidCallback onClearCart;
  final VoidCallback onAddMore;

  const CartHeader({
    super.key,
    required this.kotGenerated,
    this.kotOrderNumber,
    this.tableName,
    this.selectedLocation,
    required this.totalItems,
    required this.hasItems,
    required this.onClearCart,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Cart',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (kotGenerated) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'KOT SENT',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      kotGenerated && kotOrderNumber != null
                          ? 'Order #$kotOrderNumber • $totalItems items'
                          : '$totalItems items',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (tableName != null) ...[
                      Text(
                        'Table: $tableName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (selectedLocation != null)
                        Text(
                          'Location: $selectedLocation',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (hasItems)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      onClearCart();
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (hasItems) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await HapticHelper.triggerFeedback();
                  onAddMore();
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Add More Items'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
