import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import '../providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/data/models/order_detail_api_response_model.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';

import 'package:restaurant_pos_system/shared/services/pdf_service.dart';
import 'package:restaurant_pos_system/features/billing/widgets/generate_bill_summary_dialog.dart';
import 'package:restaurant_pos_system/features/billing/providers/billing_provider.dart';
import 'package:restaurant_pos_system/features/billing/providers/tax_provider.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import '../widgets/cart_header.dart';
import '../widgets/cart_items_list.dart';
import '../widgets/cart_footer.dart';
import '../widgets/empty_cart_widget.dart';
import '../widgets/edit_item_dialog.dart';
import '../widgets/clear_cart_dialog.dart';
import '../widgets/gst_info_dialog.dart';
import '../widgets/kot_pdf_viewer_dialog.dart';
import '../widgets/kot_section_widget.dart';
import '../widgets/kitchen_note_dialog.dart';
import 'package:restaurant_pos_system/shared/widgets/overlays/pdf_share_bottom_sheet.dart';
import '../providers/order_provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

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
  final Set<String> _kotNumbers =
      {}; // Track all KOT numbers generated for this table
  final Map<String, String> _kotNotes =
      {}; // Track whole-KOT kitchen notes by KOT number
  String? _orderNumber; // Backend order number (e.g. OD/UR/...)
  String _currentKotNote = '';

  /// Guards against a second KOT submission while one is still running — a
  /// double tap would otherwise send the same items to the kitchen twice.
  bool _kotInFlight = false;

  /// True only for a real seated table — Phone/Takeaway carts pass their
  /// order type ('PhoneOrder' / 'Takeaway') through the same `tableId` slot
  /// as a sentinel, so `widget.tableId != null` alone can't tell them apart
  /// from a table order (see main_navigation.dart's CartView construction).
  bool get _isTableOrder =>
      widget.tableId != null &&
      !['PhoneOrder', 'Takeaway'].contains(widget.tableId);

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

      cartProvider.switchToOrder(
        context.read<TableProvider>().currentOrderId,
        tableId: widget.tableId!,
      );

      debugPrint('[CartView] Cart switched to table ${widget.tableId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: Consumer2<AnimatedCartProvider, TableProvider>(
          builder: (context, cartProvider, tableProvider, child) {
            final items = cartProvider.cartItems.values.toList();
            final newItems = cartProvider.newItems.values.toList();
            final kotGeneratedItems =
                cartProvider.kotGeneratedItems.values.toList();
            final serverKotItems = cartProvider.serverKotItems;
            final hasLocalKotItems = kotGeneratedItems.isNotEmpty;
            final hasServerKotItems = serverKotItems.isNotEmpty;
            final hasKotItems = hasLocalKotItems || hasServerKotItems;
            final hasNewItems = newItems.isNotEmpty;

            // Sync tracked KOT numbers and notes from cart items
            for (final item in kotGeneratedItems) {
              final kn = item.kotNumber?.trim();
              if (kn != null && kn.isNotEmpty) {
                _kotNumbers.add(kn);
                if (item.kotNote != null &&
                    item.kotNote!.trim().isNotEmpty &&
                    !_kotNotes.containsKey(kn)) {
                  _kotNotes[kn] = item.kotNote!.trim();
                }
              }
            }

            String? orderId;
            if (_isTableOrder) {
              if (widget.tableId != null) {
                final matchedTable = tableProvider.tables
                    .where(
                      (t) =>
                          t.id == widget.tableId ||
                          t.name == widget.tableName,
                    )
                    .firstOrNull;
                if (matchedTable != null &&
                    matchedTable.activeOrders.isNotEmpty) {
                  orderId = matchedTable.activeOrders.last.orderId;
                }
              }
            } else {
              final orderProvider = Provider.of<OrderProvider>(
                context,
                listen: false,
              );
              orderId = orderProvider.createdOrderId;
            }
            orderId ??= cartProvider.currentOrderId ?? _orderNumber;

            final matchedTable =
                widget.tableId != null
                    ? tableProvider.tables
                        .where(
                          (t) =>
                              t.id == widget.tableId ||
                              t.name == widget.tableName,
                        )
                        .firstOrNull
                    : null;

            final bool isBilled =
                cartProvider.isOrderBilled(orderId) ||
                (matchedTable != null &&
                    (matchedTable.status == TableStatus.billGenerated ||
                        matchedTable.billGenerated ||
                        matchedTable.activeOrders.any(
                          (o) =>
                              o.isBilled ||
                              (orderId != null &&
                                  o.orderId == orderId &&
                                  o.isBilled),
                        ))) ||
                (orderId != null &&
                    (tableProvider.getBillId(orderId) != null ||
                        HiveService.getOrderBillId(orderId) != null));

            final billingOrderNumber = _resolveOrderNumber(orderId);

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
                  showClearAll: hasNewItems && !isBilled,
                  onClearCart: () => _showClearCartDialog(cartProvider),
                  onAddMore: () => _navigateBackToMenu(cartProvider),
                ),
                if (tableProvider.isLoading)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ListView.builder(
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                SkeletonLoader.rectangular(
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                SkeletonLoader.rectangular(
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
                  )
                else if (items.isEmpty)
                  const Expanded(child: EmptyCartWidget())
                else
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 230),
                          child: Column(
                            children: [
                              // Show billed banner if already billed
                              if (isBilled) _buildBilledBanner(),

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
                        if (items.isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: CartFooter(
                              subtotal: cartProvider.totalAmount,
                              isBilled: isBilled,
                              onProceedToPayment:
                                  () => _navigateToPaymentFromCart(
                                    cartProvider,
                                    orderId,
                                    billingOrderNumber,
                                  ),
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
                              kotNote: _currentKotNote,
                              onKotNoteChanged: (note) {
                                setState(() => _currentKotNote = note);
                              },
                              onOpenKotNoteDialog: () async {
                                final note = await KitchenNoteDialog.show(
                                  context,
                                  initialNote: _currentKotNote,
                                );
                                if (note != null && mounted) {
                                  setState(() => _currentKotNote = note);
                                }
                              },
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

  String _formatKotTitle(String rawKey) {
    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) return 'KOT';

    final upper = trimmed.toUpperCase();
    if (upper.startsWith('KOT #') || upper.startsWith('KOT#')) {
      return trimmed;
    }
    if (upper.startsWith('KOT ') || upper == 'KOT') {
      return trimmed;
    }
    if (upper.startsWith('KOT')) {
      final stripped = trimmed
          .replaceFirst(RegExp(r'^KOT\s*[-#]?\s*', caseSensitive: false), '')
          .trim();
      return stripped.isNotEmpty ? 'KOT #$stripped' : trimmed;
    }
    if (trimmed.startsWith('#')) {
      return 'KOT $trimmed';
    }
    return 'KOT #$trimmed';
  }

  // Build section for KOT generated items (read-only, grouped into unified boxes per KOT)
  Widget _buildKotGeneratedSection(
    List<CartItem> kotGeneratedItems,
    List<OrderDetailList> serverKotItems,
  ) {
    final List<CartItem> displayKotItems = List<CartItem>.from(kotGeneratedItems);

    for (final serverItem in serverKotItems) {
      final alreadyInLocal = displayKotItems.any(
        (local) =>
            local.id == serverItem.productId &&
            local.quantity == (serverItem.productQty ?? 1) &&
            local.kotNumber == serverItem.kotNo,
      );
      if (!alreadyInLocal) {
        String img = serverItem.imageThumbUrl ?? serverItem.imageUrl ?? '';
        if (img.isEmpty && serverItem.productId != null) {
          final menuProvider =
              Provider.of<MenuProvider>(context, listen: false);
          img = menuProvider.getImageUrlForProduct(serverItem.productId!) ?? '';
        }
        displayKotItems.add(
          CartItem(
            id: serverItem.productId ?? serverItem.orderDetailId ?? '',
            name: serverItem.productName ?? 'Item',
            price: (serverItem.itemPrice ?? 0).toDouble(),
            quantity: serverItem.productQty?.toInt() ?? 1,
            tableId: widget.tableId ?? '',
            tableName: widget.tableName ?? '',
            imageUrl: img.isNotEmpty ? img : null,
            specialNotes: serverItem.instruction,
            isKotGenerated: true,
            kotNumber: serverItem.kotNo,
          ),
        );
      }
    }

    // Group items into separate unified boxes by the actual API KOT number
    final Map<String, List<CartItem>> kotGroups = {};
    for (final item in displayKotItems) {
      final rawKey =
          (item.kotNumber != null && item.kotNumber!.trim().isNotEmpty)
              ? item.kotNumber!.trim()
              : 'KOT';
      kotGroups.putIfAbsent(rawKey, () => []).add(item);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kotGroups.entries.map((entry) {
          final kotKey = entry.key;
          final groupItems = entry.value;
          final groupCount =
              groupItems.fold<int>(0, (sum, i) => sum + i.quantity);
          final title = _formatKotTitle(kotKey);

          // Resolve whole-KOT note for this combined box
          String? groupKotNote = _kotNotes[kotKey];
          if (groupKotNote == null || groupKotNote.isEmpty) {
            for (final it in groupItems) {
              if (it.kotNote != null && it.kotNote!.trim().isNotEmpty) {
                groupKotNote = it.kotNote!.trim();
                break;
              }
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KotSectionWidget(
              backgroundColor: const Color(0xFFF5F3FF),
              headerIcon: Icons.receipt_long_rounded,
              headerTitle: title,
              headerColor: const Color(0xFF7C3AED),
              itemCountText: '$groupCount ${groupCount == 1 ? 'Item' : 'Items'}',
              badgeColor: const Color(0xFF6D28D9),
              kotNote: groupKotNote,
              child: CartItemsList(
                items: groupItems,
                onEditItem: (item) {}, // Read-only: no popup dialog
                showKotBadge: false, // Frame header prominently shows KOT ID
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build section for new items (editable)
  Widget _buildNewItemsSection(List<CartItem> newItems) {
    final count = newItems.fold<int>(0, (sum, i) => sum + i.quantity);
    final pendingKotNote = _currentKotNote.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: KotSectionWidget(
        backgroundColor: const Color(0xFFFFF7ED),
        headerIcon: Icons.dinner_dining_rounded,
        headerTitle: 'New Items (Pending KOT)',
        headerColor: const Color(0xFFEA580C),
        itemCountText: '$count ${count == 1 ? 'Item' : 'Items'}',
        badgeColor: const Color(0xFFF97316),
        kotNote: pendingKotNote.isNotEmpty ? pendingKotNote : null,
        onEditKotNote: () async {
          final note = await KitchenNoteDialog.show(
            context,
            initialNote: _currentKotNote,
          );
          if (note != null && mounted) {
            setState(() => _currentKotNote = note);
          }
        },
        child: CartItemsList(items: newItems, onEditItem: _showEditItemDialog),
      ),
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
                const Icon(Icons.receipt_long, color: AppColors.kotStatus),
                const SizedBox(width: 8),
                Text(AppStrings.orderTaking.kotGenerated),
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
                child: const Text(AppStrings.ok),
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
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(AppStrings.orderTaking.cannotGenerateBill),
              ],
            ),
            content: const Text(
              'All items must have KOT generated before proceeding to billing. Please generate KOT for pending items first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.ok),
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
        AppSnackBar.showWarning(context, AppStrings.orderTaking.noItemsInCart);
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
  /// Sends the cart's new items to the kitchen.
  ///
  /// [isRetry] marks a second attempt after a failure. That matters because
  /// CreateKotWithOrderDetails saves the order lines and creates the KOT as
  /// two separate steps server-side with no shared transaction: a failure may
  /// leave the items already persisted. Blindly resending would insert them
  /// again, so a retry first asks the server what actually landed and, when
  /// the lines are already there, only fires the KOT.
  Future<void> _generateKOT(
    AnimatedCartProvider cartProvider, {
    bool isRetry = false,
  }) async {
    if (_kotInFlight) {
      debugPrint('[cart] KOT submission already in flight - ignoring');
      return;
    }
    _kotInFlight = true;
    try {
      final newItems = cartProvider.newItems.values.toList();

      if (newItems.isEmpty) {
        AppSnackBar.showWarning(
          context,
          AppStrings.orderTaking.noNewItemsForKot,
        );
        return;
      }

      // KOT-wise note is provided via the collapsible bar above Generate KOT.
      // Clicking Generate KOT directly generates KOT without showing a blocking popup dialog.
      final kotNote = _currentKotNote.trim();

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
      //
      // Must branch on _isTableOrder rather than fall back on null — a
      // dine-in table opened earlier in the session leaves
      // tableProvider.currentOrderId set indefinitely (nothing clears it),
      // so a null-based fallback would silently attach a Phone/Takeaway
      // order's KOT to that stale table order instead of this one.
      final String? backendOrderId =
          _isTableOrder ? tableProvider.currentOrderId : orderProvider.createdOrderId;

      if (backendOrderId == null) {
        Navigator.of(context).pop();
        AppSnackBar.showError(
          context,
          'Error: No order ID found. Please create an order first.',
        );
        return;
      }

      if (kDebugMode) {
        debugPrint('=== New Items KOT Generation ===');
        debugPrint('Using backend order ID: $backendOrderId');
        debugPrint(
          'OrderProvider createdOrderId: ${orderProvider.createdOrderId}',
        );
        debugPrint(
          'TableProvider currentOrderId: ${tableProvider.currentOrderId}',
        );
        debugPrint('Generated Order No: ${orderProvider.generatedOrderNo}');
        debugPrint('Order No: ${orderProvider.orderNo}');
        debugPrint('New items count: ${newItems.length}');
        debugPrint('Table ID: ${newItems.first.tableId}');
        debugPrint('User ID: ${HiveService.getUserId()}');
        debugPrint('Outlet ID: ${HiveService.getOutletId()}');
        debugPrint('================================');
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
        debugPrint('=== New Items Data for KOT ===');
        debugPrint('Items count: ${newItemsData.length}');
        debugPrint('Sample item structure (should match Postman):');
        if (newItemsData.isNotEmpty) {
          debugPrint(newItemsData.first.toString());
        }
        debugPrint('Full data: $newItemsData');
        debugPrint('===============================');
      }

      // Use the proper order map format from AnimatedCartProvider
      final kotPayload = cartProvider.buildNewItemsOrderMap(
        orderId: backendOrderId,
        kotNote: kotNote,
      );

      if (kDebugMode) {
        debugPrint('KOT Payload: $kotPayload');
      }

      // On a retry, find out whether the previous attempt already saved these
      // lines. If the server is holding at least as many un-KOT'd lines as we
      // are about to send, they landed — fire the KOT alone rather than
      // inserting duplicates.
      bool itemsAlreadyOnServer = false;
      if (isRetry) {
        final unKotdCount = await ApiService.countUnKotdOrderLines(
          orderId: backendOrderId,
        );
        itemsAlreadyOnServer =
            unKotdCount != null && unKotdCount >= newItemsData.length;
        debugPrint(
          '[cart] KOT retry - un-KOT\'d lines on server: $unKotdCount, '
          'sending ${newItemsData.length} -> '
          '${itemsAlreadyOnServer ? "KOT only" : "full resend"}',
        );
      }

      // Use the existing order ID from backend (table selection)
      final kotResponse =
          itemsAlreadyOnServer
              ? await ApiService.createKotWithoutBatch(
                outletId: HiveService.getOutletId() ?? 0,
                orderId: backendOrderId,
                kotNote: kotNote,
              )
              : await orderProvider.createKotWithOrderDetails(
                userId: HiveService.getUserId() ?? "",
                outletId:
                    HiveService.getOutletId() ??
                    0, // No fallback - validation will catch this
                orderId: backendOrderId,
                kotNote: kotNote,
                cartItems: newItemsData,
              );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (kotResponse != null && kotResponse.isSuccess == true) {
        // Get KOT details directly from API response
        final kotDetail = kotResponse.data?.kotDetail;
        final rawKotNo = kotDetail?.kotNo?.trim();
        final rawHeadId = kotResponse.data?.kotHeadId?.trim();
        final rawOrderNo = kotDetail?.orderNo?.trim();

        // Actual KOT number coming directly from the API response
        final String apiKotNumber = (rawKotNo != null && rawKotNo.isNotEmpty)
            ? rawKotNo
            : (rawHeadId != null && rawHeadId.isNotEmpty)
                ? rawHeadId
                : (rawOrderNo != null && rawOrderNo.isNotEmpty)
                    ? rawOrderNo
                    : 'KOT';

        // Backend order number for billing reference (must never be a KOT number)
        final rawOrderIdent = kotDetail?.orderIdentifier?.trim();
        final genOrderNo = orderProvider.generatedOrderNo?.trim();
        final numOrderNo = orderProvider.orderNo?.toString().trim();

        String? validOrderNo;
        if (rawOrderNo != null &&
            rawOrderNo.isNotEmpty &&
            !rawOrderNo.toUpperCase().contains('KT/')) {
          validOrderNo = rawOrderNo;
        } else if (rawOrderIdent != null &&
            rawOrderIdent.toUpperCase().contains('OD/')) {
          validOrderNo = rawOrderIdent;
        } else if (genOrderNo != null &&
            genOrderNo.isNotEmpty &&
            !genOrderNo.toUpperCase().contains('KT/')) {
          validOrderNo = genOrderNo;
        } else if (numOrderNo != null &&
            numOrderNo.isNotEmpty &&
            !numOrderNo.toUpperCase().contains('KT/')) {
          validOrderNo = numOrderNo;
        }

        final String orderNumber = validOrderNo ?? (rawOrderNo?.isNotEmpty == true ? rawOrderNo! : '');
        if (validOrderNo != null) {
          _orderNumber = validOrderNo;
          final targetOrderId = kotDetail?.orderId ?? backendOrderId;
          if (targetOrderId.isNotEmpty) {
            HiveService.saveOrderNo(targetOrderId, validOrderNo);
          }
        }

        // Mark the new items as KOT generated with the actual API KOT number
        final newItemCartKeys = cartProvider.newItems.keys.toList();
        cartProvider.markItemsAsKotGenerated(
          newItemCartKeys,
          apiKotNumber,
          kotNote: kotNote,
        );

        // Update table status to KOT Generated (for table orders only)
        if (widget.tableId != null &&
            !['PhoneOrder', 'Takeaway'].contains(widget.tableId)) {
          final tableProvider = context.read<TableProvider>();
          tableProvider.updateTableStatus(widget.tableId!, 'kotGenerated');
          await tableProvider.refreshTables();
          if (!mounted) return;
        }

        if (widget.tableId != null) {
          cartProvider.switchToOrder(
            backendOrderId,
            tableId: widget.tableId!,
          );
        }

        setState(() {
          _kotNumbers.add(apiKotNumber);
          if (kotNote.isNotEmpty) {
            _kotNotes[apiKotNumber] = kotNote;
            HiveService.saveKotNote(apiKotNumber, kotNote);
            if (rawHeadId != null && rawHeadId.isNotEmpty) {
              HiveService.saveKotNote(rawHeadId, kotNote);
            }
            if (orderNumber.isNotEmpty) {
              HiveService.saveKotNote(orderNumber, kotNote);
            }
          }
          _currentKotNote = '';
        });

        // Generate PDF KOT for the new items only, all fields dynamic from API
        final kotBytes = await PDFService.generateKOT(
          items: newItems,
          tableId: kotDetail?.orderId ?? newItems.first.tableId,
          tableName: kotDetail?.channelName ?? newItems.first.tableName,
          orderNumber: kotDetail?.orderNo ?? orderNumber,
          orderTime: DateTime.now(),
          kotNo: apiKotNumber,
          waiterName: kotDetail?.waiterName ?? 'Unknown',
          // The whole-ticket note collected above — it was already being
          // saved to KOTHead.KOTNote via kotNote: on the create call, but
          // never made it into this preview PDF.
          specialNotes: kotNote,
        );

        // Show KOT PDF viewer dialog
        if (mounted) {
          KOTPDFViewerDialog.show(
            context,
            pdfBytes: kotBytes,
            kotNumber: apiKotNumber,
            fileName: 'KOT_$apiKotNumber.pdf',
          );
        }

        // Also show a brief success message
        // Removed green SnackBar per request: KOT generation success message
      } else {
        if (!mounted) return;
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
            debugPrint('=== KOT Creation Failed ===');
            debugPrint('Status Code: ${kotResponse.statusCode}');
            debugPrint('Is Success: ${kotResponse.isSuccess}');
            debugPrint('Message: ${kotResponse.message}');
            debugPrint('Data Response: ${kotResponse.data?.response}');
            debugPrint('Full Response: ${kotResponse.toJson()}');
            debugPrint('Order ID used: $backendOrderId');
            debugPrint('===========================');
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
                title: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(AppStrings.orderTaking.kotCreationFailed),
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
                    Text(AppStrings.orderTaking.checkItemsInCart),
                    Text(AppStrings.orderTaking.contactSupport),
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
                    child: const Text(AppStrings.ok),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Retry, reconciling against whatever the failed attempt
                      // already persisted so items are not duplicated.
                      _generateKOT(cartProvider, isRetry: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (kDebugMode) {
        debugPrint('Exception during KOT generation: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      if (mounted) {
        AppSnackBar.showError(
          context,
          'Error generating KOT: ${e.toString()}',
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      _kotInFlight = false;
    }
  }

  // Send to Kitchen logic here
  Future<void> _sendToKitchen(AnimatedCartProvider cartProvider) async {
    final kotGeneratedItems = cartProvider.kotGeneratedItems.values.toList();
    if (kotGeneratedItems.isEmpty) {
      AppSnackBar.showWarning(
        context,
        AppStrings.orderTaking.pleaseGenerateKotFirst,
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
        orderNumber: _orderNumber ?? latestKotNumber,
        orderTime: DateTime.now(),
        kotNo: latestKotNumber,
        waiterName: 'Unknown', // If you have waiterName, pass it here
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSendKitchenOptions(kotBytes, latestKotNumber);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.showError(context, 'Error sending to kitchen: $e');
      }
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

  String _resolveOrderNumber(String? orderId) {
    // 1. Direct _orderNumber if valid (not KT/ and not Unknown)
    if (_orderNumber != null &&
        _orderNumber!.trim().isNotEmpty &&
        !_orderNumber!.toUpperCase().contains('KT/') &&
        !_orderNumber!.toLowerCase().contains('unknown')) {
      return _orderNumber!.trim();
    }

    // 2. OrderProvider generatedOrderNo or orderNo
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final genOrderNo = orderProvider.generatedOrderNo?.trim();
    if (genOrderNo != null &&
        genOrderNo.isNotEmpty &&
        !genOrderNo.toUpperCase().contains('KT/') &&
        !genOrderNo.toLowerCase().contains('unknown')) {
      return genOrderNo;
    }
    final numOrderNo = orderProvider.orderNo?.toString().trim();
    if (numOrderNo != null &&
        numOrderNo.isNotEmpty &&
        !numOrderNo.toUpperCase().contains('KT/') &&
        !numOrderNo.toLowerCase().contains('unknown')) {
      return numOrderNo;
    }

    // 3. For table orders, check TableProvider's activeOrders
    if (widget.tableId != null) {
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      final matchedTable = tableProvider.tables
          .where((t) => t.id == widget.tableId || t.name == widget.tableName)
          .firstOrNull;

      if (matchedTable != null && matchedTable.activeOrders.isNotEmpty) {
        final matchedOrder = orderId != null
            ? matchedTable.activeOrders
                .where((o) => o.orderId == orderId)
                .firstOrNull
            : null;
        final targetOrder = matchedOrder ?? matchedTable.activeOrders.first;
        if (targetOrder.generatedOrderNo.trim().isNotEmpty &&
            !targetOrder.generatedOrderNo.toUpperCase().contains('KT/') &&
            !targetOrder.generatedOrderNo.toLowerCase().contains('unknown')) {
          return targetOrder.generatedOrderNo.trim();
        }
      }
    }

    // 4. Check cached order number by orderId in Hive
    if (orderId != null && orderId.isNotEmpty) {
      final cached = HiveService.getOrderNo(orderId);
      if (cached != null &&
          cached.isNotEmpty &&
          !cached.toUpperCase().contains('KT/') &&
          !cached.toLowerCase().contains('unknown')) {
        return cached;
      }
    }

    return '';
  }

  // Navigate to Billing Page logic here
  void _navigateToBillingPage(AnimatedCartProvider cartProvider) {
    // Check if all items have been KOT'd
    if (!cartProvider.canProceedToBilling) {
      AppSnackBar.showWarning(
        context,
        AppStrings.orderTaking.allItemsMustHaveKot,
      );
      return;
    }

    // Get orderId from table provider or order provider based on context.
    // widget.tableId is non-null for Phone/Takeaway too (it carries the
    // 'PhoneOrder'/'Takeaway' sentinel there) — checking _isTableOrder
    // instead of `widget.tableId != null` is what actually tells them apart.
    String? orderId;
    if (_isTableOrder) {
      // For table orders, get from TableProvider
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      orderId = tableProvider.currentOrderId;
    } else {
      // For phone/takeaway orders, get from OrderProvider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderId = orderProvider.createdOrderId;
    }

    // Resolve proper backend order number (never KT/ or Unknown)
    final billingOrderNumber = _resolveOrderNumber(orderId);

    // Show Generate Bill Summary Glassmorphic Modal Popup (No full page navigation!)
    GenerateBillSummaryDialog.show(
      context,
      orderNumber: billingOrderNumber,
      cartItems: cartProvider.cartItems.values.toList(),
      tableId: widget.tableId,
      orderId: orderId,
      onBillGenerated: () {
        cartProvider.clearCart();
        setState(() {
          _kotNumbers.clear();
          _kotNotes.clear();
          _orderNumber = null;
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

  Widget _buildBilledBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Generated · Payment Pending',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'This order has already been billed. Kitchen orders & billing are closed. Please proceed to payment below to settle.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB45309),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPaymentFromCart(
    AnimatedCartProvider cartProvider,
    String? orderId,
    String orderNumber,
  ) {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final billingProvider =
        Provider.of<BillingProvider>(context, listen: false);

    final billId =
        (orderId != null ? tableProvider.getBillId(orderId) : null) ??
        billingProvider.billId;

    final taxProvider = Provider.of<TaxProvider>(context, listen: false);
    final totalAmount = cartProvider.totalAmount +
        taxProvider.calculateGstAmount(cartProvider.totalAmount);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentPage(
              orderId: orderId,
              orderNumber:
                  orderNumber.isNotEmpty
                      ? orderNumber
                      : (_orderNumber ?? ''),
              totalAmount: totalAmount,
              tableId: widget.tableId,
              billId: billId,
              isFinalSettlement: true,
              onPaymentCompleted: () {
                cartProvider.clearCart();
                if (orderId != null) {
                  cartProvider.clearOrderData(orderId);
                  tableProvider.clearBillId(orderId);
                }
                final navProvider = Provider.of<NavigationProvider>(
                  context,
                  listen: false,
                );
                navProvider.clearTableSelection();
                navProvider.navigateToTables();
              },
            ),
      ),
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
                color: Colors.black.withValues(alpha: 0.15),
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
