import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/data/models/bill_details_response.dart';
import 'package:restaurant_pos_system/data/repositories/table_repository.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/order_channel.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;
  String? _error;
  String _selectedLocation = 'Main Hall';
  int? _outletId; // Remove static assignment - will get from Hive

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
  String get selectedLocation => _selectedLocation;
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
      debugPrint('[TableProvider] Updated outlet ID: $outletId (saved to Hive)');
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

  /// Initialize tables with proper authentication - ONLY API DATA
  void initializeTables() {
    final token = _getAuthToken();
    final outletId = _getOutletId();
    if (token != null && outletId != null) {
      fetchTablesWithAuth(token, outletId);
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

  /// Fetch tables using ONLY API data - FIXED UI UPDATE
  Future<void> fetchTablesWithAuth(String token, int outletId) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // First notification: Loading state
    try {
      debugPrint('[TableProvider] Fetching REAL API tables - Outlet: $outletId');
      final tables = await TableRepository.fetchTablesFromOrderChannelAPI(
        token: token,
        outletId: outletId,
      );

      // CRITICAL FIX: Merge API data with existing local data to preserve bill IDs
      final List<RestaurantTable> mergedTables = [];

      for (final apiTable in tables) {
        // Find existing table to preserve local data
        final existingTable = _tables.firstWhere(
          (t) => t.id == apiTable.id,
          orElse: () => apiTable,
        );

        // Get bill ID from memory or persistent storage
        String? preservedBillId = existingTable.billId;
        if (preservedBillId == null || preservedBillId.isEmpty) {
          // Fallback to persistent storage if not in memory
          preservedBillId = HiveService.getTableBillId(apiTable.id);
        }

        // Merge API data with existing local data (preserve billId)
        final mergedTable = apiTable.copyWith(
          billId: preservedBillId, // Preserve existing bill ID
        );

        mergedTables.add(mergedTable);

        // Debug log for bill ID preservation
        if (preservedBillId != null && preservedBillId.isNotEmpty) {
          debugPrint(
            '[TableProvider] Preserved bill ID for ${apiTable.name}: $preservedBillId',
          );
        }
      }

      _tables = mergedTables; // Replace with merged data

      if (_tables.isEmpty) {
        _error =
            'No tables found for this outlet. Check backend configuration.';
        debugPrint('[TableProvider] API returned no tables - Check backend data');
      } else {
        debugPrint(
          '[TableProvider] Successfully loaded ${_tables.length} REAL tables from API',
        );
        for (final table in _tables) {
          debugPrint(
            '[TableProvider] API Table: ${table.name} (${table.location}) - Orders: ${table.activeOrders.length}',
          );
        }
      }
    } catch (e) {
      _error = 'Failed to fetch tables: ${e.toString()}';
      _tables = []; // Empty list if API fails
      debugPrint('[TableProvider] API Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // CRITICAL: Notify after data changes
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
      debugPrint('[TableProvider] fetchTablesByOutlet called - Outlet: $outletId');
      debugPrint('[TableProvider] Token: ${token.substring(0, 10)}...');

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
    filteredTables =
        filteredTables
            .where((table) => table.location == locationName)
            .toList();

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
  Future<bool> createOrderForTable(String tableId, String tableName) async {
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
        customerName: 'Walk-in Customer',
        outletId: outletId, // Use getter instead of private field
        userId: userId,
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
    final tableIndex = _tables.indexWhere((t) => t.id == tableId);
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

  /// Remove order from table (API-driven) - FIXED
  Future<bool> removeOrderFromTable(String tableId, String orderId) async {
    try {
      final userId = HiveService.getUserId() ?? '041f765b-658c-47a4-b1a7-9dedf6e980b9';

      // Call UpdateOrderHeadStatus API to cancel/remove order (statusId: 6, companyId: 18)
      final result = await ApiService.updateOrderHeadStatus(
        orderHeadId: orderId,
        statusId: 6,
        userId: userId,
        companyId: 18,
      );

      if (result != null && result['isSuccess'] == true) {
        debugPrint('[Order Removed] ID: $orderId');

        // Update local state immediately
        final tableIndex = _tables.indexWhere((t) => t.id == tableId);
        if (tableIndex != -1) {
          final currentOrders =
              _tables[tableIndex].activeOrders
                  .where((order) => order.orderId != orderId)
                  .toList();
          final newStatus =
              currentOrders.isEmpty
                  ? TableStatus.available
                  : TableStatus.occupied;

          _tables[tableIndex] = _tables[tableIndex].copyWith(
            activeOrders: currentOrders,
            status: newStatus,
          );

          if (currentOrders.isEmpty) {
            debugPrint('[API Call] Table $tableId -> Available (no more orders)');
          }

          // Clear cart state for this order
          _orderCartStates.remove(orderId);
          notifyListeners();

          // Refresh from API to sync with backend
          await refreshTables();

          return true;
        }

        return false;
      }
    } catch (e) {
      debugPrint('[Error] Removing order: $e');
      return false;
    }
    return false;
  }

  /// Set current active order - NEWLY ADDED METHOD
  void setCurrentOrder(String orderId) {
    _currentOrderId = orderId;
    debugPrint('[Navigation] Redirecting to Menu with Order ID $orderId');
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
      final tableIndex = _tables.indexWhere((table) => table.id == tableId);
      if (tableIndex != -1) {
        _tables[tableIndex] = _tables[tableIndex].copyWith(status: status);
        notifyListeners();
      }
    }
  }

  void clearTableStatusOverride(String tableId) {
    // No-op for backward compatibility
  }

  // Store bill ID for a table (new approach)
  void storeBillId(String tableId, String billId) {
    debugPrint(
      '[TableProvider] Attempting to store bill ID for table ID: $tableId, billId: $billId',
    );
    debugPrint(
      '[TableProvider] Available tables: ${_tables.map((t) => '${t.id}:${t.name}').toList()}',
    );

    // Save to persistent storage first
    HiveService.saveTableBillId(tableId, billId);

    final tableIndex = _tables.indexWhere((table) => table.id == tableId);
    if (tableIndex != -1) {
      _tables[tableIndex] = _tables[tableIndex].copyWith(
        billId: billId,
        status: TableStatus.billGenerated,
      );

      notifyListeners();
      debugPrint(
        '[TableProvider] Successfully stored bill ID for table $tableId: $billId',
      );
    } else {
      debugPrint('[TableProvider] ERROR: Table with ID $tableId not found!');
    }
  }

  // Backward compatibility method (deprecated)
  @Deprecated('Use storeBillId instead')
  void storeBillAmount(String tableId, double billAmount) {
    debugPrint('Warning: storeBillAmount is deprecated. Use storeBillId instead.');
    // This method is kept for backward compatibility but does nothing
  }

  // Get stored bill ID for a table
  String? getBillId(String tableId) {
    debugPrint('[TableProvider] Attempting to get bill ID for table ID: $tableId');
    debugPrint(
      '[TableProvider] Available tables: ${_tables.map((t) => '${t.id}:${t.name}:${t.billId}').toList()}',
    );

    try {
      final table = _tables.firstWhere((table) => table.id == tableId);
      debugPrint(
        '[TableProvider] Found table ${table.name}, bill ID: ${table.billId}',
      );

      // If table bill ID is null, try loading from persistent storage
      if (table.billId == null || table.billId!.isEmpty) {
        final persistedBillId = HiveService.getTableBillId(tableId);
        if (persistedBillId != null && persistedBillId.isNotEmpty) {
          debugPrint(
            '[TableProvider] Loaded bill ID from persistent storage: $persistedBillId',
          );
          // Update the table with persisted bill ID
          final tableIndex = _tables.indexWhere((t) => t.id == tableId);
          if (tableIndex != -1) {
            _tables[tableIndex] = _tables[tableIndex].copyWith(
              billId: persistedBillId,
            );
            notifyListeners();
          }
          return persistedBillId;
        }
      }

      return table.billId;
    } catch (e) {
      debugPrint(
        '[TableProvider] ERROR: Table with ID $tableId not found, trying persistent storage',
      );
      // Fallback to persistent storage
      final persistedBillId = HiveService.getTableBillId(tableId);
      if (persistedBillId != null && persistedBillId.isNotEmpty) {
        debugPrint(
          '[TableProvider] Found bill ID in persistent storage: $persistedBillId',
        );
      }
      return persistedBillId;
    }
  }

  // Fetch bill details using the new API
  Future<BillDetailsResponse?> getBillDetails(String tableId) async {
    try {
      final billId = getBillId(tableId);
      if (billId == null || billId.isEmpty) {
        debugPrint('[TableProvider] No bill ID found for table $tableId');
        return null;
      }

      debugPrint(
        '[TableProvider] Fetching bill details for table $tableId with billId: $billId',
      );
      final billDetails = await ApiService.getBillDetailByBillId(
        billId: billId,
      );

      if (billDetails != null && billDetails.isSuccess) {
        debugPrint(
          '[TableProvider] Successfully fetched bill details for table $tableId',
        );
        return billDetails;
      } else {
        debugPrint(
          '[TableProvider] Failed to fetch bill details for table $tableId: ${billDetails?.message}',
        );
        return null;
      }
    } catch (e) {
      debugPrint(
        '[TableProvider] Error fetching bill details for table $tableId: $e',
      );
      return null;
    }
  }

  // Get bill amount using the new API (backward compatibility)
  Future<double?> getBillAmount(String tableId) async {
    try {
      final billDetails = await getBillDetails(tableId);
      return billDetails?.data?.billHeadDt.billAmountInclTax;
    } catch (e) {
      debugPrint('[TableProvider] Error getting bill amount for table $tableId: $e');
      return null;
    }
  }

  void addOrderToTable(String tableId, ActiveOrder newOrder) {
    // This is now handled by API calls and refresh
  }

  void setSelectedLocation(String location) {
    _selectedLocation = location;
    notifyListeners(); // Notify location change
  }

  void clearError() {
    _error = null;
    notifyListeners(); // Notify error state change
  }

  Future<void> refreshTables() async {
    final token = _getAuthToken();
    final outletId = _getOutletId();
    if (token != null && outletId != null) {
      await fetchTablesWithAuth(token, outletId);
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
