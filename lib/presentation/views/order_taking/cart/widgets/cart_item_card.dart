import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/haptic_helper.dart';
import '../../../../view_models/providers/animated_cart_provider.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onEdit;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<AnimatedCartProvider>(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await HapticHelper.triggerFeedback();
                              onEdit();
                            },
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For ${item.tableName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Text(' × '),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(' = '),
                          Flexible(
                            child: Text(
                              '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await HapticHelper.triggerFeedback();
                            cartProvider.removeItem(item.id);
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: AppColors.primary,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await HapticHelper.triggerFeedback();
                            cartProvider.addItem(
                              item.id,
                              item.name,
                              item.price,
                              item.tableId,
                              item.tableName,
                            );
                          },
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (item.specialNotes != null && item.specialNotes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Special: ${item.specialNotes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
