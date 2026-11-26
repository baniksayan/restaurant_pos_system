import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/guid_helper.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import 'add_party_dialog.dart';
import '../providers/table_provider.dart';
import '../providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';

/// Payment status of an active order
enum OrderPaymentStatus {
  paidInFull,
  partiallyPaid,
  pending,
}

/// Kitchen / delivery workflow status of an active order
enum OrderKitchenStatus {
  readyForDelivery,
  preparing,
  inKitchen,
  orderPlaced,
  delivered,
}

/// Dynamically fetched and computed metadata for an active order
class OrderDynamicInfo {
  final String orderId;
  final String orderNumber;
  final String customerName;
  final int totalGuests;
  final int itemCount;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String? billId;
  final bool isBilled;
  final OrderPaymentStatus paymentStatus;
  final OrderKitchenStatus kitchenStatus;
  final String kitchenStatusText;
  final List<String> itemNamesPreview;
  final bool isLoaded;

  const OrderDynamicInfo({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.totalGuests,
    required this.itemCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    this.billId,
    required this.isBilled,
    required this.paymentStatus,
    required this.kitchenStatus,
    required this.kitchenStatusText,
    this.itemNamesPreview = const [],
    this.isLoaded = false,
  });

  bool get isPaidInFull => paymentStatus == OrderPaymentStatus.paidInFull;
  bool get isPartiallyPaid => paymentStatus == OrderPaymentStatus.partiallyPaid;
  bool get isPending => paymentStatus == OrderPaymentStatus.pending;
}

class MultiOrderManagementDialog extends StatefulWidget {
  final RestaurantTable table;
  final bool enableDynamicFetch;
  final Map<String, OrderDynamicInfo>? initialDynamicData;
  final bool? isLoading;
  final bool enableShimmerAnimation;
  final Duration liveSyncInterval;

  const MultiOrderManagementDialog({
    super.key,
    required this.table,
    this.enableDynamicFetch = true,
    this.initialDynamicData,
    this.isLoading,
    this.enableShimmerAnimation = true,
    this.liveSyncInterval = const Duration(seconds: 4),
  });

  @override
  State<MultiOrderManagementDialog> createState() =>
      _MultiOrderManagementDialogState();
}

