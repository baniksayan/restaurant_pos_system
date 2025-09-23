import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/animated_cart_provider.dart';
import '../../../view_models/providers/navigation_provider.dart';
import '../../../view_models/providers/table_provider.dart';
import '../../../../data/models/order_detail_api_response_model.dart';

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
import 'widgets/kot_pdf_viewer_dialog.dart';
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
  Set<String> _kotNumbers =
      {}; // Track all KOT numbers generated for this table

  @override
  void initState() {
    super.initState();
    // Switch to current table's cart when entering cart view and sync with server
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _switchToCurrentTable();
    });
  }

  @override
  void didUpdateWidget(CartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switch to new table if table ID changed
    if (oldWidget.tableId != widget.tableId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _switchToCurrentTable();
      });
    }
  }

  Future<void> _switchToCurrentTable() async {
    if (widget.tableId != null && widget.tableName != null) {
      final cartProvider = Provider.of<AnimatedCartProvider>(
        context,
        listen: false,
      );
      debugPrint('[CartView] Switching to table ${widget.tableId}');

      cartProvider.switchToTable(widget.tableId!);

      debugPrint('[CartView] Cart switched to table ${widget.tableId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<AnimatedCartProvider>(
          builder: (context, cartProvider, child) {
            final items = cartProvider.cartItems.values.toList();
            final newItems = cartProvider.newItems.values.toList();
            final kotGeneratedItems =
                cartProvider.kotGeneratedItems.values.toList();
            final serverKotItems = cartProvider.serverKotItems;
            final hasLocalKotItems = kotGeneratedItems.isNotEmpty;
            final hasServerKotItems = serverKotItems.isNotEmpty;
            final hasKotItems = hasLocalKotItems || hasServerKotItems;
            final hasNewItems = newItems.isNotEmpty;

            return Column(
              children: [
                CartHeader(
                  kotGenerated: hasKotItems,
                  kotOrderNumber:
                      _kotNumbers.isNotEmpty ? _kotNumbers.join(', ') : null,
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
                      child: Column(
                        children: [
                          // Show KOT generated items section (from both local and server)
                          if (hasKotItems)
                            _buildKotGeneratedSection(
                              kotGeneratedItems,
                              serverKotItems,
                            ),
                          // Show new items section
                          if (newItems.isNotEmpty)
                            _buildNewItemsSection(newItems),
                        ],
                      ),
                    ),
                  ),
                if (items.isNotEmpty)
                  CartFooter(
                    subtotal: cartProvider.totalAmount,
                    kotGenerated: hasKotItems && !hasNewItems, // KOT generated and no new items
                    onGenerateKOT: hasNewItems ? () => _generateKOT(cartProvider) : () {},
                    onSendToKitchen: () => _sendToKitchen(cartProvider),
                    onGenerateBill: cartProvider.canProceedToBilling
                        ? () => _navigateToBillingPage(cartProvider)
                        : () => _showCannotBillDialog(),
                    onShowGSTInfo: _showGSTInfoDialog,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Build section for KOT generated items (read-only)
  Widget _buildKotGeneratedSection(
    List<CartItem> kotGeneratedItems,
    List<OrderDetailList> serverKotItems,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kotStatus.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.kotStatus, size: 20),
                const SizedBox(width: 8),
                Text(
                  'KOT Generated Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.kotStatus.withOpacity(0.95),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.kotStatus,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${serverKotItems.length + kotGeneratedItems.where((localItem) => !serverKotItems.any((serverItem) => serverItem.productId == localItem.id)).length} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show server KOT items (authoritative source to prevent duplicates)
          if (serverKotItems.isNotEmpty)
            _buildServerKotItemsList(serverKotItems),
          // Show any local-only KOT items that aren't in server yet (should be rare)
          if (kotGeneratedItems.isNotEmpty)
            CartItemsList(
              items:
                  kotGeneratedItems
                      .where(
                        (localItem) =>
                            !serverKotItems.any(
                              (serverItem) =>
                                  serverItem.productId == localItem.id,
                            ),
                      )
                      .toList(),
              onEditItem: (item) => _showKotItemInfo(item),
            ),
        ],
      ),
    );
  }

  // Build section for new items (editable)
  Widget _buildNewItemsSection(List<CartItem> newItems) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'New Items (Pending KOT)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${newItems.length} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CartItemsList(items: newItems, onEditItem: _showEditItemDialog),
        ],
      ),
    );
  }

  // Build widget for server KOT items
  Widget _buildServerKotItemsList(List<OrderDetailList> serverKotItems) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: serverKotItems.length,
      itemBuilder: (context, index) {
        final item = serverKotItems[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.kotStatus.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.kotStatus.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Unknown Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Qty: ${item.productQty?.toInt() ?? 0}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Price: ₹${item.itemPrice?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (item.instruction != null &&
                        item.instruction!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Note: ${item.instruction}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kotStatus,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'KOT: ${item.kotNo ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.totPrice?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.kotStatus,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditItemDialog(CartItem item) {
    // Only allow editing if item is not KOT'd
    if (!item.canEdit) {
      _showKotItemInfo(item);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
  }

  void _showKotItemInfo(CartItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.kotStatus),
                const SizedBox(width: 8),
                const Text('KOT Generated'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${item.name}'),
                Text('Quantity: ${item.quantity}'),
                if (item.kotNumber != null) Text('KOT #: ${item.kotNumber}'),
                if (item.kotGeneratedAt != null)
                  Text(
                    'Generated: ${item.kotGeneratedAt!.toString().substring(0, 16)}',
                  ),
                const SizedBox(height: 16),
                const Text(
                  'This item has been sent to kitchen and cannot be modified.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showCannotBillDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Cannot Generate Bill'),
              ],
            ),
            content: const Text(
              'All items must have KOT generated before proceeding to billing. Please generate KOT for pending items first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
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
      // Removed green SnackBar per request: navigated back to menu message
    }
  }

  // KOT Generation for new items only
  Future<void> _generateKOT(AnimatedCartProvider cartProvider) async {
    try {
      final newItems = cartProvider.newItems.values.toList();

      if (newItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new items to generate KOT for'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

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
                  Text('Generating KOT for ${newItems.length} new items...'),
                ],
              ),
            ),
      );

      final orderProvider = context.read<OrderProvider>();
      final tableProvider = context.read<TableProvider>();

      // Use the actual orderId from backend
      // For table orders: get from TableProvider (created during table selection)
      // For Phone/Takeaway orders: get from OrderProvider (created during phone/takeaway order)
      String? backendOrderId = tableProvider.currentOrderId;

      // If no table order ID, check for Phone/Takeaway order ID
      if (backendOrderId == null) {
        backendOrderId = orderProvider.createdOrderId;
      }

      if (backendOrderId == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: No order ID found. Please create an order first.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (kDebugMode) {
        print('=== New Items KOT Generation ===');
        print('Using backend order ID: $backendOrderId');
        print('OrderProvider createdOrderId: ${orderProvider.createdOrderId}');
        print('TableProvider currentOrderId: ${tableProvider.currentOrderId}');
        print('Generated Order No: ${orderProvider.generatedOrderNo}');
        print('Order No: ${orderProvider.orderNo}');
        print('New items count: ${newItems.length}');
        print('Table ID: ${newItems.first.tableId}');
        print('User ID: ${HiveService.getUserId()}');
        print('Outlet ID: ${HiveService.getOutletId()}');
        print('================================');
      }

      // Convert ONLY new items to match Postman format exactly
      final newItemsData =
          newItems.map((item) {
            return <String, dynamic>{
              'id': item.id,
              'name': item.name,
              'categoryId': item.categoryId ?? '',
              'categoryName': item.categoryName ?? '',
              'price': item.price,
              'quantity': item.quantity,
              'specialNotes': item.specialNotes ?? '',
              'discountPercentage': item.discountPercentage ?? 0,
              'uom': item.uom ?? 'Plate',
            };
          }).toList();

      if (kDebugMode) {
        print('=== New Items Data for KOT ===');
        print('Items count: ${newItemsData.length}');
        print('Sample item structure (should match Postman):');
        if (newItemsData.isNotEmpty) {
          print(newItemsData.first);
        }
        print('Full data: $newItemsData');
        print('===============================');
      }

      // Use the proper order map format from AnimatedCartProvider
      final kotPayload = cartProvider.buildNewItemsOrderMap(
        orderId: backendOrderId,
        kotNote: "",
      );

      if (kDebugMode) {
        print('KOT Payload: $kotPayload');
      }

      // Use the existing order ID from backend (table selection)
      final kotResponse = await orderProvider.createKotWithOrderDetails(
        userId: HiveService.getUserId() ?? "",
        outletId: HiveService.getOutletId() ?? 1,
        orderId: backendOrderId,
        kotNote: "",
        cartItems: newItemsData,
      );

      Navigator.of(context).pop();

      if (kotResponse != null && kotResponse.isSuccess == true) {
        // Get KOT details from response
        final kotDetail = kotResponse.data?.kotDetail;
        final orderNumber = kotDetail?.orderNo ??
            orderProvider.generatedOrderNo ??
            orderProvider.orderNo?.toString() ??
            kotDetail?.kotNo ??
            PDFService.generateOrderNumber();

        // Mark the new items as KOT generated
        final newItemCartKeys = cartProvider.newItems.keys.toList();
        cartProvider.markItemsAsKotGenerated(newItemCartKeys, orderNumber);

        // Update table status to KOT Generated (for table orders only)
        if (widget.tableId != null &&
            !['PhoneOrder', 'Takeaway'].contains(widget.tableId)) {
          final tableProvider = context.read<TableProvider>();
          tableProvider.updateTableStatus(widget.tableId!, 'kotGenerated');
          await tableProvider.refreshTables();
        }

        if (widget.tableId != null) {
          cartProvider.switchToTable(widget.tableId!);
        }

        setState(() {
          _kotNumbers.add(orderNumber);
        });

        // Generate PDF KOT for the new items only, all fields dynamic from API
        final kotBytes = await PDFService.generateKOT(
          items: newItems,
          tableId: kotDetail?.orderId ?? newItems.first.tableId,
          tableName: kotDetail?.channelName ?? newItems.first.tableName,
          orderNumber: kotDetail?.orderNo ?? orderNumber,
          orderTime: DateTime.now(),
          kotNo: kotDetail?.kotNo ?? orderNumber,
          waiterName: kotDetail?.waiterName ?? 'Unknown',
        );

        // Show KOT PDF viewer dialog (undismissible)
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, // Make it undismissible
            builder:
                (context) => KOTPDFViewerDialog(
                  pdfBytes: kotBytes,
                  kotNumber: orderNumber,
                  fileName: 'KOT_$orderNumber.pdf',
                ),
          );
        }

        // Also show a brief success message
        // Removed green SnackBar per request: KOT generation success message
      } else {
        // Enhanced error handling with backend context
        String errorMessage = 'Backend server error (HTTP 500)';
        String detailedMessage =
            'The server encountered an internal error while processing the KOT request.';

        if (kotResponse != null) {
          if (kotResponse.message != null && kotResponse.message!.isNotEmpty) {
            errorMessage = kotResponse.message!;
          } else if (kotResponse.data?.response != null &&
              kotResponse.data!.response!.isNotEmpty) {
            errorMessage = kotResponse.data!.response!;
          }

          if (kotResponse.statusCode != null) {
            detailedMessage =
                'Server returned status code: ${kotResponse.statusCode}';
            if (kotResponse.statusCode == 500) {
              detailedMessage +=
                  '\n\nThis suggests a backend database or logic issue. The order ID and items are valid, but the server cannot process the KOT creation.';
            }
          }

          if (kDebugMode) {
            print('=== KOT Creation Failed ===');
            print('Status Code: ${kotResponse.statusCode}');
            print('Is Success: ${kotResponse.isSuccess}');
            print('Message: ${kotResponse.message}');
            print('Data Response: ${kotResponse.data?.response}');
            print('Full Response: ${kotResponse.toJson()}');
            print('Order ID used: $backendOrderId');
            print('===========================');
          }
        } else {
          errorMessage = 'No response from server';
          detailedMessage =
              'The KOT creation request returned no response. This may indicate a network issue or server timeout.';
        }

        // Show detailed error dialog instead of just snackbar
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('KOT Creation Failed'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error: $errorMessage',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(detailedMessage),
                    const SizedBox(height: 12),
                    const Text(
                      'Possible Solutions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '• Try generating the KOT again in a few moments',
                    ),
                    const Text('• Check if the items are still in your cart'),
                    const Text('• Contact support if the issue persists'),
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Debug Info:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Order ID: $backendOrderId'),
                      Text('Items Count: ${newItems.length}'),
                      Text('User ID: ${HiveService.getUserId()}'),
                      Text('Outlet ID: ${HiveService.getOutletId()}'),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Retry KOT generation
                      _generateKOT(cartProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
        );
      }
    } catch (e, stackTrace) {
      Navigator.of(context).pop();

      if (kDebugMode) {
        print('Exception during KOT generation: $e');
        print('Stack trace: $stackTrace');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating KOT: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Send to Kitchen logic here
  Future<void> _sendToKitchen(AnimatedCartProvider cartProvider) async {
    final kotGeneratedItems = cartProvider.kotGeneratedItems.values.toList();
    if (kotGeneratedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate KOT first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Get the latest KOT number (most recently generated)
      final latestKotNumber =
          _kotNumbers.isNotEmpty ? _kotNumbers.last : 'Unknown';

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
                  Text('Sending KOTs to Kitchen...'),
                ],
              ),
            ),
      );

      // Generate combined KOT for all KOT'd items
      final kotBytes = await PDFService.generateKOT(
        items: kotGeneratedItems,
        tableId: kotGeneratedItems.first.tableId,
        tableName: kotGeneratedItems.first.tableName,
        orderNumber: latestKotNumber,
        orderTime: DateTime.now(),
        kotNo: latestKotNumber,
        waiterName: 'Unknown', // If you have waiterName, pass it here
      );

      Navigator.of(context).pop();
      _showSendKitchenOptions(kotBytes, latestKotNumber);
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

  void _showSendKitchenOptions(dynamic kotBytes, String kotNumber) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Send KOT #$kotNumber to Kitchen'),
            content: const Text('Choose how to send the KOT to kitchen:'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendViaWhatsApp(kotBytes, kotNumber);
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
                  _printKOT(kotBytes, kotNumber);
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
                  _shareKOT(kotBytes, kotNumber);
                },
                child: const Text('Share'),
              ),
            ],
          ),
    );
  }

  Future<void> _sendViaWhatsApp(dynamic kotBytes, String kotNumber) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$kotNumber');
      final whatsappMessage =
          "New order from restaurant! Please check KOT #$kotNumber.";
      final whatsappUrl =
          "https://wa.me/+918768412832?text=${Uri.encodeComponent(whatsappMessage)}";

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      }

      // Removed green SnackBar per request: KOT sent via WhatsApp
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending via WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printKOT(dynamic kotBytes, String kotNumber) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$kotNumber');
      // Print ready message (no green snackbar). Kept as implicit UX behavior.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareKOT(dynamic kotBytes, String kotNumber) async {
    try {
      await PDFService.sharePDF(kotBytes, 'KOT_$kotNumber');
      // Removed green SnackBar per request: KOT shared
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
    // Check if all items have been KOT'd
    if (!cartProvider.canProceedToBilling) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All items must have KOT generated before billing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use the first KOT number for billing reference
    final orderNumber = _kotNumbers.isNotEmpty ? _kotNumbers.first : 'Unknown';

    // Get orderId from table provider or order provider based on context
    String? orderId;
    if (widget.tableId != null) {
      // For table orders, get from TableProvider
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      orderId = tableProvider.currentOrderId;
    } else {
      // For phone/takeaway orders, get from OrderProvider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderId = orderProvider.createdOrderId;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BillingPage(
              orderNumber: orderNumber,
              cartItems: cartProvider.cartItems.values.toList(),
              tableId: widget.tableId,
              orderId: orderId, // Pass the orderId
              onBillGenerated: () {
                // This will be called after payment is completed
                cartProvider.clearCart();
                setState(() {
                  _kotNumbers.clear();
                });
              },
            ),
      ),
    );
  }
}
