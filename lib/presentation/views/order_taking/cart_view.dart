// lib/presentation/views/order_taking/cart_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../../../core/themes/app_colors.dart';
import '../../view_models/providers/animated_cart_provider.dart';
import '../../../services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CartView extends StatefulWidget {
  final String? tableId;
  final String? tableName;

  const CartView({super.key, this.tableId, this.tableName});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  bool _kotGenerated = false;
  String? _kotOrderNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<AnimatedCartProvider>(
          builder: (context, cartProvider, child) {
            return Stack(
              children: [
                // 👈 Main UI - Always Interactive
                Column(
                  children: [
                    _buildEnhancedHeader(context, cartProvider),
                    if (cartProvider.cartItems.isEmpty)
                      const Expanded(child: _EmptyCartWidget())
                    else
                      // 👈 FIX: Always scrollable cart items
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _buildCartItems(context, cartProvider),
                        ),
                      ),
                    if (cartProvider.cartItems.isNotEmpty)
                      _buildEnhancedCheckoutFooter(context, cartProvider),
                  ],
                ),
                // 👈 FIX: Non-blocking overlay
                if (_kotGenerated)
                  IgnorePointer(
                    ignoring: true, // Let touches pass through
                    child: _buildKOTGeneratedOverlay(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
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
          // Main header row
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
                        if (_kotGenerated) ...[
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
                      _kotGenerated && _kotOrderNumber != null
                          ? 'Order #$_kotOrderNumber • ${cartProvider.totalItems} items'
                          : '${cartProvider.totalItems} items',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 👈 FIX: Clear button only when items exist and no KOT
              if (cartProvider.cartItems.isNotEmpty && !_kotGenerated)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _triggerHapticFeedback();
                      _showClearCartDialog(context, cartProvider);
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
          // 👈 FIX: Add More Items - Always visible when cart has items
          if (cartProvider.cartItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _triggerHapticFeedback();
                  _navigateBackToMenu(context, cartProvider);
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

  // 👈 FIX: Always scrollable cart items
  Widget _buildCartItems(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children:
            cartProvider.cartItems.values
                .map(
                  (item) =>
                      _buildEnhancedCartItemCard(context, item, cartProvider),
                )
                .toList(),
      ),
    );
  }

  Widget _buildEnhancedCartItemCard(
    BuildContext context,
    CartItem item,
    AnimatedCartProvider cartProvider,
  ) {
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
                          if (!_kotGenerated)
                            IconButton(
                              onPressed: () {
                                _triggerHapticFeedback();
                                _showEditItemDialog(
                                  context,
                                  item,
                                  cartProvider,
                                );
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
                if (!_kotGenerated)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _triggerHapticFeedback();
                            cartProvider.removeItem(item.id);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 16,
                            ),
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
                          onTap: () {
                            _triggerHapticFeedback();
                            cartProvider.addItem(
                              item.id,
                              item.name,
                              item.price,
                              item.tableId,
                              item.tableName,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
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

  Widget _buildEnhancedCheckoutFooter(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
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
          // 👈 FIX: GST Info - Always clickable
          GestureDetector(
            onTap: () {
              _triggerHapticFeedback();
              _showGSTInfoDialog(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restaurant GST: 18% (Pre-defined) - Tap for info',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
          ),
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
          if (!_kotGenerated)
            _buildPreKOTButtons(context, cartProvider)
          else
            _buildPostKOTButtons(context, cartProvider),
        ],
      ),
    );
  }

  Widget _buildPreKOTButtons(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _triggerHapticFeedback();
          _generateKOT(context, cartProvider);
        },
        icon: const Icon(Icons.print, size: 20),
        label: const Text('Generate KOT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildPostKOTButtons(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            // 👈 FIX: Always enabled Send to Kitchen
            onPressed: () {
              _triggerHapticFeedback();
              _sendToKitchen(context, cartProvider);
            },
            icon: const Icon(Icons.kitchen, size: 20),
            label: const Text('Send to Kitchen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.orange),
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _triggerHapticFeedback();
              _navigateToBillingPage(context, cartProvider);
            },
            icon: const Icon(Icons.receipt_long, size: 20),
            label: const Text('Generate Bill'),
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
    );
  }

  // 👈 FIX: Non-blocking overlay
  Widget _buildKOTGeneratedOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.05), // Lighter overlay
        child: Center(
          child: Transform.rotate(
            angle: -0.3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'KOT GENERATED',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.withOpacity(0.4),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ),
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

  // 👈 FIX: Working Haptic Feedback
  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 50, amplitude: 128);
      }
      await HapticFeedback.lightImpact();
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }

  // 👈 FIX: Always working GST Info Dialog
  void _showGSTInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('GST Information'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurant GST Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• GST Rate: 18% (Pre-defined)'),
                Text('• Applied to all food items'),
                Text('• Inclusive in final amount'),
                SizedBox(height: 12),
                Card(
                  color: Color(0xFFE8F5E8),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'This is a standard restaurant GST rate as per regulations.',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  // 👈 FIX: Always working Navigate Back to Menu
  void _navigateBackToMenu(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
    try {
      final items = cartProvider.cartItems.values.toList();
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items in cart to navigate back'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final firstItem = items.first;
      // Navigate back to previous screen (should be menu)
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Back to menu for ${firstItem.tableName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateKOT(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) async {
    try {
      final orderNumber = PDFService.generateOrderNumber();
      final items = cartProvider.cartItems.values.toList();
      if (items.isEmpty) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await Future.delayed(const Duration(seconds: 2));

      final kotBytes = await PDFService.generateKOT(
        items: items,
        tableId: items.first.tableId,
        tableName: items.first.tableName,
        orderNumber: orderNumber,
        orderTime: DateTime.now(),
      );

      Navigator.pop(context);

      setState(() {
        _kotGenerated = true;
        _kotOrderNumber = orderNumber;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT #$orderNumber generated successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share KOT',
            onPressed: () {
              PDFService.sharePDF(kotBytes, 'KOT_$orderNumber');
            },
          ),
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

  // 👈 FIX: Always working Send to Kitchen
  Future<void> _sendToKitchen(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) async {
    if (_kotOrderNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate KOT first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Sending Order #$_kotOrderNumber to Kitchen...'),
                ],
              ),
            ),
      );

      // Generate KOT for sharing
      final items = cartProvider.cartItems.values.toList();
      final kotBytes = await PDFService.generateKOT(
        items: items,
        tableId: items.first.tableId,
        tableName: items.first.tableName,
        orderNumber: _kotOrderNumber!,
        orderTime: DateTime.now(),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);

      // Show options for sharing
      _showSendToKitchenOptions(context, kotBytes, _kotOrderNumber!);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending to kitchen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSendToKitchenOptions(
    BuildContext context,
    dynamic kotBytes,
    String orderNumber,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Send Order #$orderNumber to Kitchen'),
            content: const Text('Choose how to send the KOT to kitchen:'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendViaWhatsApp(kotBytes, orderNumber);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.message, color: Colors.green),
                    SizedBox(width: 4),
                    Text('WhatsApp'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _printKOT(kotBytes, orderNumber);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('Print'),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareKOT(kotBytes, orderNumber);
                },
                child: const Text('Share'),
              ),
            ],
          ),
    );
  }

  void _sendViaWhatsApp(dynamic kotBytes, String orderNumber) async {
    try {
      // First share the KOT file
      await PDFService.sharePDF(kotBytes, 'KOT_$orderNumber');

      // Then open WhatsApp with pre-filled message
      final whatsappMessage =
          "New order from restaurant! Please check the KOT.";
      final whatsappUrl =
          "https://wa.me/+918768412832?text=${Uri.encodeComponent(whatsappMessage)}";

      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT #$orderNumber sent via WhatsApp!'),
          backgroundColor: const Color.fromARGB(255, 17, 114, 58),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending via WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _printKOT(dynamic kotBytes, String orderNumber) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$orderNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT #$orderNumber ready to print!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareKOT(dynamic kotBytes, String orderNumber) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$orderNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT #$orderNumber shared!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToBillingPage(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
    if (!_kotGenerated || _kotOrderNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate and send KOT first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text('Generate Bill - Order #$_kotOrderNumber'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bill Generation Page',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Order #$_kotOrderNumber'),
                    Text('${cartProvider.cartItems.length} items'),
                    const SizedBox(height: 20),
                    const Text(
                      'This page will be implemented later\nwith all customer billing functionalities',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        cartProvider.clearCart();
                        setState(() {
                          _kotGenerated = false;
                          _kotOrderNumber = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Close & Clear Cart'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    CartItem item,
    AnimatedCartProvider cartProvider,
  ) {
    if (_kotGenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit items after KOT is generated'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController notesController = TextEditingController(
      text: item.specialNotes ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Price: ₹${item.price} | Qty: ${item.quantity}',
                                      ),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showRemoveConfirmation(
                              context,
                              item,
                              cartProvider,
                            );
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
                            _triggerHapticFeedback();
                            cartProvider.updateItemNotes(
                              item.id,
                              notesController.text.trim(),
                            );
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

  void _showRemoveConfirmation(
    BuildContext context,
    CartItem item,
    AnimatedCartProvider cartProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: Text('Remove ${item.name} from cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _triggerHapticFeedback();
                  cartProvider.removeItem(item.id);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} removed from cart'),
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

  void _showClearCartDialog(
    BuildContext context,
    AnimatedCartProvider cartProvider,
  ) {
    if (_kotGenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot clear cart after KOT is generated'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text('Remove all items from cart?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _triggerHapticFeedback();
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
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
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