class _MultiOrderManagementDialogState
    extends State<MultiOrderManagementDialog> {
  bool _isCreatingOrder = false;
  bool _isLoadingDynamic = false;
  final Map<String, OrderDynamicInfo> _dynamicDataMap = {};
  final Set<String> _deletingOrderIds = {};
  Timer? _liveSyncTimer;
  bool _isSyncing = false;
  bool _hadActiveOrders = false;
  String _lastTableOrdersSignature = '';
  bool _isClosingFromRemoteClear = false;

  String _buildOrdersSignature(List<ActiveOrder> orders) {
    return orders
        .map(
          (o) =>
              '${o.orderId.toLowerCase().trim()}|${o.orderStatus}|${o.isBilled}|${o.billId ?? ''}|${o.kotNumber ?? ''}',
        )
        .join(';');
  }

  @override
  void initState() {
    super.initState();
    _hadActiveOrders = widget.table.hasActiveOrders;
    _lastTableOrdersSignature = _buildOrdersSignature(widget.table.activeOrders);
    if (widget.initialDynamicData != null) {
      _dynamicDataMap.addAll(widget.initialDynamicData!);
    }
    final hasInitialData = widget.initialDynamicData != null &&
        widget.initialDynamicData!.isNotEmpty;
    _isLoadingDynamic = widget.isLoading ??
        (widget.enableDynamicFetch && !hasInitialData);

    if (widget.enableDynamicFetch) {
      _loadDynamicOrdersData();
      _startLiveSyncTimer();
    }
  }

  void _startLiveSyncTimer() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = Timer.periodic(widget.liveSyncInterval, (_) {
      _syncLiveTableAndOrders();
    });
  }

  Future<void> _syncLiveTableAndOrders() async {
    if (!mounted ||
        _isSyncing ||
        _isCreatingOrder ||
        _deletingOrderIds.isNotEmpty) {
      return;
    }
    _isSyncing = true;
    try {
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      await tableProvider.refreshTables(silent: true);
      if (mounted) {
        await _loadDynamicOrdersData(silent: true);
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MultiOrderManagementDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDynamicData != null) {
      _dynamicDataMap.addAll(widget.initialDynamicData!);
    }
    if (widget.isLoading != null && widget.isLoading != oldWidget.isLoading) {
      setState(() {
        _isLoadingDynamic = widget.isLoading!;
      });
    }
    if (widget.liveSyncInterval != oldWidget.liveSyncInterval &&
        widget.enableDynamicFetch) {
      _startLiveSyncTimer();
    }
  }

  /// Dynamically load full order line details, live kitchen statuses, and payment states
  Future<void> _loadDynamicOrdersData({bool silent = false}) async {
    if (!mounted) return;

    if (!silent && _dynamicDataMap.isEmpty) {
      setState(() {
        _isLoadingDynamic = true;
      });
    }

    try {
      final token = HiveService.getAuthToken();
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      final currentTable = tableProvider.tables.firstWhere(
        (t) => GuidHelper.areEqual(t.id, widget.table.id),
        orElse: () => widget.table,
      );

      final results = await Future.wait(
        currentTable.activeOrders.map((order) async {
          try {
            // 1. Fetch live order details from API
            final orderDetails = await ApiService.getOrderDetailById(
              token: token,
              orderId: order.orderId,
            );

            String customerName =
                HiveService.getCustomerName(order.orderId) ?? 'Guest';
            int itemCount = 0;
            double itemsSum = 0.0;
            String? resolvedBillId =
                order.billId ?? HiveService.getOrderBillId(order.orderId);
            bool isActuallyBilled = order.isBilled;
            bool isActuallyPaid = false;
            final List<String> topItems = [];

            int readyCount = 0;
            int preparingCount = 0;
            int kotCount = 0;
            int servedCount = 0;
            int totalItemsInList = 0;

            if (orderDetails != null &&
                orderDetails.isSuccess == true &&
                orderDetails.data != null &&
                orderDetails.data!.isNotEmpty) {
              final headData = orderDetails.data!.first;

              if (GuidHelper.isValid(headData.billId)) {
                resolvedBillId = headData.billId;
                await HiveService.saveOrderBillId(
                  order.orderId,
                  resolvedBillId!,
                );
              }

              if (headData.isBilled == true) {
                isActuallyBilled = true;
              }
              if (headData.isPaid == true) {
                isActuallyPaid = true;
              }

              final orderDetailList = headData.orderDetailList ?? [];
              totalItemsInList = orderDetailList.length;

              for (final line in orderDetailList) {
                final qty = line.productQty ?? 1;
                itemCount += qty;

                final price =
                    line.totPrice?.toDouble() ??
                    ((line.itemPrice?.toDouble() ?? 0.0) * qty);
                itemsSum += price;

                if (line.productName != null &&
                    line.productName!.isNotEmpty &&
                    topItems.length < 3) {
                  topItems.add('${qty}x ${line.productName}');
                }

                final statusId = line.orderStatusId;
                final statusName = (line.statusSystemName ??
                        line.status ??
                        line.kotStatusName ??
                        '')
                    .toLowerCase();

                if (statusId == 3 ||
                    statusName.contains('ready') ||
                    statusName.contains('deliver')) {
                  readyCount++;
                } else if (statusId == 2 || statusName.contains('prepar')) {
                  preparingCount++;
                } else if (statusId == 5 ||
                    statusName.contains('serv') ||
                    statusName.contains('complet')) {
                  servedCount++;
                } else if (line.kotNo != null && line.kotNo!.isNotEmpty) {
                  kotCount++;
                }
              }
            }

            // 2. Resolve live kitchen / delivery status dynamically
            OrderKitchenStatus kitchenStatus;
            String kitchenStatusText;
            if (readyCount > 0) {
              kitchenStatus = OrderKitchenStatus.readyForDelivery;
              kitchenStatusText = 'Ready for Delivery';
            } else if (preparingCount > 0) {
              kitchenStatus = OrderKitchenStatus.preparing;
              kitchenStatusText = 'Preparing in Kitchen';
            } else if (kotCount > 0) {
              kitchenStatus = OrderKitchenStatus.inKitchen;
              kitchenStatusText = 'In Kitchen (KOT Sent)';
            } else if (totalItemsInList > 0 &&
                servedCount == totalItemsInList) {
              kitchenStatus = OrderKitchenStatus.delivered;
              kitchenStatusText = 'Delivered / Served';
            } else {
              kitchenStatus = OrderKitchenStatus.orderPlaced;
              kitchenStatusText = 'Order Placed';
            }

            // 3. Resolve live bill details and payments
            double billTotal = itemsSum;
            double paidAmount = 0.0;

            if (resolvedBillId != null && resolvedBillId.isNotEmpty) {
              final paid = await ApiService.getPaidAmountForBill(
                billId: resolvedBillId,
              );
              if (paid != null && paid > 0) {
                paidAmount = paid;
              }

              final billResp = await ApiService.getBillDetailByBillId(
                billId: resolvedBillId,
              );
              if (billResp != null &&
                  billResp.isSuccess &&
                  billResp.data != null) {
                final amt = billResp.data!.billHeadDt.effectivePayableAmount;
                if (amt > 0) {
                  billTotal = amt;
                }
                if (paidAmount <= 0.004 && billResp.data!.totalPaidAmount > 0) {
                  paidAmount = billResp.data!.totalPaidAmount;
                }
                final cust = billResp.data!.billHeadDt.customerName.trim();
                if (cust.isNotEmpty &&
                    cust.toLowerCase() != 'walk-in customer') {
                  customerName = cust;
                }
                if (billResp.data!.isPaidInFull) {
                  isActuallyPaid = true;
                }
              }
            }

            // 4. Resolve exact payment status directly from backend data
            OrderPaymentStatus paymentStatus;
            if (isActuallyPaid ||
                HiveService.isOrderSettled(order.orderId) ||
                (billTotal > 0.004 && paidAmount >= (billTotal - 0.004))) {
              paymentStatus = OrderPaymentStatus.paidInFull;
            } else if (paidAmount > 0.004) {
              paymentStatus = OrderPaymentStatus.partiallyPaid;
            } else {
              paymentStatus = OrderPaymentStatus.pending;
            }

            final balanceAmount =
                (billTotal - paidAmount) > 0 ? (billTotal - paidAmount) : 0.0;

            return MapEntry(
              order.orderId,
              OrderDynamicInfo(
                orderId: order.orderId,
                orderNumber: order.generatedOrderNo,
                customerName: customerName,
                totalGuests: order.guestCount ?? 1,
                itemCount: itemCount,
                totalAmount: billTotal,
                paidAmount: paidAmount,
                balanceAmount: balanceAmount,
                billId: resolvedBillId,
                isBilled: isActuallyBilled,
                paymentStatus: paymentStatus,
                kitchenStatus: kitchenStatus,
                kitchenStatusText: kitchenStatusText,
                itemNamesPreview: topItems,
                isLoaded: true,
              ),
            );
          } catch (e) {
            debugPrint(
              '[MultiOrderDialog] Error loading dynamic order ${order.orderId}: $e',
            );
            return MapEntry(
              order.orderId,
              OrderDynamicInfo(
                orderId: order.orderId,
                orderNumber: order.generatedOrderNo,
                customerName: 'Guest',
                totalGuests: order.guestCount ?? 1,
                itemCount: 0,
                totalAmount: 0.0,
                paidAmount: 0.0,
                balanceAmount: 0.0,
                isBilled: order.isBilled,
                paymentStatus: order.isBilled
                    ? OrderPaymentStatus.pending
                    : OrderPaymentStatus.pending,
                kitchenStatus: OrderKitchenStatus.orderPlaced,
                kitchenStatusText: order.orderStatus.isNotEmpty
                    ? order.orderStatus
                    : 'Order Placed',
                isLoaded: true,
              ),
            );
          }
        }),
      );

      if (mounted) {
        final latestTable = tableProvider.tables.firstWhere(
          (t) => GuidHelper.areEqual(t.id, widget.table.id),
          orElse: () => currentTable,
        );
        final latestActiveIds = latestTable.activeOrders
            .map((o) => o.orderId.toLowerCase().trim())
            .toSet();
        setState(() {
          for (final entry in results) {
            if (latestActiveIds.contains(entry.key.toLowerCase().trim())) {
              _dynamicDataMap[entry.key] = entry.value;
            }
          }
          _dynamicDataMap.removeWhere(
            (orderId, _) =>
                !latestActiveIds.contains(orderId.toLowerCase().trim()),
          );
        });
      }
    } catch (e) {
      debugPrint('[MultiOrderDialog] Error loading dynamic orders data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDynamic = widget.isLoading ?? false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        final currentTable = tableProvider.tables.firstWhere(
          (t) => GuidHelper.areEqual(t.id, widget.table.id),
          orElse: () => widget.table,
        );

        if (currentTable.hasActiveOrders) {
          _hadActiveOrders = true;
        }

        final activeIds = currentTable.activeOrders
            .map((o) => o.orderId.toLowerCase().trim())
            .toSet();
        _dynamicDataMap.removeWhere(
          (orderId, _) => !activeIds.contains(orderId.toLowerCase().trim()),
        );

        final currentSig = _buildOrdersSignature(currentTable.activeOrders);
        if (currentSig != _lastTableOrdersSignature) {
          _lastTableOrdersSignature = currentSig;
          if (widget.enableDynamicFetch && currentTable.hasActiveOrders) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadDynamicOrdersData(silent: true);
              }
            });
          }
        }

        final bool isReservedOnly = !currentTable.hasActiveOrders &&
            currentTable.status == TableStatus.occupied;
        if (_hadActiveOrders &&
            !currentTable.hasActiveOrders &&
            !isReservedOnly &&
            !_isClosingFromRemoteClear &&
            _deletingOrderIds.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _isClosingFromRemoteClear) return;
            final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
            if (isCurrent && Navigator.of(context).canPop()) {
              _isClosingFromRemoteClear = true;
              Navigator.of(context).pop();
            }
          });
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent taps inside popup from closing
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.94,
                        constraints: BoxConstraints(
                          maxWidth: 520,
                          maxHeight: MediaQuery.of(context).size.height *
                              (MediaQuery.of(context).orientation ==
                                      Orientation.landscape
                                  ? 0.92
                                  : 0.82),
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(context, currentTable, isDark),
                            Flexible(
                              child: _buildContent(
                                context,
                                currentTable,
                                tableProvider,
                                isDark,
                              ),
                            ),
                            _buildFooter(
                              context,
                              currentTable,
                              tableProvider,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RestaurantTable table,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Table Badge Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.table_restaurant_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // Title & Table Meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Active Orders',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFC7D2FE),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        table.name,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Capacity: ${table.capacity} guests  •  ${table.orderCount} active ${table.orderCount == 1 ? "order" : "orders"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Close X button
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildContent(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
    bool isDark,
  ) {
    // Scenario: Table is marked reserved and has no active orders
    final isReservedNoOrder =
        (table.status == TableStatus.reserved || table.reservationInfo != null) &&
        !table.hasActiveOrders;

    if (isReservedNoOrder) {
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(10),
        children: [
          _buildReservedTableCard(context, table, tableProvider, isDark),
        ],
      );
    }

    if (!table.hasActiveOrders) {
      return _buildNoActiveOrders(isDark);
    }

    if (_isLoadingDynamic) {
      return _buildSkeletonOrdersView(context, table, isDark);
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(10),
      itemCount: table.activeOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = table.activeOrders[index];
        final dynamicInfo = _dynamicDataMap[order.orderId];
        return _buildEnhancedOrderCard(
          context,
          table,
          order,
          dynamicInfo,
          index,
          tableProvider,
          isDark,
        );
      },
    );
  }

  Widget _buildSkeletonOrdersView(
    BuildContext context,
    RestaurantTable table,
    bool isDark,
  ) {
    final count = table.activeOrders.isNotEmpty
        ? table.activeOrders.length
        : (table.orderCount > 0 ? table.orderCount : 2);

    final baseColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF475569) : const Color(0xFFFFFFFF);
    final boneColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Shimmer(
      enabled: widget.enableShimmerAnimation,
      duration: const Duration(milliseconds: 1400),
      gradient: LinearGradient(
        colors: [
          baseColor,
          Color.lerp(baseColor, highlightColor, 0.4) ?? baseColor,
          highlightColor,
          Color.lerp(baseColor, highlightColor, 0.4) ?? baseColor,
          baseColor,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        tileMode: TileMode.clamp,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(10),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _buildOrderCardSkeleton(
            index: index,
            isDark: isDark,
            boneColor: boneColor,
          );
        },
      ),
    );
  }

  Widget _buildOrderCardSkeleton({
    required int index,
    required bool isDark,
    required Color boneColor,
  }) {
    // Alternates between KOT style (index 0) and Bill Generated / Partially Paid style (index 1)
    final isBilledStyle = index % 2 == 1;

    final accentColor = isBilledStyle
        ? (isDark
            ? const Color(0xFFD97706).withValues(alpha: 0.6)
            : const Color(0xFFFDE68A))
        : (isDark
            ? const Color(0xFF059669).withValues(alpha: 0.6)
            : const Color(0xFFA7F3D0));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ShimmerLoading(
        child: Stack(
          children: [
            // Left accent indicator stripe
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 3.5,
              child: Container(color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Order ID bone + Badges bones
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShimmerBone.rectangular(
                        width: isBilledStyle ? 130 : 140,
                        height: 16,
                        color: boneColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const Spacer(),
                      ShimmerBone.pill(
                        width: isBilledStyle ? 88 : 94,
                        height: 20,
                        color: boneColor,
                      ),
                      const SizedBox(width: 5),
                      ShimmerBone.pill(
                        width: isBilledStyle ? 80 : 72,
                        height: 20,
                        color: boneColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Row 2: Guests & Items meta bones
                  Row(
                    children: [
                      ShimmerBone.circular(
                        size: 13,
                        color: boneColor,
                      ),
                      const SizedBox(width: 4),
                      ShimmerBone.rectangular(
                        width: 52,
                        height: 11,
                        color: boneColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      Container(
                        height: 10,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFCBD5E1),
                      ),
                      ShimmerBone.circular(
                        size: 13,
                        color: boneColor,
                      ),
                      const SizedBox(width: 4),
                      ShimmerBone.rectangular(
                        width: 46,
                        height: 11,
                        color: boneColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),

                  if (isBilledStyle) ...[
                    const SizedBox(height: 7),
                    // 3-Column financial summary box skeleton
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF1F5F9),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShimmerBone.rectangular(
                                width: 50,
                                height: 9,
                                color: boneColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(height: 4),
                              ShimmerBone.rectangular(
                                width: 58,
                                height: 13,
                                color: boneColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShimmerBone.rectangular(
                                width: 36,
                                height: 9,
                                color: boneColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(height: 4),
                              ShimmerBone.rectangular(
                                width: 50,
                                height: 13,
                                color: boneColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShimmerBone.rectangular(
                                width: 52,
                                height: 9,
                                color: boneColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              const SizedBox(height: 4),
                              ShimmerBone.rectangular(
                                width: 54,
                                height: 13,
                                color: boneColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Reminder banner bone
                    ShimmerBone.rectangular(
                      width: double.infinity,
                      height: 22,
                      color: boneColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    // Action row: delete icon + collect payment button bones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ShimmerBone.rectangular(
                          width: 32,
                          height: 30,
                          color: boneColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 8),
                        ShimmerBone.rectangular(
                          width: 118,
                          height: 30,
                          color: boneColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    // KOT Action row: Amount on left, Delete + Open Cart on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ShimmerBone.rectangular(
                          width: 65,
                          height: 18,
                          color: boneColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShimmerBone.rectangular(
                              width: 32,
                              height: 30,
                              color: boneColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 8),
                            ShimmerBone.rectangular(
                              width: 95,
                              height: 30,
                              color: boneColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReservationDateTime(ReservationInfo? info) {
    if (info != null) {
      final date = info.reservationDate;
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthStr = (date.month >= 1 && date.month <= 12)
          ? months[date.month - 1]
          : '';
      final timeStr = info.startTime.isNotEmpty ? info.startTime : '';
      if (timeStr.isNotEmpty) {
        return '${date.day} $monthStr, $timeStr';
      }
      return '${date.day} $monthStr';
    }
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthStr = months[now.month - 1];
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '${now.day} $monthStr, $hour:$minute $ampm';
  }

  Widget _buildReservedTableCard(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
    bool isDark,
  ) {
    final info = table.reservationInfo;
    final guestCount = info?.guestCount ?? table.capacity;
    final formattedTime = _formatReservationDateTime(info);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left blue accent indicator
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 3.5,
            child: Container(color: const Color(0xFF3B82F6)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Table Name & Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          table.name,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBadge(
                          label: 'Reserved',
                          icon: Icons.calendar_today_outlined,
                          bg: const Color(0xFFEFF6FF),
                          border: const Color(0xFFBFDBFE),
                          text: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 5),
                        _buildBadge(
                          label: 'Awaiting Order',
                          icon: Icons.access_time_rounded,
                          bg: const Color(0xFFF8FAFC),
                          border: const Color(0xFFE2E8F0),
                          text: const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 2: Guest count
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$guestCount ${guestCount == 1 ? "Guest" : "Guests"}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 3: Reserved At Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                        : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                          : const Color(0xFFDBEAFE),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reserved At: $formattedTime',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Row 4: Bottom Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                    _buildPrimaryButton(
                      icon: Icons.menu_book_rounded,
                      label: 'Open Menu',
                      onPressed: () => _handleOpenMenuForTable(context, table, tableProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOrderCard(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    OrderDynamicInfo? dynamicInfo,
    int index,
    TableProvider tableProvider,
    bool isDark,
  ) {
    final String orderNo = dynamicInfo?.orderNumber ?? order.generatedOrderNo;
    final int guestCount = dynamicInfo?.totalGuests ?? (order.guestCount ?? 1);
    final int itemCount = dynamicInfo?.itemCount ?? 0;
    final double totalAmount = dynamicInfo?.totalAmount ?? 0.0;
    final double paidAmount = dynamicInfo?.paidAmount ?? 0.0;
    final double balanceAmount = dynamicInfo?.balanceAmount ??
        (totalAmount - paidAmount > 0 ? totalAmount - paidAmount : 0.0);

    final bool isBilled = order.isBilled || (dynamicInfo?.isBilled ?? false);
    final bool isSettledInHive = HiveService.isOrderSettled(order.orderId);
    final bool isPaidInFull = (dynamicInfo?.isPaidInFull ?? false) ||
        isSettledInHive ||
        (isBilled && totalAmount > 0.004 && paidAmount >= (totalAmount - 0.004));
    final bool isPartiallyPaid = isBilled && !isPaidInFull && paidAmount > 0.004;
    final bool isUnpaid = isBilled && !isPaidInFull && !isPartiallyPaid;

    // A newly created order before items/KOT is in Awaiting Order state!
    final bool hasKotGenerated = order.hasKotGenerated ||
        (dynamicInfo != null &&
            dynamicInfo.kitchenStatus != OrderKitchenStatus.orderPlaced) ||
        itemCount > 0;
    final bool isAwaitingOrder = !isBilled && !hasKotGenerated;

    // Left border indicator accent color
    final Color accentColor;
    if (isAwaitingOrder) {
      accentColor = const Color(0xFF3B82F6); // Blue for Reserved / Awaiting Order
    } else if (!isBilled) {
      accentColor = const Color(0xFF10B981); // Green for KOT Generated
    } else if (isPaidInFull) {
      accentColor = const Color(0xFF10B981); // Green for Paid
    } else if (isPartiallyPaid) {
      accentColor = const Color(0xFFF59E0B); // Amber for Partially Paid
    } else {
      accentColor = const Color(0xFFEF4444); // Red for Unpaid
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left accent stripe
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 3.5,
            child: Container(color: accentColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Title (Order ID or Table) + Badges (Never wrap) ─
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isAwaitingOrder ? table.name : orderNo,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isAwaitingOrder) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBadge(
                            label: 'Reserved',
                            icon: Icons.calendar_today_outlined,
                            bg: const Color(0xFFEFF6FF),
                            border: const Color(0xFFBFDBFE),
                            text: const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 5),
                          _buildBadge(
                            label: 'Awaiting Order',
                            icon: Icons.access_time_rounded,
                            bg: const Color(0xFFF8FAFC),
                            border: const Color(0xFFE2E8F0),
                            text: const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ] else if (!isBilled) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBadge(
                            label: 'KOT Generated',
                            icon: Icons.outdoor_grill_outlined,
                            bg: const Color(0xFFECFDF5),
                            border: const Color(0xFFA7F3D0),
                            text: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 5),
                          _buildBadge(
                            label: dynamicInfo?.kitchenStatusText == 'Ready for Delivery'
                                ? 'Ready'
                                : (dynamicInfo?.kitchenStatusText == 'Preparing in Kitchen'
                                    ? 'Preparing'
                                    : 'In Progress'),
                            icon: Icons.access_time_rounded,
                            bg: const Color(0xFFFFFBEB),
                            border: const Color(0xFFFDE68A),
                            text: const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBadge(
                            label: 'Bill Generated',
                            icon: Icons.description_outlined,
                            bg: const Color(0xFFEEF2FF),
                            border: const Color(0xFFC7D2FE),
                            text: const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 5),
                          if (isPaidInFull)
                            _buildBadge(
                              label: 'Paid',
                              icon: Icons.check_circle_outline_rounded,
                              bg: const Color(0xFFECFDF5),
                              border: const Color(0xFFA7F3D0),
                              text: const Color(0xFF059669),
                            )
                          else if (isPartiallyPaid)
                            _buildBadge(
                              label: 'Partially Paid',
                              icon: Icons.credit_card_outlined,
                              bg: const Color(0xFFFFFBEB),
                              border: const Color(0xFFFDE68A),
                              text: const Color(0xFFD97706),
                            )
                          else
                            _buildBadge(
                              label: 'Unpaid',
                              icon: Icons.credit_card_outlined,
                              bg: const Color(0xFFFEF2F2),
                              border: const Color(0xFFFECACA),
                              text: const Color(0xFFDC2626),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // ── Row 2: Guest Count & Item Count ────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$guestCount ${guestCount == 1 ? "Guest" : "Guests"}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    if (!isAwaitingOrder) ...[
                      Container(
                        height: 10,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                      Icon(
                        Icons.restaurant_outlined,
                        size: 14,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$itemCount ${itemCount == 1 ? "Item" : "Items"}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Reserved At Banner (for Awaiting Order) ────────────────
                if (isAwaitingOrder) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                          : const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                            : const Color(0xFFDBEAFE),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 13,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reserved At: ${_formatReservationDateTime(table.reservationInfo)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Scenarios 3, 4, 5: 3-Column Payment Breakdown ──────────
                if (isBilled) ...[
                  const SizedBox(height: 6),
                  _buildPaymentSummaryThreeColumns(
                    billAmount: totalAmount,
                    paidAmount: paidAmount,
                    dueOrRemaining: isUnpaid ? totalAmount : balanceAmount,
                    isUnpaid: isUnpaid,
                    isPaidInFull: isPaidInFull,
                    isDark: isDark,
                  ),
                ],

                // ── Scenario 4: Payment Reminder Banner ───────────────────
                if (isPartiallyPaid) ...[
                  const SizedBox(height: 6),
                  _buildPaymentReminderBanner(
                    remainingAmount: balanceAmount,
                    isDark: isDark,
                  ),
                ],

                const SizedBox(height: 8),

                // ── Bottom Action Row ─────────────────────────────────────
                if (isAwaitingOrder) ...[
                  // Awaiting Order: Amount dash on left, Delete Icon + Open Menu on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '—',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDeleteIconButton(
                            context,
                            table,
                            order,
                            dynamicInfo,
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildPrimaryButton(
                            icon: Icons.menu_book_rounded,
                            label: 'Open Menu',
                            onPressed: () => _handleOpenMenuForOrder(
                              context,
                              table,
                              order,
                              tableProvider,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else if (!isBilled) ...[
                  // Scenario 1: Order amount on left, Delete Icon + Open Cart on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${CurrencyConstants.symbol}${CurrencyConstants.formatWithoutSymbol(totalAmount)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDeleteIconButton(
                            context,
                            table,
                            order,
                            dynamicInfo,
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildPrimaryButton(
                            icon: Icons.shopping_cart_outlined,
                            label: 'Open Cart',
                            onPressed: () => _handleOpenCart(
                              context,
                              table,
                              order,
                              tableProvider,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  // Scenarios 3, 4, 5: Right-aligned CTA + Delete action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPaidInFull)
                        // Scenario 5: Delete Order button (prominent red)
                        _buildPrimaryButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete Order',
                          backgroundColor: const Color(0xFFDC2626),
                          onPressed: () => _removeOrder(
                            context,
                            table,
                            order,
                            dynamicInfo,
                          ),
                        )
                      else if (isPartiallyPaid) ...[
                        _buildDeleteIconButton(
                          context,
                          table,
                          order,
                          dynamicInfo,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildPrimaryButton(
                          icon: Icons.credit_card_rounded,
                          label: 'Collect ${CurrencyConstants.symbol}${CurrencyConstants.formatWithoutSymbol(balanceAmount)}',
                          onPressed: () => _handleCollectPayment(
                            context,
                            table,
                            order,
                            dynamicInfo,
                            tableProvider,
                          ),
                        ),
                      ] else ...[
                        _buildDeleteIconButton(
                          context,
                          table,
                          order,
                          dynamicInfo,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildPrimaryButton(
                          icon: Icons.credit_card_rounded,
                          label: 'Collect Payment',
                          onPressed: () => _handleCollectPayment(
                            context,
                            table,
                            order,
                            dynamicInfo,
                            tableProvider,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteIconButton(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    OrderDynamicInfo? dynamicInfo,
    bool isDark,
  ) {
    final bool isDeleting = _deletingOrderIds.any(
      (id) => GuidHelper.areEqual(id, order.orderId),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDeleting
            ? null
            : () => _removeOrder(
                  context,
                  table,
                  order,
                  dynamicInfo,
                ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                  : const Color(0xFFFECACA),
              width: 1,
            ),
          ),
          child: isDeleting
              ? const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFDC2626),
                      ),
                    ),
                  ),
                )
              : const Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: Color(0xFFDC2626),
                ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryThreeColumns({
    required double billAmount,
    required double paidAmount,
    required double dueOrRemaining,
    required bool isUnpaid,
    required bool isPaidInFull,
    required bool isDark,
  }) {
    final dueLabel = isUnpaid ? 'Due' : 'Remaining';
    final dueColor = isPaidInFull
        ? const Color(0xFF10B981) // Green for 0.00
        : const Color(0xFFDC2626); // Red for outstanding due

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F9),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Column 1: Bill Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Amount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyConstants.symbol}${CurrencyConstants.formatWithoutSymbol(billAmount)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // Divider 1
          Container(
            height: 22,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
          // Column 2: Paid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyConstants.symbol}${CurrencyConstants.formatWithoutSymbol(paidAmount)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981), // Green
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // Divider 2
          Container(
            height: 22,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
          // Column 3: Due / Remaining
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dueLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyConstants.symbol}${CurrencyConstants.formatWithoutSymbol(dueOrRemaining)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: dueColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReminderBanner({
    required double remainingAmount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF78350F).withValues(alpha: 0.25)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
              : const Color(0xFFFDE68A),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Please pay ${CurrencyConstants.symbol}${CurrencyConstants.formatWithoutSymbol(remainingAmount)} to complete the bill.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOpenCart(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    TableProvider tableProvider,
  ) async {
    final items = await tableProvider.loadCartStateForOrder(order.orderId);
    tableProvider.setCurrentOrder(order.orderId);

    if (context.mounted) {
      final animatedCart = Provider.of<AnimatedCartProvider>(
        context,
        listen: false,
      );
      animatedCart.importFromOrderCart(
        items,
        orderId: order.orderId,
        tableId: table.id,
        tableName: table.name,
        clearExisting: true,
      );

      final navProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );
      navProvider.selectTableAndNavigateToCart(
        table.id,
        table.name,
        table.location,
      );

      Navigator.pop(context); // Close dialog
    }
  }

  Future<void> _handleOpenMenuForOrder(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    TableProvider tableProvider,
  ) async {
    final items = await tableProvider.loadCartStateForOrder(order.orderId);
    tableProvider.setCurrentOrder(order.orderId);
    if (context.mounted) {
      final animatedCart = Provider.of<AnimatedCartProvider>(
        context,
        listen: false,
      );
      animatedCart.importFromOrderCart(
        items,
        orderId: order.orderId,
        tableId: table.id,
        tableName: table.name,
        clearExisting: true,
      );
      final navProvider =
          Provider.of<NavigationProvider>(context, listen: false);
      navProvider.selectTableAndNavigateToMenu(
        table.id,
        table.name,
        table.location,
      );
      Navigator.pop(context); // Close dialog
    }
  }

  Future<void> _handleOpenMenuForTable(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
  ) async {
    Navigator.pop(context); // Close dialog
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.selectTableAndNavigateToMenu(
      table.id,
      table.name,
      table.location,
    );
  }

  Future<void> _handleCollectPayment(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    OrderDynamicInfo? dynamicInfo,
    TableProvider tableProvider,
  ) async {
    final storedBillId =
        dynamicInfo?.billId ?? tableProvider.getBillId(order.orderId);
    Navigator.pop(context); // Close dialog

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          orderId: order.orderId,
          orderNumber: order.generatedOrderNo,
          tableId: table.id,
          billId: storedBillId,
          totalAmount: dynamicInfo?.totalAmount,
          onPaymentCompleted: () {
            tableProvider.refreshTables();
            Provider.of<NavigationProvider>(
              context,
              listen: false,
            ).clearTableSelection();
          },
        ),
      ),
    );
  }

  Widget _buildNoActiveOrders(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Table is Available',
            style: TextStyle(
              fontSize: 16.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'No active orders. Tap "Add New Order" below to seat guests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isCreatingOrder
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    _handleAddNewOrder(context, table, tableProvider);
                  },
            icon: _isCreatingOrder
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_rounded, size: 20),
            label: Text(
              _isCreatingOrder ? 'Adding Order...' : 'Add New Order',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle Add New Order to table via Order/saveOrderHead
  Future<void> _handleAddNewOrder(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
  ) async {
    final party = await AddPartyDialog.show(
      context,
      tableName: table.name,
      capacity: table.capacity,
      seatedGuests: table.seatedGuests ?? 0,
    );
    if (party == null) return; // cancelled
    if (!context.mounted) return;

    setState(() => _isCreatingOrder = true);
    try {
      final success = await tableProvider.createOrderForTable(
        table.id,
        table.name,
        adults: party.adults,
        children: party.children,
        customerName: party.customerName,
      );

      if (context.mounted) {
        if (success) {
          AppSnackBar.showSuccess(context, 'New order added to ${table.name}');
          _loadDynamicOrdersData(silent: false);
        } else {
          AppSnackBar.showError(
            context,
            AppStrings.dashboard.failedToAddOrderToServer,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Error creating order: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingOrder = false);
      }
    }
  }

  /// Handle removing an order with proper payment warning & confirmation
  void _removeOrder(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    OrderDynamicInfo? dynamicInfo,
  ) {
    if (_deletingOrderIds.any((id) => GuidHelper.areEqual(id, order.orderId))) {
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double paidAmount = dynamicInfo?.paidAmount ?? 0.0;
    final bool isPaidInFull = (dynamicInfo?.isPaidInFull ?? false) ||
        HiveService.isOrderSettled(order.orderId) ||
        (order.isBilled &&
            (dynamicInfo?.totalAmount ?? 0.0) > 0.004 &&
            paidAmount >= ((dynamicInfo?.totalAmount ?? 0.0) - 0.004));

    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Remove order dialog',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        void closeDialog() {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: closeDialog,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(color: Colors.black.withValues(alpha: 0.1)),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {},
                      child: Material(
                        color: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 360),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A).withValues(alpha: 0.92)
                                    : Colors.white.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.8),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      isPaidInFull
                                          ? 'Delete Settled Order'
                                          : 'Delete Order',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Are you sure you want to delete order "${order.generatedOrderNo}" from ${table.name}?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (isPaidInFull) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 15,
                                              color: Color(0xFF059669),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Bill Paid in Full (${CurrencyConstants.symbol}${CurrencyConstants.formatWithoutSymbol(paidAmount > 0 ? paidAmount : (dynamicInfo?.totalAmount ?? 0.0))})',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF065F46),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: closeDialog,
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              side: BorderSide(
                                                color: isDark
                                                    ? Colors.white24
                                                    : const Color(0xFFCBD5E1),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              if (_deletingOrderIds.any(
                                                (id) => GuidHelper.areEqual(
                                                  id,
                                                  order.orderId,
                                                ),
                                              )) {
                                                return;
                                              }
                                              if (mounted) {
                                                setState(() {
                                                  _deletingOrderIds
                                                      .add(order.orderId);
                                                });
                                              }
                                              closeDialog();
                                              final tableProvider =
                                                  Provider.of<TableProvider>(
                                                context,
                                                listen: false,
                                              );
                                              final cartProvider =
                                                  Provider.of<AnimatedCartProvider>(
                                                context,
                                                listen: false,
                                              );

                                              var success = false;
                                              try {
                                                success = await tableProvider
                                                    .removeOrderFromTable(
                                                  table.id,
                                                  order.orderId,
                                                  isPaidInFull: isPaidInFull,
                                                );
                                              } finally {
                                                if (mounted) {
                                                  setState(() {
                                                    _deletingOrderIds
                                                        .removeWhere(
                                                      (id) =>
                                                          GuidHelper.areEqual(
                                                        id,
                                                        order.orderId,
                                                      ),
                                                    );
                                                  });
                                                }
                                              }

                                              if (context.mounted) {
                                                if (success) {
                                                  cartProvider.clearOrderData(
                                                    order.orderId,
                                                  );
                                                  if (GuidHelper.areEqual(
                                                    tableProvider
                                                        .currentOrderId,
                                                    order.orderId,
                                                  )) {
                                                    tableProvider
                                                        .clearCurrentOrder();
                                                  }
                                                  _dynamicDataMap.removeWhere(
                                                    (key, _) =>
                                                        GuidHelper.areEqual(
                                                      key,
                                                      order.orderId,
                                                    ),
                                                  );

                                                  AppSnackBar.showSuccess(
                                                    context,
                                                    'Order ${order.generatedOrderNo} deleted',
                                                  );

                                                  // Check if table now has no orders, pop dialog
                                                  final updatedTable =
                                                      tableProvider.tables
                                                          .firstWhere(
                                                    (t) => GuidHelper.areEqual(
                                                        t.id, table.id),
                                                    orElse: () =>
                                                        RestaurantTable(
                                                      id: table.id,
                                                      name: table.name,
                                                      capacity: table.capacity,
                                                      location: table.location,
                                                      status:
                                                          TableStatus.available,
                                                      kotGenerated: false,
                                                      billGenerated: false,
                                                    ),
                                                  );
                                                  if (!updatedTable
                                                      .hasActiveOrders) {
                                                    if ((ModalRoute.of(context)
                                                                ?.isCurrent ??
                                                            false) &&
                                                        Navigator.of(context)
                                                            .canPop()) {
                                                      _isClosingFromRemoteClear =
                                                          true;
                                                      Navigator.pop(context);
                                                    }
                                                  } else {
                                                    setState(() {});
                                                    if (widget
                                                        .enableDynamicFetch) {
                                                      _loadDynamicOrdersData(
                                                        silent: true,
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  AppSnackBar.showError(
                                                    context,
                                                    tableProvider.error ??
                                                        'Failed to delete order from server',
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFDC2626),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
