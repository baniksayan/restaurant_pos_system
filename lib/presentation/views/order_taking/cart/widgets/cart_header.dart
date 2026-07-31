import 'package:flutter/material.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/haptic_helper.dart';

class CartHeader extends StatelessWidget {
  final bool hasKotItems;
  final bool hasNewItems;
  final String? kotOrderNumber;
  final String? tableName;
  final String? selectedLocation;
  final int totalItems;
  final bool hasItems;
  final bool showClearAll;
  final VoidCallback onClearCart;
  final VoidCallback onAddMore;

  const CartHeader({
    super.key,
    required this.hasKotItems,
    required this.hasNewItems,
    this.kotOrderNumber,
    this.tableName,
    this.selectedLocation,
    required this.totalItems,
    required this.hasItems,
    required this.showClearAll,
    required this.onClearCart,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    String? statusText;
    Color? statusColor;

    if (hasNewItems) {
      statusText = 'PENDING KOT';
      statusColor = const Color(0xFFEA580C);
    } else if (hasKotItems) {
      statusText = 'KOT SENT';
      statusColor = AppColors.kotStatus;
    }

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
                        if (statusText != null && statusColor != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Text(
                    //   kotGenerated && kotOrderNumber != null
                    //       ? 'Order #$kotOrderNumber • $totalItems items'
                    //       : '$totalItems items',
                    //   style: const TextStyle(
                    //     fontSize: 14,
                    //     color: AppColors.textSecondary,
                    //   ),
                    // ),
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
              if (showClearAll)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      onClearCart();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Clear All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[300]!),
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
        ],
      ),
    );
  }
}
