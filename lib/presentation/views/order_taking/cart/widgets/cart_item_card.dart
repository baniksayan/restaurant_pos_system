import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/haptic_helper.dart';
import '../../../../view_models/providers/animated_cart_provider.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onEdit;

  const CartItemCard({super.key, required this.item, required this.onEdit});

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row - Food name, special instruction icon, delete all icon
            Row(
              children: [
                // REMOVED LEFT-SIDE ICON - Show food name directly
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
                // REPLACED EDIT ICON with meaningful special instruction icon
                IconButton(
                  onPressed: () async {
                    await HapticHelper.triggerFeedback();
                    onEdit();
                  },
                  icon: const Icon(
                    Icons.sticky_note_2, // Better icon for special instructions
                    size: 20,
                    color: AppColors.primary,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  tooltip: 'Add special instructions',
                ),
                // DELETE ALL BUTTON for multiple items - FIXED IMPLEMENTATION
                if (item.quantity > 1)
                  IconButton(
                    onPressed: () async {
                      await HapticHelper.triggerFeedback();
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Delete All Items'),
                            content: Text(
                              'Remove all ${item.quantity} "${item.name}" items from cart?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Delete All',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (shouldDelete == true) {
                        cartProvider.deleteAllOfItem(
                          item.id,
                        ); // <-- Use deleteAllOfItem here
                      }
                    },
                    icon: const Icon(
                      Icons.delete_sweep,
                      size: 20,
                      color: Colors.red,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    tooltip: 'Delete all ${item.quantity} items',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Table info
            Text(
              'For ${item.tableName}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // SPECIAL INSTRUCTIONS with truncation and eye icon
            if (item.specialNotes != null && item.specialNotes!.isNotEmpty)
              _buildSpecialInstructions(context),
            const SizedBox(height: 12),
            // Bottom row - Price calculation and quantity controls
            Row(
              children: [
                // Price calculation
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
                      Text(
                        '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // QUANTITY CONTROLS with confirmation for zero
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
                      // Decrement button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await HapticHelper.triggerFeedback();
                            // CONFIRMATION when decrementing to zero
                            if (item.quantity == 1) {
                              final shouldRemove =
                                  await _showRemoveConfirmDialog(context);
                              if (shouldRemove) {
                                cartProvider.removeItem(item.id);
                              }
                            } else {
                              cartProvider.removeItem(item.id);
                            }
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
                      // Quantity display
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
                      // Increment button
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
                              categoryId: item.categoryId,
                              categoryName: item.categoryName,
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
          ],
        ),
      ),
    );
  }

  // SPECIAL INSTRUCTIONS with truncation and modal view
  Widget _buildSpecialInstructions(BuildContext context) {
    final instruction = item.specialNotes!;
    final isLong = instruction.length > 40; // Truncate if longer than 40 chars

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: GestureDetector(
        onTap: isLong ? () => _showFullInstructionModal(context) : null,
        child: Row(
          children: [
            Icon(Icons.note_alt, color: Colors.blue[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isLong
                    ? '${instruction.substring(0, 37)}...' // Truncate with ellipsis
                    : instruction, // Show full text if short
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            // EYE ICON for long instructions
            if (isLong) ...[
              const SizedBox(width: 8),
              Icon(Icons.visibility, color: Colors.blue[700], size: 16),
            ],
          ],
        ),
      ),
    );
  }

  // CONFIRMATION DIALOG when decrementing to zero
  Future<bool> _showRemoveConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Remove Item'),
          content: const Text(
            'Do you really want to remove this item from the cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // MODAL for viewing full special instructions
  void _showFullInstructionModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.note_alt, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              const Text('Special Instructions'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              item.specialNotes!,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
