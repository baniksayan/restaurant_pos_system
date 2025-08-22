import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/utils/haptic_helper.dart';
import '../../../../view_models/providers/animated_cart_provider.dart';

class EditItemDialog extends StatefulWidget {
  final CartItem item;

  const EditItemDialog({
    super.key,
    required this.item,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.specialNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<AnimatedCartProvider>(context, listen: false);

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit ${widget.item.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restaurant,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Price: ₹${widget.item.price} | Qty: ${widget.item.quantity}',
                                ),
                                Text('Table: ${widget.item.tableName}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Special Instructions',
                        hintText: 'e.g., Extra spicy, No onions, etc.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRemoveConfirmation(context, cartProvider),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Remove'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _saveChanges(context, cartProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges(BuildContext context, AnimatedCartProvider cartProvider) async {
    await HapticHelper.triggerFeedback();
    cartProvider.updateItemNotes(
      widget.item.id,
      _notesController.text.trim(),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.item.name} updated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, AnimatedCartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${widget.item.name} from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              cartProvider.removeItem(widget.item.id);
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close edit dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.item.name} removed from cart'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
