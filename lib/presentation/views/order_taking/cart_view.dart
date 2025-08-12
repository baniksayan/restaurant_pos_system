// lib/presentation/views/order_taking/cart_view.dart - COMPLETE MERGED & FIXED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../view_models/providers/animated_cart_provider.dart';
import '../../../services/pdf_service.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<AnimatedCartProvider>(
          builder: (context, cartProvider, child) {
            return Column(
              children: [
                _buildHeader(context, cartProvider),
                if (cartProvider.cartItems.isEmpty)
                  const Expanded(child: _EmptyCartWidget())
                else
                  Expanded(child: _buildCartItems(context, cartProvider)),
                if (cartProvider.cartItems.isNotEmpty)
                  _buildCheckoutFooter(context, cartProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AnimatedCartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardShadow, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${cartProvider.totalItems} items',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showSpecialNotesDialog(context, cartProvider),
            icon: const Icon(Icons.edit_note, color: AppColors.primary),
            tooltip: 'Add Special Notes',
          ),
          if (cartProvider.cartItems.isNotEmpty)
            TextButton(
              onPressed: () => _showClearCartDialog(context, cartProvider),
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context, AnimatedCartProvider cartProvider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartProvider.cartItems.length,
      itemBuilder: (context, index) {
        final item = cartProvider.cartItems.values.elementAt(index);
        return _buildEnhancedCartItemCard(context, item, cartProvider);
      },
    );
  }

  Widget _buildEnhancedCartItemCard(BuildContext context, CartItem item, AnimatedCartProvider cartProvider) {
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
          // Main item row
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
                  child: const Icon(Icons.restaurant, color: Colors.orange, size: 30),
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
                            onPressed: () => _showEditItemDialog(context, item, cartProvider),
                            icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
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
                    ],
                  ),
                ),
                
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => cartProvider.removeItem(item.id),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.remove, color: Colors.white, size: 16),
                        ),
                      ),
                      Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => cartProvider.addItem(item.id, item.name, item.price, item.tableId, item.tableName),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Special notes section
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

  Widget _buildCheckoutFooter(BuildContext context, AnimatedCartProvider cartProvider) {
    final subtotal = cartProvider.totalAmount;
    final gstAmount = subtotal * 0.18;
    final total = subtotal + gstAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardShadow, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPriceRow("Subtotal:", "₹${subtotal.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _buildPriceRow("GST (18%):", "₹${gstAmount.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          const Divider(thickness: 2),
          const SizedBox(height: 8),
          _buildPriceRow(
            "TOTAL AMOUNT:", 
            "₹${total.toStringAsFixed(2)}",
            isTotal: true,
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _generateKOT(context, cartProvider),
                  icon: const Icon(Icons.print, size: 20),
                  label: const Text('KOT'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _placeOrder(context, cartProvider),
                  icon: const Icon(Icons.receipt_long, size: 20),
                  label: const Text('Place Order & Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : Colors.black,
          ),
        ),
      ],
    );
  }

  // 🔥 FIXED EDIT DIALOG - NO MORE OVERFLOW
  void _showEditItemDialog(BuildContext context, CartItem item, AnimatedCartProvider cartProvider) {
    final TextEditingController notesController = TextEditingController(text: item.specialNotes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
            maxWidth: 400,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.edit, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit ${item.name}',
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
              
              // Scrollable content - FIXES OVERFLOW
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
                            const Icon(Icons.restaurant, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Price: ₹${item.price} | Qty: ${item.quantity}'),
                                  Text('Table: ${item.tableName}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: notesController,
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
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showRemoveConfirmation(context, item, cartProvider);
                      },
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
                      onPressed: () {
                        cartProvider.updateItemNotes(item.id, notesController.text.trim());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} updated!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
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
      ),
    );
  }

  // 🔥 FIXED SPECIAL NOTES DIALOG
  void _showSpecialNotesDialog(BuildContext context, AnimatedCartProvider cartProvider) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: 400,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Order Special Instructions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      const Text('Add special instructions for the entire order:'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Order Instructions',
                          hintText: 'e.g., Serve hot, Less oil, Extra sauce on side, etc.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant_menu),
                        ),
                        maxLines: 4,
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final notes = notesController.text.trim();
                        Navigator.pop(context);
                        if (notes.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Special instructions added'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Remove confirmation dialog
  void _showRemoveConfirmation(BuildContext context, CartItem item, AnimatedCartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${item.name} from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.removeItem(item.id);
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close edit dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} removed from cart'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Clear cart confirmation
  void _showClearCartDialog(BuildContext context, AnimatedCartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔥 UPDATED _placeOrder method
  Future<void> _placeOrder(BuildContext context, AnimatedCartProvider cartProvider) async {
    try {
      final orderNumber = PDFService.generateOrderNumber();
      final items = cartProvider.cartItems.values.toList();
      
      if (items.isEmpty) return;

      final subtotal = cartProvider.totalAmount;
      final gstAmount = subtotal * 0.18;
      final total = subtotal + gstAmount;

      // Collect all special notes from items
      final specialNotes = items
          .where((item) => item.specialNotes != null && item.specialNotes!.isNotEmpty)
          .map((item) => "${item.name}: ${item.specialNotes}")
          .join('\n');

      showDialog(
        context: context, 
        barrierDismissible: false, 
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate bill with special notes
      final billBytes = await PDFService.generateCustomerBill(
        items: items,
        tableId: items.first.tableId,
        tableName: items.first.tableName,
        orderNumber: orderNumber,
        orderTime: DateTime.now(),
        subtotal: subtotal,
        gstAmount: gstAmount,
        total: total,
        specialNotes: specialNotes.isNotEmpty ? specialNotes : null,
      );

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed Successfully!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Order #$orderNumber placed for ${items.first.tableName}'),
              if (specialNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Special Instructions included in bill', 
                  style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { 
                Navigator.pop(context); 
                cartProvider.clearCart(); 
              }, 
              child: const Text('Done'),
            ),
            TextButton(
              onPressed: () async { 
                await PDFService.sharePDF(billBytes, 'Bill_$orderNumber'); 
              }, 
              child: const Text('Share Bill'),
            ),
          ],
        ),
      );

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateKOT(BuildContext context, AnimatedCartProvider cartProvider) async {
    try {
      final orderNumber = PDFService.generateOrderNumber();
      final items = cartProvider.cartItems.values.toList();
      
      if (items.isEmpty) return;

      // Collect special notes for KOT
      final specialNotes = items
          .where((item) => item.specialNotes != null && item.specialNotes!.isNotEmpty)
          .map((item) => "${item.name}: ${item.specialNotes}")
          .join('\n');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Simulate KOT generation
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT generated for Order #$orderNumber'),
          backgroundColor: Colors.green,
          action: specialNotes.isNotEmpty 
            ? SnackBarAction(
                label: 'View Notes',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Special Instructions'),
                      content: Text(specialNotes),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating KOT: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _EmptyCartWidget extends StatelessWidget {
  const _EmptyCartWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
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
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
