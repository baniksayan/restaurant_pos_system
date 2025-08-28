import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/haptic_helper.dart';
import '../../../view_models/providers/animated_cart_provider.dart';
import '../../../view_models/providers/navigation_provider.dart';
import '../../../../services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../billing/billing_page.dart';
import 'widgets/cart_header.dart';
import 'widgets/cart_items_list.dart';
import 'widgets/cart_footer.dart';
import 'widgets/empty_cart_widget.dart';
import 'widgets/edit_item_dialog.dart';
import 'widgets/clear_cart_dialog.dart';
import 'widgets/gst_info_dialog.dart';
import '../../../view_models/providers/order_provider.dart';
import '../../../../data/local/hive_service.dart';

class CartView extends StatefulWidget {
  final String? tableId;
  final String? tableName;
  final String? selectedLocation;

  const CartView({
    super.key,
    this.tableId,
    this.tableName,
    this.selectedLocation,
  });

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
            final items = cartProvider.cartItems.values.toList();

            return Column(
              children: [
                CartHeader(
                  kotGenerated: _kotGenerated,
                  kotOrderNumber: _kotOrderNumber,
                  tableName: widget.tableName,
                  selectedLocation: widget.selectedLocation,
                  totalItems: cartProvider.totalItems,
                  hasItems: items.isNotEmpty,
                  onClearCart: () => _showClearCartDialog(cartProvider),
                  onAddMore: () => _navigateBackToMenu(cartProvider),
                ),
                if (items.isEmpty)
                  const Expanded(child: EmptyCartWidget())
                else
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: CartItemsList(
                        items: items,
                        onEditItem: _showEditItemDialog,
                      ),
                    ),
                  ),
                if (items.isNotEmpty)
                  CartFooter(
                    subtotal: cartProvider.totalAmount,
                    kotGenerated: _kotGenerated,
                    onGenerateKOT: () => _generateKOT(cartProvider),
                    onSendToKitchen: () => _sendToKitchen(cartProvider),
                    onGenerateBill: () => _navigateToBillingPage(cartProvider),
                    onShowGSTInfo: _showGSTInfoDialog,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditItemDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
  }

