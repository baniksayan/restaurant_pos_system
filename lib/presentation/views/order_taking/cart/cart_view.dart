import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/animated_cart_provider.dart';
import '../../../view_models/providers/menu_provider.dart';
import '../../../view_models/providers/navigation_provider.dart';
import '../../../view_models/providers/table_provider.dart';
import '../../../../data/models/order_detail_api_response_model.dart';

import '../../../../services/pdf_service.dart';
import '../../billing/billing_page.dart';
import '../../billing/widgets/generate_bill_summary_dialog.dart';
import 'widgets/cart_header.dart';
import 'widgets/cart_items_list.dart';
import 'widgets/cart_footer.dart';
import 'widgets/empty_cart_widget.dart';
import 'widgets/edit_item_dialog.dart';
import 'widgets/clear_cart_dialog.dart';
import 'widgets/gst_info_dialog.dart';
import 'widgets/kot_pdf_viewer_dialog.dart';
import 'widgets/kot_section_widget.dart';
import 'package:restaurant_pos_system/shared/widgets/images/network_image_widget.dart';
import '../../../../shared/widgets/overlays/pdf_share_bottom_sheet.dart';
import '../../../view_models/providers/order_provider.dart';
import '../../../../data/local/hive_service.dart';

import '../../../../shared/widgets/layout/skeleton_loader.dart';

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
  bool _isFooterVisible = true;
  Timer? _scrollEndTimer;

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse ||
          notification.direction == ScrollDirection.forward) {
        if (_isFooterVisible) {
          setState(() {
            _isFooterVisible = false;
          });
        }
        _scrollEndTimer?.cancel();
        _scrollEndTimer = Timer(const Duration(milliseconds: 350), () {
          if (mounted && !_isFooterVisible) {
            setState(() {
              _isFooterVisible = true;
            });
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      _scrollEndTimer?.cancel();
      _scrollEndTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted && !_isFooterVisible) {
          setState(() {
            _isFooterVisible = true;
          });
        }
      });
    }
    return false;
  }

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
        child: Consumer2<AnimatedCartProvider, TableProvider>(
          builder: (context, cartProvider, tableProvider, child) {
            if (tableProvider.isLoading) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const SkeletonLoader.rectangular(width: 140, height: 24),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                const SkeletonLoader.rectangular(
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      SkeletonLoader.rectangular(
                                        width: 140,
                                        height: 16,
                                      ),
                                      SizedBox(height: 8),
                                      SkeletonLoader.rectangular(
                                        width: 70,
                                        height: 12,
                                      ),
                                    ],
                                  ),
                                ),
                                const SkeletonLoader.rectangular(
                                  width: 80,
                                  height: 32,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

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
                  hasKotItems: hasKotItems,
                  hasNewItems: hasNewItems,
                  kotOrderNumber:
                      _kotNumbers.isNotEmpty ? _kotNumbers.join(', ') : null,
                  tableName: widget.tableName,
                  selectedLocation: widget.selectedLocation,
                  totalItems: cartProvider.totalItems,
                  hasItems: items.isNotEmpty,
                  showClearAll: hasNewItems,
                  onClearCart: () => _showClearCartDialog(cartProvider),
                  onAddMore: () => _navigateBackToMenu(cartProvider),
                ),
                if (items.isEmpty)
                  const Expanded(child: EmptyCartWidget())
                else
                  Expanded(
                    child: Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: _handleScrollNotification,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100),
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
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AnimatedSlide(
                              offset:
                                  _isFooterVisible
                                      ? Offset.zero
                                      : const Offset(0, 1.2),
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              child: AnimatedOpacity(
                                opacity: _isFooterVisible ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                child: CartFooter(
                                  subtotal: cartProvider.totalAmount,
                                  kotGenerated:
                                      hasKotItems &&
                                      !hasNewItems, // KOT generated and no new items
                                  onGenerateKOT:
                                      hasNewItems
                                          ? () => _generateKOT(cartProvider)
                                          : () {},
                                  onSendToKitchen:
                                      () => _sendToKitchen(cartProvider),
                                  onGenerateBill:
                                      cartProvider.canProceedToBilling
                                          ? () => _navigateToBillingPage(
                                            cartProvider,
                                          )
                                          : () => _showCannotBillDialog(),
                                  onShowGSTInfo: _showGSTInfoDialog,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
    final count =
        serverKotItems.length +
        kotGeneratedItems
            .where(
              (localItem) =>
                  !serverKotItems.any(
                    (serverItem) => serverItem.productId == localItem.id,
                  ),
            )
            .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: KotSectionWidget(
        backgroundColor: const Color(0xFFF5F3FF),
        headerIcon: Icons.receipt_long_rounded,
        headerTitle: 'KOT Generated Items',
        headerColor: const Color(0xFF7C3AED),
        itemCountText: '$count ${count == 1 ? 'Item' : 'Items'}',
        badgeColor: const Color(0xFF6D28D9),
        child: Column(
          children: [
            if (serverKotItems.isNotEmpty)
              _buildServerKotItemsList(serverKotItems),
            if (serverKotItems.isNotEmpty && kotGeneratedItems.isNotEmpty)
              const SizedBox(height: 12),
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
      ),
    );
  }

  // Build section for new items (editable)
  Widget _buildNewItemsSection(List<CartItem> newItems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: KotSectionWidget(
        backgroundColor: const Color(0xFFFFF7ED),
        headerIcon: Icons.dinner_dining_rounded,
        headerTitle: 'New Items (Pending KOT)',
        headerColor: const Color(0xFFEA580C),
        itemCountText:
            '${newItems.length} ${newItems.length == 1 ? 'Item' : 'Items'}',
        badgeColor: const Color(0xFFF97316),
        child: CartItemsList(items: newItems, onEditItem: _showEditItemDialog),
      ),
    );
  }

  // Build widget for server KOT items
  Widget _buildServerKotItemsList(List<OrderDetailList> serverKotItems) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: serverKotItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = serverKotItems[index];
        final unitPrice = item.itemPrice?.toDouble() ?? 0.0;
        final qty = item.productQty?.toInt() ?? 1;
        final totalPrice = unitPrice * qty;
        String imageUrl = item.imageThumbUrl ?? item.imageUrl ?? '';
        if (imageUrl.isEmpty && item.productId != null) {
          final menuProvider = Provider.of<MenuProvider>(
            context,
            listen: false,
          );
          imageUrl = menuProvider.getImageUrlForProduct(item.productId!) ?? '';
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: NetworkImageWidget(
                  imageUrl: imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Unknown Item',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6D28D9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'KOT #${item.kotNo ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.instruction != null &&
                        item.instruction!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Note: ${item.instruction}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildValueColumn(
                              value:
                                  '${CurrencyConstants.symbol}${unitPrice.toStringAsFixed(2)}',
                              label: 'Unit Price',
                              valueColor: const Color(0xFF1E293B),
                            ),
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildValueColumn(
                              value: '$qty',
                              label: 'Quantity',
                              valueColor: const Color(0xFF6D28D9),
                            ),
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: _buildValueColumn(
                              value:
                                  '${CurrencyConstants.symbol}${totalPrice.toStringAsFixed(2)}',
                              label: 'Total',
                              valueColor: const Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValueColumn({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
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
      barrierColor: Colors.transparent,
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
    ClearCartDialog.show(
      context,
      onConfirm:
          cartProvider.kotGeneratedItems.isNotEmpty ||
                  cartProvider.serverKotItems.isNotEmpty
              ? cartProvider.clearNewItems
              : cartProvider.clearCart,
    );
  }

  void _showGSTInfoDialog() {
    GSTInfoDialog.show(context);
  }

  void _navigateBackToMenu(AnimatedCartProvider cartProvider) {
    if (HiveService.getCompanySiteUrl() == 'Menu') {
      Navigator.pop(context);
      return;
    }
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
            (_) => _PremiumLoaderDialog(
              message: 'Generating KOT for ${newItems.length} new items...',
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
        outletId:
            HiveService.getOutletId() ??
            0, // No fallback - validation will catch this
        orderId: backendOrderId,
        kotNote: "",
        cartItems: newItemsData,
      );

      Navigator.of(context).pop();

      if (kotResponse != null && kotResponse.isSuccess == true) {
        // Get KOT details from response
        final kotDetail = kotResponse.data?.kotDetail;
        final orderNumber =
            kotDetail?.orderNo ??
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
            (_) => const _PremiumLoaderDialog(
              message: 'Sending KOTs to Kitchen...',
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
    if (kotBytes is Uint8List) {
      PDFShareBottomSheet.show(
        context,
        pdfBytes: kotBytes,
        fileName: 'KOT_$kotNumber.pdf',
        orderNumber: kotNumber,
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

    // Show Generate Bill Summary Glassmorphic Modal Popup (No full page navigation!)
    GenerateBillSummaryDialog.show(
      context,
      orderNumber: orderNumber,
      cartItems: cartProvider.cartItems.values.toList(),
      tableId: widget.tableId,
      orderId: orderId,
      onBillGenerated: () {
        // This will be called after payment is completed
        cartProvider.clearCart();
        setState(() {
          _kotNumbers.clear();
        });
        // Clear the active ordering session and go back to Tables dashboard
        final navProvider = Provider.of<NavigationProvider>(
          context,
          listen: false,
        );
        navProvider.clearTableSelection();
        navProvider.navigateToTables();
      },
    );
  }
}

class _PremiumLoaderDialog extends StatefulWidget {
  final String message;
  const _PremiumLoaderDialog({required this.message});

  @override
  State<_PremiumLoaderDialog> createState() => _PremiumLoaderDialogState();
}

class _PremiumLoaderDialogState extends State<_PremiumLoaderDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rotating hourglass icon
              RotationTransition(
                turns: _controller,
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
