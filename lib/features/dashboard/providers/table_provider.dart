import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/core/utils/guid_helper.dart';
import 'package:restaurant_pos_system/core/utils/connectivity_helper.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/data/models/bill_details_response.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/data/repositories/table_repository.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/order_channel.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;
  String? _error;
  String _selectedLocation = '';
  int? _outletId; // Remove static assignment - will get from Hive
  Timer? _pollingTimer;

  // Multi-order support
  final Map<String, List<Map<String, dynamic>>> _orderCartStates = {};
  String? _currentOrderId;

  // Legacy API loading state (for tables_view.dart compatibility)
  bool _isApiLoading = false;
  String? _tableApiError;
  List<OrderChannel> _orderChannels = [];

  // Getters
  List<RestaurantTable> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedLocation =>
      _selectedLocation.isNotEmpty
          ? _selectedLocation
          : (HiveService.getSelectedLocationName() ?? '');

  void setSelectedLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }
  int get outletId => _outletId ?? _getOutletIdFromHive();

  // Helper method to get outlet ID from Hive
  int _getOutletIdFromHive() {
    final savedOutletId = HiveService.getOutletId();
    if (savedOutletId != null && savedOutletId > 0) {
      _outletId = savedOutletId; // Cache it locally
      return savedOutletId;
    }
    if (kDebugMode) {
      debugPrint('[TableProvider] WARNING: No valid outlet ID found in Hive');
    }
    return 0; // Return 0 if no valid outlet ID found
  }

  String? get currentOrderId => _currentOrderId;

  // Legacy getters
  bool get isApiLoading => _isApiLoading;
  String? get tableApiError => _tableApiError;
  List<OrderChannel> get orderChannels => _orderChannels;

  void setOutletId(int outletId) {
    _outletId = outletId;
    // Also save to Hive for persistence
    HiveService.setOutletId(outletId);
    if (kDebugMode) {
      debugPrint(
        '[TableProvider] Updated outlet ID: $outletId (saved to Hive)',
      );
    }
    notifyListeners();
  }

  /// Get authentication token - Made public for dialog access
  String? getAuthToken() {
    return HiveService.getAuthToken();
  }

  /// Private method for internal use
  String? _getAuthToken() {
    return getAuthToken();
  }

  /// Start background polling timer to automatically keep all devices synchronized
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final token = _getAuthToken();
      final outletId = _getOutletId();
      if (token != null && outletId != null && outletId > 0) {
        refreshTables(silent: true);
      }
    });
  }

  /// Stop background polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Initialize tables with proper authentication - ONLY API DATA
  Future<void> initializeTables({bool silent = false}) async {
    final token = _getAuthToken();
    final outletId = _getOutletId();
    if (token != null && outletId != null && outletId > 0) {
      await fetchTablesWithAuth(token, outletId, selectedLocation, silent);
      startPolling();
    } else {
      _error = 'Authentication token or outlet ID not found';
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[TableProvider] Missing auth token or outlet ID');
      }
    }
  }

  /// Get outlet ID with validation
  int? _getOutletId() {
    final id = outletId; // Use getter
    if (id > 0) {
      return id;
    }
    if (kDebugMode) {
      debugPrint('[TableProvider] Invalid outlet ID: $id');
    }
    return null;
  }

  /// Fetch tables using ONLY API data - Multi-device synchronized
  Future<void> fetchTablesWithAuth(
    String token,
    int outletId, [
    String? locationName,
    bool silent = false,
  ]) async {
    // Only show full loading spinner if this is an initial empty load,
    // avoiding UI unmounting on background sync or pull-to-refresh
    if (!silent && _tables.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final effectiveLocation = locationName ?? selectedLocation;
      debugPrint(
        '[TableProvider] Fetching REAL API tables - Outlet: $outletId, Location: $effectiveLocation',
      );
      final tables = await TableRepository.fetchTablesFromOrderChannelAPI(
        token: token,
        outletId: outletId,
        locationName: effectiveLocation,
      );

      // Multi-device backend payment synchronization:
      // Fetch bills from backend via Order/GetBillForReprint to resolve real billIds
      // and payment status without relying on local device Hive cache.
      final List<ActiveOrder> billedOrdersToCheck = [];
      for (final apiTable in tables) {
        for (final order in apiTable.activeOrders) {
          if (order.isBilled || apiTable.billGenerated || order.billId != null) {
            billedOrdersToCheck.add(order);
          }
        }
      }

      final Set<String> backendPaidOrderIds = {};

      if (billedOrdersToCheck.isNotEmpty) {
        try {
          final now = DateTime.now();
          final fromDate = now.subtract(const Duration(days: 14));
          final toDate = now.add(const Duration(days: 1));
          final billsList = await ApiService.getBillsForReprint(
            outletId: outletId,
            from: fromDate,
            to: toDate,
          );

          final Map<String, PendingBill> billsByOrderNo = {};
          final Map<String, PendingBill> billsByBillId = {};
          final Map<String, PendingBill> billsByBillNo = {};
          if (billsList != null) {
            for (final b in billsList) {
              if (b.orderNo.isNotEmpty) {
                billsByOrderNo[b.orderNo.toLowerCase().trim()] = b;
              }
              if (b.billId.isNotEmpty) {
                billsByBillId[b.billId.toLowerCase().trim()] = b;
              }
              if (b.billNo.isNotEmpty) {
                billsByBillNo[b.billNo.toLowerCase().trim()] = b;
              }
            }
          }

          await Future.wait(
            billedOrdersToCheck.map((order) async {
              try {
                final matchByNo = billsByOrderNo[order.generatedOrderNo.toLowerCase().trim()];
                final storedBillId = order.billId ?? HiveService.getOrderBillId(order.orderId);
                final matchById = storedBillId != null
                    ? billsByBillId[storedBillId.toLowerCase().trim()]
                    : null;

                var matchedBill = matchByNo ?? matchById;
                String? billId = matchedBill?.billId ?? storedBillId;

                // Direct order details lookup if billId not known or not matched in reprint list
                if (billId == null || billId.isEmpty) {
                  try {
                    final orderDetails = await ApiService.getOrderDetailById(
                      token: token,
                      orderId: order.orderId,
                    );
                    if (orderDetails != null &&
                        orderDetails.isSuccess == true &&
                        orderDetails.data != null &&
                        orderDetails.data!.isNotEmpty) {
                      final head = orderDetails.data!.first;
                      if (head.isPaid == true) {
                        backendPaidOrderIds.add(order.orderId);
                        await markOrderSettled(order.orderId);
                        try {
                          await ApiService.updateOrderHeadStatus(
                            orderHeadId: order.orderId,
                            statusId: 7,
                            status: 'Settled',
                          );
                        } catch (_) {}
                        return;
                      }
                      final hBillId = head.billId;
                      if (GuidHelper.isValid(hBillId)) {
                        billId = hBillId;
                        await HiveService.saveOrderBillId(order.orderId, hBillId!);
                        matchedBill = billsByBillId[hBillId.toLowerCase().trim()];
                      }
                    }
                  } catch (e) {
                    debugPrint('[TableProvider] Error checking order details: $e');
                  }
                }

                if (matchedBill != null) {
                  // Save real billId from backend across all devices
                  if (GuidHelper.isValid(matchedBill.billId)) {
                    await HiveService.saveOrderBillId(order.orderId, matchedBill.billId);
                  }

                  // Verify if backend confirms bill is fully paid (isPaid == 2 or balance <= 0.004)
                  if (matchedBill.isFullyPaid) {
                    backendPaidOrderIds.add(order.orderId);
                    await markOrderSettled(order.orderId);
                    try {
                      await ApiService.updateOrderHeadStatus(
                        orderHeadId: order.orderId,
                        statusId: 7,
                        status: 'Settled',
                      );
                    } catch (_) {}
                    return;
                  }
                }

                // Verify through paid amount and bill details
                if (GuidHelper.isValid(billId)) {
                  final paid = await ApiService.getPaidAmountForBill(billId: billId!);
                  final billDetails = await ApiService.getBillDetailByBillId(billId: billId);
                  final double effectivePaid = (paid != null && paid > 0)
                      ? paid
                      : (billDetails?.data?.totalPaidAmount ?? 0.0);

                  final head = billDetails?.data?.billHeadDt;
                  double billAmt = head?.effectivePayableAmount ?? 0.0;
                  if (billAmt <= 0.004 && matchedBill != null && matchedBill.totalAmount > 0.004) {
                    billAmt = matchedBill.totalAmount;
                  }

                  final bool isPaidInFull = (billAmt > 0 && effectivePaid >= (billAmt - 0.004)) ||
                      (billDetails?.data?.isPaidInFull == true);

                  if (isPaidInFull) {
                    backendPaidOrderIds.add(order.orderId);
                    await markOrderSettled(order.orderId);
                    try {
                      await ApiService.updateOrderHeadStatus(
                        orderHeadId: order.orderId,
                        statusId: 7,
                        status: 'Settled',
                      );
                    } catch (_) {}
                  }
                }
              } catch (e) {
                debugPrint('[TableProvider] Error verifying billed order payment: $e');
              }
            }),
          );
        } catch (e) {
          debugPrint('[TableProvider] Error fetching reprint bills for sync: $e');
        }
      }

      // Check unbilled orders to synchronize KOT generation status across devices
      final List<ActiveOrder> unbilledOrdersToCheck = [];
      for (final apiTable in tables) {
        for (final order in apiTable.activeOrders) {
          if (!order.isBilled &&
              !order.hasKotGenerated &&
              !isOrderSettled(order.orderId) &&
              !backendPaidOrderIds.contains(order.orderId)) {
            unbilledOrdersToCheck.add(order);
          }
        }
      }

      if (unbilledOrdersToCheck.isNotEmpty) {
        await Future.wait(
          unbilledOrdersToCheck.map((order) async {
            try {
              final orderDetails = await ApiService.getOrderDetailById(
                token: token,
                orderId: order.orderId,
              );
              if (orderDetails != null &&
                  orderDetails.isSuccess == true &&
                  orderDetails.data != null &&
                  orderDetails.data!.isNotEmpty) {
                final head = orderDetails.data!.first;
                final lines = head.orderDetailList ?? [];
                for (final l in lines) {
                  if (l.kotNo != null && l.kotNo!.isNotEmpty) {
                    await HiveService.saveOrderKotNumber(order.orderId, l.kotNo!);
                    break;
                  }
                }
              }
            } catch (_) {}
          }),
        );
      }

      final List<RestaurantTable> mergedTables = [];

      for (final apiTable in tables) {
        // Exclude orders verified as fully paid directly from backend, marked settled, or deleted
        final validOrders = apiTable.activeOrders
            .where((order) =>
                order.orderId.isNotEmpty &&
                !isOrderSettled(order.orderId) &&
                !isOrderDeleted(order.orderId) &&
                !backendPaidOrderIds.contains(order.orderId))
            .toList();

        // Re-attach each order's billId and KOT status from memory/Hive if present
        final mergedOrders = validOrders.map((order) {
          final storedBillId = HiveService.getOrderBillId(order.orderId);
          final storedKotNo = HiveService.getOrderKotNumber(order.orderId);
          final isKotCreated =
              order.isKotCreated || (storedKotNo != null && storedKotNo.isNotEmpty);
          return order.copyWith(
            billId: GuidHelper.isNullOrEmpty(storedBillId) ? order.billId : storedBillId,
            isKotCreated: isKotCreated,
            kotNumber: storedKotNo ?? order.kotNumber,
          );
        }).toList();

        final hasKot = mergedOrders.any((o) => o.hasKotGenerated);
        final hasBill = mergedOrders.any((o) => o.isBilled);

        final resolvedStatus = mergedOrders.isEmpty
            ? TableStatus.available
            : (hasBill
                ? TableStatus.billGenerated
                : (hasKot ? TableStatus.kotGenerated : TableStatus.occupied));

        mergedTables.add(apiTable.copyWith(
          activeOrders: mergedOrders,
          status: resolvedStatus,
          kotGenerated: hasKot,
          billGenerated: hasBill,
        ));
      }

      if (tables.isNotEmpty) {
        _tables = mergedTables;
        _error = null;
        debugPrint(
          '[TableProvider] Successfully loaded ${_tables.length} REAL tables from API',
        );
      } else {
        final isConnected = await ConnectivityHelper.hasInternetConnection();
        if (!isConnected) {
          _error = null;
          debugPrint('[TableProvider] Offline: preserved ${_tables.length} existing tables');
        } else {
          _tables = [];
          _error = null;
          debugPrint('[TableProvider] Online: No tables found for this outlet');
        }
      }
    } catch (e) {
      final isConnected = await ConnectivityHelper.hasInternetConnection();
      if (!isConnected) {
        _error = null;
        debugPrint('[TableProvider] Offline caught: preserved ${_tables.length} existing tables');
      } else {
        _error = 'Failed to fetch tables: ${e.toString()}';
        debugPrint('[TableProvider] API Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Legacy method for fetchTablesByOutlet (for tables_view.dart) - FIXED
  Future<void> fetchTablesByOutlet({
    required String token,
    required int outletId,
  }) async {
    _isApiLoading = true;
    _tableApiError = null;
    notifyListeners(); // Notify loading state change
    try {
      debugPrint(
        '[TableProvider] fetchTablesByOutlet called - Outlet: $outletId',
      );
      debugPrint('[TableProvider] Auth Token: [PRESENT]');

      // Call the API service directly
      final response = await ApiService.getOrderChannelListByType(
        token: token,
        outletId: outletId,
        orderChannelType: "Table",
      );

      if (response != null && response.isSuccess == true) {
        // Map API response to OrderChannel objects for legacy compatibility
        _orderChannels =
            response.data
                ?.map(
                  (tableData) => OrderChannel(
                    orderChannelId: tableData.orderChannelId ?? '',
                    channelType: tableData.channelType ?? '',
                    name: tableData.name ?? '',
                    capacity: tableData.capacity ?? 0,
                    orderList:
                        tableData.orderList
                            ?.map(
                              (order) => OrderInfo(
                                orderId: order.orderId ?? '',
                                isBilled: order.isBilled ?? false,
                                orderStatus: order.orderStatus ?? '',
                                generatedOrderNo: order.generatedOrderNo ?? '',
                              ),
                            )
                            .toList() ??
                        [],
                  ),
                )
                .toList() ??
            [];

        // Also update the main tables list
        await fetchTablesWithAuth(token, outletId);

        debugPrint(
          '[TableProvider] fetchTablesByOutlet Success - Found ${_orderChannels.length} tables',
        );
      } else {
        _tableApiError = 'API returned unsuccessful response';
        _orderChannels = [];
        debugPrint(
          '[TableProvider] fetchTablesByOutlet Failed - ${response?.message}',
        );
      }
    } catch (e) {
      _tableApiError = 'Error: $e';
      _orderChannels = [];
      debugPrint('[TableProvider] fetchTablesByOutlet Error: $e');
    } finally {
      _isApiLoading = false;
      notifyListeners(); // CRITICAL: Always notify when loading completes
    }
  }

  /// Get tables filtered by location and status
  List<RestaurantTable> getTablesForLocation(
    String locationName, [
    String? statusFilter,
  ]) {
    List<RestaurantTable> filteredTables = List.from(_tables);

    // Filter by location
    if (locationName.isNotEmpty) {
      final selectedLocId = HiveService.getSelectedLocationId();
      filteredTables =
          filteredTables
              .where((table) {
                if (selectedLocId != null && table.locationId != null && table.locationId! > 0) {
                  return table.locationId == selectedLocId;
                }
                return table.location == locationName || table.location.isEmpty;
              })
              .toList();
    }

    // Filter by status if provided
    if (statusFilter != null && statusFilter != 'all') {
      switch (statusFilter) {
        case 'available':
          filteredTables =
              filteredTables
                  .where((table) => table.status == TableStatus.available)
                  .toList();
          break;
        case 'occupied':
          filteredTables =
              filteredTables
                  .where((table) => table.status == TableStatus.occupied)
                  .toList();
          break;
        case 'kot_generated':
          filteredTables =
              filteredTables
                  .where((table) => table.status == TableStatus.kotGenerated)
                  .toList();
          break;
        case 'bill_generated':
          filteredTables =
              filteredTables
                  .where((table) => table.status == TableStatus.billGenerated)
                  .toList();
          break;
        case 'bill_settled':
          filteredTables =
              filteredTables
                  .where((table) => table.status == TableStatus.billSettled)
                  .toList();
          break;
        case 'reserved':
          filteredTables =
              filteredTables
                  .where((table) => table.status == TableStatus.reserved)
                  .toList();
          break;
      }
    }

    filteredTables.sort((a, b) => _compareTableNames(a.name, b.name));
    return filteredTables;
  }

  /// Create new order for table (API-driven) - FIXED
  /// Opens a new order on [tableId].
  ///
  /// Called for the first group at a table and for every additional party
  /// after it — each call creates a separate OrderHead against the same
  /// channel (empty OrderIdUI means "new order" server-side). [adults],
  /// [children] and [customerName] describe this party; the guest counts are
  /// what tell groups on a shared table apart in the order list.
  Future<bool> createOrderForTable(
    String tableId,
    String tableName, {
    int adults = 1,
    int children = 0,
    String? customerName,
  }) async {
    try {
      final token = _getAuthToken();
      final userId = HiveService.getUserId();
      final waiterId = HiveService.getWaiterId(); // You need to implement this

      if (token == null || userId == null) {
        debugPrint('[Error] Missing authentication credentials');
        return false;
      }

      debugPrint('[Table Manager] Table $tableName tapped - Status: available');
      debugPrint('[Popup] Options shown: Occupy & Order, Reserve');

      // Step 1: Create new order using saveOrderHead API
      final orderResponse = await ApiService.saveOrderHead(
        token: token,
        orderChannelId: tableId,
        waiterId: waiterId ?? userId, // Use userId as fallback
        customerName:
            (customerName != null && customerName.trim().isNotEmpty)
                ? customerName.trim()
                : 'Walk-in Customer',
        outletId: outletId, // Use getter instead of private field
        userId: userId,
        totalAdult: adults,
        totalChild: children,
      );

      if (orderResponse != null && orderResponse.isSuccess == true) {
        final orderId = orderResponse.data?.orderId;
        final generatedOrderNo = orderResponse.data?.generatedOrderNo;

        if (orderId != null && generatedOrderNo != null) {
          debugPrint('[API Call] saveOrderHead Success - Order Created');
          debugPrint('[Order Created] ID: $orderId');
          debugPrint('[Order Created] Number: $generatedOrderNo');

          // Step 2: Update local table state immediately for UI responsiveness
          _updateTableStatusLocally(
            tableId,
            TableStatus.occupied,
            orderId,
            generatedOrderNo,
          );

          // Step 3: Set current order for navigation
          _currentOrderId = orderId;

          // Step 4: Refresh tables from API to get latest state
          await refreshTables();

          return true;
        }

        debugPrint(
          '[Error] Failed to create order - API response: ${orderResponse.message}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[Error] Creating order: $e');
      return false;
    }
    return false;
  }

  /// Enhanced local table update with order details
  void _updateTableStatusLocally(
    String tableId,
    TableStatus status, [
    String? newOrderId,
    String? generatedOrderNo,
  ]) {
    final tableIndex =
        _tables.indexWhere((t) => GuidHelper.areEqual(t.id, tableId));
    if (tableIndex != -1) {
      List<ActiveOrder> orders = List.from(_tables[tableIndex].activeOrders);

      if (newOrderId != null && status == TableStatus.occupied) {
        orders.add(
          ActiveOrder(
            orderId: newOrderId,
            generatedOrderNo:
                generatedOrderNo ??
                'ORD/${DateTime.now().millisecondsSinceEpoch}',
            orderStatus: 'Order Placed',
            isBilled: false,
          ),
        );
      }

      _tables[tableIndex] = _tables[tableIndex].copyWith(
        status: status,
        activeOrders: orders,
      );

      notifyListeners();
    }
  }

  /// Load cart state for specific order (API-driven)
  Future<List<Map<String, dynamic>>> loadCartStateForOrder(
    String orderId,
  ) async {
    try {
      final token = _getAuthToken();
      if (token == null) return [];
      debugPrint('[Table Manager] Loading cart for order: $orderId');
      debugPrint('[API Call] getOrderDetailById - Order $orderId');
      final orderDetails = await ApiService.getOrderDetailById(
        token: token,
        orderId: orderId,
      );

      if (orderDetails != null &&
          orderDetails.isSuccess == true &&
          orderDetails.data != null) {
        // Convert order details to cart items with proper KOT status
        final orderDetailList = orderDetails.data!.first.orderDetailList ?? [];
        final List<Map<String, dynamic>> cartItems =
            orderDetailList.map((item) {
              // All items returned from getOrderDetailById exist on the backend = KOT generated
              const bool isKotGenerated = true;

              final imageUrl = item.imageThumbUrl ?? item.imageUrl;

              return <String, dynamic>{
                'productId': item.productId,
                'productName': item.productName,
                'quantity': item.productQty,
                'price': item.itemPrice,
                'totalPrice': item.totPrice,
                'imageUrl': imageUrl,
                'imageThumbUrl': imageUrl,
                // Mark as KOT generated since these items exist in backend
                'isKotGenerated': isKotGenerated,
                'kotNo': item.kotNo,
                'kotNumber': item.kotNo,
                // Additional properties for proper cart item creation
                'uom': item.uom,
                'discountPercentage': item.discountPerc ?? 0,
                'specialNotes': item.instruction,
                'note': item.instruction,
              };
            }).toList();
        // print cart items with KOT status
        final kotGeneratedCount =
            cartItems.where((item) => item['isKotGenerated'] == true).length;
        final newItemsCount = cartItems.length - kotGeneratedCount;
        debugPrint(
          '[Cart Items] Loaded ${cartItems.length} items for order $orderId',
        );
        debugPrint(
          '[Cart Items] KOT Generated: $kotGeneratedCount, New Items: $newItemsCount',
        );

        _orderCartStates[orderId] = cartItems;
        _currentOrderId = orderId;

        debugPrint(
          '[Cart Loaded] Order $orderId with ${cartItems.length} items ($kotGeneratedCount KOT generated)',
        );
        notifyListeners(); // CRITICAL: Notify when cart state changes

        // Return loaded items so caller (UI) can sync AnimatedCartProvider
        return cartItems;
      }
    } catch (e) {
      debugPrint('[Error] Loading cart state: $e');
    }
    return [];
  }

  /// Remove order from table via authoritative backend API operation.
  /// If the backend operation fails or is offline, local state is NOT mutated.
  Future<bool> removeOrderFromTable(
    String tableId,
    String orderId, {
    bool isPaidInFull = false,
  }) async {
    try {
      // 1. Verify connectivity
      final isConnected = await ConnectivityHelper.hasInternetConnection();
      if (!isConnected) {
        _error = 'No internet connection. Cannot delete order.';
        notifyListeners();
        debugPrint(
          '[TableProvider] removeOrderFromTable aborted: No internet connection',
        );
        return false;
      }

      // 2. Call backend API with primary status and fallback:
      // For orders paid in full: primary status 7 (Settled), fallback 4 (Cancelled)
      // For unbilled/unpaid/awaiting orders: primary status 4 (Cancelled), fallback 7 (Settled)
      final primaryStatusId = isPaidInFull ? 7 : 4;
      final primaryStatus = isPaidInFull ? 'Settled' : 'Cancelled';
      final fallbackStatusId = isPaidInFull ? 4 : 7;
      final fallbackStatus = isPaidInFull ? 'Cancelled' : 'Settled';

      var response = await ApiService.updateOrderHeadStatus(
        orderHeadId: orderId,
        statusId: primaryStatusId,
        status: primaryStatus,
        tableId: tableId,
      );

      if (response == null || response['isSuccess'] == false) {
        debugPrint(
          '[TableProvider] removeOrderFromTable primary status $primaryStatusId failed, trying fallback $fallbackStatusId',
        );
        response = await ApiService.updateOrderHeadStatus(
          orderHeadId: orderId,
          statusId: fallbackStatusId,
          status: fallbackStatus,
          tableId: tableId,
        );
      }

      // 3. Verify backend response
      if (response == null || response['isSuccess'] == false) {
        final errMsg =
            response?['message']?.toString() ?? 'Server failed to remove order.';
        _error = errMsg;
        notifyListeners();
        debugPrint(
          '[TableProvider] removeOrderFromTable failed on server: $errMsg',
        );
        return false;
      }

      debugPrint(
        '[TableProvider] removeOrderFromTable confirmed by server for order $orderId',
      );

      // 4. Mark deleted (and settled if paid) in provider and Hive so subsequent refreshes never resurrect it
      await markOrderDeleted(orderId);
      if (isPaidInFull) {
        await markOrderSettled(orderId);
      }

      // 5. Clear local order cart and stored bill references
      _orderCartStates.remove(orderId);
      await HiveService.clearOrderBillId(orderId);

      // 6. Immediately update local table in-memory active orders upon confirmed backend success
      final tableIdx =
          _tables.indexWhere((t) => GuidHelper.areEqual(t.id, tableId));
      if (tableIdx != -1) {
        final remainingOrders = _tables[tableIdx]
            .activeOrders
            .where((o) => !GuidHelper.areEqual(o.orderId, orderId))
            .toList();
        final hasKot = remainingOrders.any((o) => o.hasKotGenerated);
        final hasBill = remainingOrders.any((o) => o.isBilled);
        final resolvedStatus = remainingOrders.isEmpty
            ? TableStatus.available
            : (hasBill
                ? TableStatus.billGenerated
                : (hasKot ? TableStatus.kotGenerated : TableStatus.occupied));

        _tables[tableIdx] = _tables[tableIdx].copyWith(
          activeOrders: remainingOrders,
          status: resolvedStatus,
          kotGenerated: hasKot,
          billGenerated: hasBill,
        );

        // If no orders remain on table, notify server that table is Available
        if (remainingOrders.isEmpty) {
          try {
            await ApiService.updateOrderChannelStatus(
              orderChannelId: tableId,
              channelStatusId: 0,
              status: 'Available',
            );
          } catch (_) {}
        }

        notifyListeners();
      }

      // 7. Refresh authoritative table list from backend
      await refreshTables(silent: true);
      return true;
    } catch (e) {
      debugPrint('[TableProvider] Error removing order $orderId: $e');
      _error = 'Error removing order: $e';
      notifyListeners();
      return false;
    }
  }

  /// Vacate and clear an entire table by executing backend API operations for each active order.
  /// Does NOT simulate local deletion if backend operations fail or internet is offline.
  Future<bool> clearTable(String tableId) async {
    try {
      // 1. Verify connectivity
      final isConnected = await ConnectivityHelper.hasInternetConnection();
      if (!isConnected) {
        _error = 'No internet connection. Cannot clear table.';
        notifyListeners();
        debugPrint('[TableProvider] clearTable aborted: No internet connection');
        return false;
      }

      final tableIndex =
          _tables.indexWhere((t) => GuidHelper.areEqual(t.id, tableId));
      if (tableIndex == -1) return false;

      final ordersToClear =
          List<ActiveOrder>.from(_tables[tableIndex].activeOrders);
      if (ordersToClear.isEmpty) {
        try {
          await ApiService.updateOrderChannelStatus(
            orderChannelId: tableId,
            channelStatusId: 0,
            status: 'Available',
          );
        } catch (_) {}
        return true;
      }

      bool allSucceeded = true;
      String? failureMessage;

      // 2. Execute backend removal for every active order (Settled fallback Cancelled)
      for (final order in ordersToClear) {
        var response = await ApiService.updateOrderHeadStatus(
          orderHeadId: order.orderId,
          statusId: 7,
          status: 'Settled',
          tableId: tableId,
        );

        if (response == null || response['isSuccess'] == false) {
          response = await ApiService.updateOrderHeadStatus(
            orderHeadId: order.orderId,
            statusId: 4,
            status: 'Cancelled',
            tableId: tableId,
          );
        }

        if (response == null || response['isSuccess'] == false) {
          allSucceeded = false;
          failureMessage = response?['message']?.toString() ??
              'Server failed to vacate order ${order.generatedOrderNo}';
          break;
        }

        await markOrderSettled(order.orderId);
        await markOrderDeleted(order.orderId);
        _orderCartStates.remove(order.orderId);
        await HiveService.clearOrderBillId(order.orderId);
      }

      // 3. Handle backend failure
      if (!allSucceeded) {
        _error = failureMessage ?? 'Failed to clear all orders on server.';
        notifyListeners();
        await refreshTables(silent: true);
        return false;
      }

      debugPrint('[TableProvider] clearTable confirmed by server for table $tableId');

      try {
        await ApiService.updateOrderChannelStatus(
          orderChannelId: tableId,
          channelStatusId: 0,
          status: 'Available',
        );
      } catch (_) {}

      // Update in-memory table status to available immediately upon confirmed backend success
      if (tableIndex != -1 && tableIndex < _tables.length) {
        _tables[tableIndex] = _tables[tableIndex].copyWith(
          activeOrders: [],
          status: TableStatus.available,
          kotGenerated: false,
          billGenerated: false,
        );
        notifyListeners();
      }

      // 4. Refresh authoritative table list from backend
      await refreshTables(silent: true);
      return true;
    } catch (e) {
      debugPrint('[TableProvider] Error clearing table $tableId: $e');
      _error = 'Error clearing table: $e';
      notifyListeners();
      return false;
    }
  }

  /// Set current active order - NEWLY ADDED METHOD
  void setCurrentOrder(String orderId) {
    _currentOrderId = orderId;
    debugPrint('[Navigation] Redirecting to Menu with Order ID $orderId');
    notifyListeners();
  }

  /// Clears the table order left active from a previous dine-in session.
  ///
  /// Nothing used to reset this when leaving a table for a Phone/Takeaway
  /// order — currentOrderId stayed pointed at the last table's order for the
  /// rest of the app session. CartView's KOT/bill generation both read this
  /// field, so a stale value here silently attached a new Phone/Takeaway
  /// order's KOT and bill to the previous table's order instead. Call this
  /// whenever starting an order that is not table-based.
  void clearCurrentOrder() {
    _currentOrderId = null;
    notifyListeners();
  }

  /// Get cart items for current order - NEWLY ADDED METHOD
  List<Map<String, dynamic>> getCurrentOrderCartItems() {
    if (_currentOrderId == null) return [];
    return _orderCartStates[_currentOrderId] ?? [];
  }

  /// Clear cart for specific order - NEWLY ADDED METHOD
  void clearCartForOrder(String orderId) {
    _orderCartStates.remove(orderId);
    debugPrint('[Cart] Cleared cart for order: $orderId');
    notifyListeners();
  }

  /// Add item to current order's cart - NEWLY ADDED METHOD
  void addItemToCart(String orderId, Map<String, dynamic> item) {
    if (_orderCartStates[orderId] == null) {
      _orderCartStates[orderId] = [];
    }
    _orderCartStates[orderId]!.add(item);
    debugPrint('[Cart] Added item to order $orderId: ${item['productName']}');
    notifyListeners();
  }

  /// Update item quantity in cart - NEWLY ADDED METHOD
  void updateItemQuantity(String orderId, String productId, int quantity) {
    if (_orderCartStates[orderId] == null) return;

    final items = _orderCartStates[orderId]!;
    final itemIndex = items.indexWhere(
      (item) => item['productId'] == productId,
    );

    if (itemIndex != -1) {
      if (quantity > 0) {
        items[itemIndex]['quantity'] = quantity;
        items[itemIndex]['totalPrice'] = items[itemIndex]['price'] * quantity;
      } else {
        items.removeAt(itemIndex);
      }
      notifyListeners();
    }
  }

  /// Remove item from cart - NEWLY ADDED METHOD
  void removeItemFromCart(String orderId, String productId) {
    if (_orderCartStates[orderId] == null) return;

    _orderCartStates[orderId]!.removeWhere(
      (item) => item['productId'] == productId,
    );
    debugPrint('[Cart] Removed item from order $orderId: $productId');
    notifyListeners();
  }

  /// Legacy methods for compatibility
  Future<void> fetchTables() async {
    final token = _getAuthToken();
    final outletId = _getOutletId();
    if (token != null && outletId != null) {
      await fetchTablesWithAuth(token, outletId);
    } else {
      _error = 'Authentication required';
      notifyListeners();
    }
  }

  void updateTableStatus(String tableId, String newStatus) {
    // Convert string status to enum
    TableStatus? status;
    switch (newStatus.toLowerCase()) {
      case 'available':
        status = TableStatus.available;
        break;
      case 'occupied':
        status = TableStatus.occupied;
        break;
      case 'kotgenerated':
        status = TableStatus.kotGenerated;
        break;
      case 'billgenerated':
        status = TableStatus.billGenerated;
        break;
      case 'billsettled':
        status = TableStatus.billSettled;
        break;
      case 'reserved':
        status = TableStatus.reserved;
        break;
      case 'outoforder':
        status = TableStatus.outOfOrder;
        break;
    }

    if (status != null) {
      final tableIndex =
          _tables.indexWhere((table) => GuidHelper.areEqual(table.id, tableId));
      if (tableIndex != -1) {
        if (status == TableStatus.available) {
          _tables[tableIndex] = _tables[tableIndex].copyWith(
            status: TableStatus.available,
            activeOrders: const [],
            kotGenerated: false,
            billGenerated: false,
          );
        } else {
          _tables[tableIndex] = _tables[tableIndex].copyWith(status: status);
        }
        notifyListeners();
      }
    }
  }

  void clearTableStatusOverride(String tableId) {
    // No-op for backward compatibility
  }

  /// Remember the bill generated for [orderId].
  ///
  /// Keyed by order, not table: a table can host several groups at once and
  /// each gets its own bill, so a table-level key let the second group's bill
  /// overwrite the first's.
  void storeBillId(String orderId, String billId) {
    if (GuidHelper.isNullOrEmpty(orderId) || GuidHelper.isNullOrEmpty(billId)) {
      debugPrint(
        '[TableProvider] Refusing to store bill ID '
        '(orderId: $orderId, billId: $billId)',
      );
      return;
    }

    HiveService.saveOrderBillId(orderId, billId);
    _applyToOrder(orderId, (order) => order.copyWith(billId: billId));

    debugPrint('[TableProvider] Stored bill ID for order $orderId: $billId');
  }

  /// Forget the bill attached to [orderId], in memory and in Hive.
  ///
  /// Must be called once that order is settled. Bill ids are re-attached on
  /// every refresh, so without this the next group seated at the same table
  /// under a new order could still surface a stale bill.
  Future<void> clearBillId(String orderId) async {
    if (orderId.isEmpty) return;

    await HiveService.clearOrderBillId(orderId);
    _applyToOrder(orderId, (order) => order.copyWith(clearBillId: true));

    debugPrint('[TableProvider] Cleared bill ID for order $orderId');
  }

  final Set<String> _settledOrderIds = {};
  final Set<String> _deletedOrderIds = {};

  bool isOrderSettled(String orderId) {
    if (orderId.isEmpty) return false;
    final clean = orderId.toLowerCase().trim();
    return _settledOrderIds.contains(clean) ||
        HiveService.isOrderSettled(clean);
  }

  bool isOrderDeleted(String orderId) {
    if (orderId.isEmpty) return false;
    final clean = orderId.toLowerCase().trim();
    return _deletedOrderIds.contains(clean) ||
        HiveService.isOrderDeleted(clean);
  }

  /// Mark [orderId] as deleted/cancelled, clearing its bill, removing it from active
  /// orders, and updating the holding table to Available if no other active orders remain.
  Future<void> markOrderDeleted(String orderId) async {
    if (orderId.isEmpty) return;

    final clean = orderId.toLowerCase().trim();
    _deletedOrderIds.add(clean);
    await HiveService.markOrderDeleted(clean);
    await clearBillId(orderId);

    // Update in-memory table state immediately
    var changed = false;
    for (var i = 0; i < _tables.length; i++) {
      final t = _tables[i];
      if (t.activeOrders.any((o) => GuidHelper.areEqual(o.orderId, orderId))) {
        final remaining = t.activeOrders
            .where((o) => !GuidHelper.areEqual(o.orderId, orderId))
            .toList();
        final hasKot = remaining.any((o) => o.hasKotGenerated);
        final hasBill = remaining.any((o) => o.isBilled);
        final newStatus = remaining.isEmpty
            ? TableStatus.available
            : (hasBill
                ? TableStatus.billGenerated
                : (hasKot ? TableStatus.kotGenerated : TableStatus.occupied));
        _tables[i] = t.copyWith(
          activeOrders: remaining,
          status: newStatus,
          kotGenerated: hasKot,
          billGenerated: hasBill,
        );
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Mark [orderId] as fully settled/paid, clearing its bill, removing it from active
  /// orders, and updating the holding table to Available if no other active orders remain.
  Future<void> markOrderSettled(String orderId) async {
    if (orderId.isEmpty) return;

    final clean = orderId.toLowerCase().trim();
    _settledOrderIds.add(clean);
    await HiveService.markOrderSettled(clean);
    await clearBillId(orderId);

    // Update memory table state immediately so UI updates without waiting for network
    var changed = false;
    for (var i = 0; i < _tables.length; i++) {
      final t = _tables[i];
      if (t.activeOrders.any((o) => GuidHelper.areEqual(o.orderId, orderId))) {
        final remaining = t.activeOrders
            .where((o) => !GuidHelper.areEqual(o.orderId, orderId))
            .toList();
        final hasKot = remaining.any((o) => o.hasKotGenerated);
        final hasBill = remaining.any((o) => o.isBilled);
        final newStatus = remaining.isEmpty
            ? TableStatus.available
            : (hasBill
                ? TableStatus.billGenerated
                : (hasKot ? TableStatus.kotGenerated : TableStatus.occupied));
        _tables[i] = t.copyWith(
          activeOrders: remaining,
          status: newStatus,
          kotGenerated: hasKot,
          billGenerated: hasBill,
        );
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Bill generated for [orderId], from memory or local storage.
  String? getBillId(String orderId) {
    if (orderId.isEmpty) return null;

    for (final table in _tables) {
      for (final order in table.activeOrders) {
        if (GuidHelper.areEqual(order.orderId, orderId) &&
            GuidHelper.isValid(order.billId)) {
          return GuidHelper.orNull(order.billId);
        }
      }
    }

    return GuidHelper.orNull(HiveService.getOrderBillId(orderId));
  }

  /// Rewrites the matching order in place, wherever it sits.
  void _applyToOrder(
    String orderId,
    ActiveOrder Function(ActiveOrder order) update,
  ) {
    var changed = false;

    for (var i = 0; i < _tables.length; i++) {
      final orders = _tables[i].activeOrders;
      final index =
          orders.indexWhere((o) => GuidHelper.areEqual(o.orderId, orderId));
      if (index == -1) continue;

      final updated = List<ActiveOrder>.from(orders);
      updated[index] = update(orders[index]);
      _tables[i] = _tables[i].copyWith(activeOrders: updated);
      changed = true;
    }

    if (changed) notifyListeners();
  }

  // Backward compatibility method (deprecated)
  @Deprecated('Use storeBillId instead')
  void storeBillAmount(String tableId, double billAmount) {
    debugPrint(
      'Warning: storeBillAmount is deprecated. Use storeBillId instead.',
    );
    // This method is kept for backward compatibility but does nothing
  }

  // Fetch bill details using the new API
  Future<BillDetailsResponse?> getBillDetails(String orderId) async {
    try {
      final billId = getBillId(orderId);
      if (GuidHelper.isNullOrEmpty(billId)) {
        debugPrint('[TableProvider] No bill ID found for order $orderId');
        return null;
      }

      debugPrint(
        '[TableProvider] Fetching bill details for order $orderId with billId: $billId',
      );
      final billDetails = await ApiService.getBillDetailByBillId(
        billId: billId!,
      );

      if (billDetails != null && billDetails.isSuccess) {
        debugPrint(
          '[TableProvider] Successfully fetched bill details for order $orderId',
        );
        return billDetails;
      } else {
        debugPrint(
          '[TableProvider] Failed to fetch bill details for order $orderId: ${billDetails?.message}',
        );
        return null;
      }
    } catch (e) {
      debugPrint(
        '[TableProvider] Error fetching bill details for order $orderId: $e',
      );
      return null;
    }
  }

  // Get bill amount using the new API (backward compatibility)
  Future<double?> getBillAmount(String orderId) async {
    try {
      final billDetails = await getBillDetails(orderId);
      return billDetails?.data?.billHeadDt.effectivePayableAmount;
    } catch (e) {
      debugPrint(
        '[TableProvider] Error getting bill amount for order $orderId: $e',
      );
      return null;
    }
  }

  void addOrderToTable(String tableId, ActiveOrder newOrder) {
    // This is now handled by API calls and refresh
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Wipes all company-specific in-memory state on logout.
  void reset() {
    _tables = [];
    _orderCartStates.clear();
    _currentOrderId = null;
    _outletId = null;
    _selectedLocation = '';
    _orderChannels = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  /// Refreshes table data from backend.
  /// When [silent] or [isPullToRefresh] is true, avoids full-screen loading flash.
  Future<void> refreshTables({
    bool silent = false,
    bool isPullToRefresh = false,
  }) async {
    final token = _getAuthToken();
    final outletId = _getOutletId();
    if (token != null && outletId != null && outletId > 0) {
      await fetchTablesWithAuth(
        token,
        outletId,
        selectedLocation,
        silent || isPullToRefresh || _tables.isNotEmpty,
      );
    }
  }

  int _compareTableNames(String name1, String name2) {
    final regex = RegExp(r'(\d+)');
    final match1 = regex.firstMatch(name1);
    final match2 = regex.firstMatch(name2);

    if (match1 != null && match2 != null) {
      final num1 = int.tryParse(match1.group(1)!) ?? 0;
      final num2 = int.tryParse(match2.group(1)!) ?? 0;

      final prefix1 = name1.substring(0, match1.start);
      final prefix2 = name2.substring(0, match2.start);

      final prefixComparison = prefix1.compareTo(prefix2);
      if (prefixComparison != 0) return prefixComparison;

      return num1.compareTo(num2);
    }

    return name1.compareTo(name2);
  }
}