  void _showClearCartDialog(AnimatedCartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => ClearCartDialog(onConfirm: cartProvider.clearCart),
    );
  }

  void _showGSTInfoDialog() {
    showDialog(context: context, builder: (context) => const GSTInfoDialog());
  }

  void _navigateBackToMenu(AnimatedCartProvider cartProvider) {
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
      context.read<NavigationProvider>().selectTable(
        firstItem.tableId,
        firstItem.tableName,
        widget.selectedLocation ?? '',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigated back to menu'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // KOT Generation with API Integration
  Future<void> _generateKOT(AnimatedCartProvider cartProvider) async {
    try {
      final items = cartProvider.cartItems.values.toList();
      if (items.isEmpty) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating order head...'),
                ],
              ),
            ),
      );

      final orderProvider = context.read<OrderProvider>();

      // Step 1: Create Order Head first if not already created
      if (orderProvider.createdOrderId == null) {
        final orderChannelId = items.first.tableId;
        final waiterId =
            HiveService.getWaiterId() ?? "a2f2849f-88b5-4849-a17d-a487d5e21627";
        final userId =
            HiveService.getUserId() ?? "a2f2849f-88b5-4849-a17d-a487d5e21627";
        final outletId = HiveService.getOutletId() ?? 1;
        final customerName = "Walk-in Customer";

        final orderHeadSuccess = await orderProvider.createOrderHead(
          orderChannelId: orderChannelId,
          waiterId: waiterId,
          customerName: customerName,
          outletId: outletId,
          userId: userId,
        );

        if (!orderHeadSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error creating order: ${orderProvider.error ?? "Unknown error"}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Update loading dialog
      Navigator.of(context).pop();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating KOT...'),
                ],
              ),
            ),
      );

      // Step 2: Generate KOT with order details
      final userId =
          HiveService.getUserId() ?? "a2f2849f-88b5-4849-a17d-a487d5e21627";
      final outletId = HiveService.getOutletId() ?? 1;
      final orderId = orderProvider.createdOrderId!;

      // Convert cart items to the required format
      final cartItemsData =
          items
              .map(
                (item) => {
                  'id': item.id,
                  'name': item.name,
                  'price': item.price,
                  // Fixed typo and ensure non-null values
                  'categoryId': item.categoryId ?? '',
                  'categoryName': item.categoryName ?? '',
                  'quantity': item.quantity,
                  'specialNotes': item.specialNotes ?? '',
                },
              )
              .toList();

      print(cartItemsData.toString());

      final kotResponse = await orderProvider.createKotWithOrderDetails(
        userId: userId,
        outletId: outletId,
        orderId: orderId,
        kotNote: "",
        cartItems: cartItemsData,
      );

      Navigator.of(context).pop();

      if (kotResponse != null && kotResponse.isSuccess == true) {
        // Get KOT details from response
        final kotNo = kotResponse.data?.kotDetail?.kotNo;
        final orderNumber =
            orderProvider.generatedOrderNo ??
            orderProvider.orderNo?.toString() ??
            kotNo ??
            PDFService.generateOrderNumber();

        setState(() {
          _kotGenerated = true;
          _kotOrderNumber = orderNumber;
        });

        // Generate PDF KOT for sharing/printing
        final kotBytes = await PDFService.generateKOT(
          items: items,
          tableId: items.first.tableId,
          tableName: items.first.tableName,
          orderNumber: orderNumber,
          orderTime: DateTime.now(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KOT #$orderNumber generated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                PDFService.sharePDF(kotBytes, 'KOT_$orderNumber');
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating KOT: ${kotResponse?.data?.response ?? "Unknown error"}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating KOT: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Send to Kitchen logic here
  Future<void> _sendToKitchen(AnimatedCartProvider cartProvider) async {
    if (!_kotGenerated || _kotOrderNumber == null) {
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
            (_) => AlertDialog(
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

      final items = cartProvider.cartItems.values.toList();
      final kotBytes = await PDFService.generateKOT(
        items: items,
        tableId: items.first.tableId,
        tableName: items.first.tableName,
        orderNumber: _kotOrderNumber!,
        orderTime: DateTime.now(),
      );

      Navigator.of(context).pop();
      _showSendKitchenOptions(kotBytes);
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending to kitchen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSendKitchenOptions(dynamic kotBytes) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Send Order #$_kotOrderNumber to Kitchen'),
            content: const Text('Choose how to send the KOT to kitchen:'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendViaWhatsApp(kotBytes);
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
                  Navigator.of(context).pop();
                  _printKOT(kotBytes);
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
                  Navigator.of(context).pop();
                  _shareKOT(kotBytes);
                },
                child: const Text('Share'),
              ),
            ],
          ),
    );
  }

  Future<void> _sendViaWhatsApp(dynamic kotBytes) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$_kotOrderNumber');
      final whatsappMessage =
          "New order from restaurant! Please check the KOT.";
      final whatsappUrl =
          "https://wa.me/+918768412832?text=${Uri.encodeComponent(whatsappMessage)}";

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT #$_kotOrderNumber sent via WhatsApp!'),
          backgroundColor: Colors.green,
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

  Future<void> _printKOT(dynamic kotBytes) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$_kotOrderNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT #$_kotOrderNumber ready to print!'),
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

  Future<void> _shareKOT(dynamic kotBytes) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$_kotOrderNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KOT #$_kotOrderNumber shared!'),
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

  // Navigate to Billing Page logic here
  void _navigateToBillingPage(AnimatedCartProvider cartProvider) {
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
            (_) => BillingPage(
              orderNumber: _kotOrderNumber!,
              cartItems: cartProvider.cartItems.values.toList(),
              onBillGenerated: () {
                // This will be called after payment is completed
                cartProvider.clearCart();
                setState(() {
                  _kotGenerated = false;
                  _kotOrderNumber = null;
                });
              },
            ),
      ),
    );
  }
}
