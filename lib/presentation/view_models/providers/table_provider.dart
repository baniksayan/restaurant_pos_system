import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/services/api_service.dart';
import '../../../data/models/restaurant_table.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/models/order_channel.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;
  String? _error;
  String _selectedLocation = 'Main Hall';
  int _outletId = 47;

  // Multi-order support
  Map<String, List<Map<String, dynamic>>> _orderCartStates = {};
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
  int get outletId => _outletId;
  String? get currentOrderId => _currentOrderId;

  // Legacy getters
  bool get isApiLoading => _isApiLoading;
  String? get tableApiError => _tableApiError;
  List<OrderChannel> get orderChannels => _orderChannels;

  void setOutletId(int outletId) {
    _outletId = outletId;
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
        print('[TableProvider] Missing auth token or outlet ID');
      }
    }
  }

  /// Get outlet ID
  int? _getOutletId() {
    return _outletId;
  }

  /// Fetch tables using ONLY API data - FIXED UI UPDATE
  Future<void> fetchTablesWithAuth(String token, int outletId) async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // First notification: Loading state
    try {
      print('[TableProvider] Fetching REAL API tables - Outlet: $outletId');
      final tables = await TableRepository.fetchTablesFromOrderChannelAPI(
        token: token,
        outletId: outletId,
      );

      // CRITICAL FIX: Force list replacement to trigger UI update
      _tables = List<RestaurantTable>.from(tables); // Create new list instance

      if (_tables.isEmpty) {
        _error = 'No tables found for this outlet. Check backend configuration.';
        print('[TableProvider] API returned no tables - Check backend data');
      } else {
        print('[TableProvider] Successfully loaded ${_tables.length} REAL tables from API');
        for (final table in _tables) {
          print('[TableProvider] API Table: ${table.name} (${table.location}) - Orders: ${table.activeOrders.length}');
        }
      }
    } catch (e) {
      _error = 'Failed to fetch tables: ${e.toString()}';
      _tables = []; // Empty list if API fails
      print('[TableProvider] API Error: $e');
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
      print('[TableProvider] fetchTablesByOutlet called - Outlet: $outletId');
      print('[TableProvider] Token: ${token.substring(0, 10)}...');

      // Call the API service directly
      final response = await ApiService.getOrderChannelListByType(
        token: token,
        outletId: outletId,
        orderChannelType: "Table",
      );

      if (response != null && response.isSuccess == true) {
        // Map API response to OrderChannel objects for legacy compatibility
        _orderChannels = response.data
                ?.map(
                  (tableData) => OrderChannel(
                    orderChannelId: tableData.orderChannelId ?? '',
                    channelType: tableData.channelType ?? '',
                    name: tableData.name ?? '',
                    capacity: tableData.capacity ?? 0,
                    orderList: tableData.orderList
                            ?.map(
                              (order) =>
                                  // FIXED: Properly convert to OrderChannel's OrderList structure
                                  OrderInfo(
                                orderId: order.orderId ?? '',
                                isBilled: order.isBilled ?? false,
                                orderStatus: order.orderStatus ?? '',
                                generatedOrderNo: order.generatedOrderNo ?? '',
                              ),
                            )
                            ?.toList() ??
                        [],
                  ),
                )
                ?.toList() ??
            [];

        // Also update the main tables list
        await fetchTablesWithAuth(token, outletId);

        print('[TableProvider] fetchTablesByOutlet Success - Found ${_orderChannels.length} tables');
      } else {
        _tableApiError = 'API returned unsuccessful response';
        _orderChannels = [];
        print('[TableProvider] fetchTablesByOutlet Failed - ${response?.message}');
      }
    } catch (e) {
      _tableApiError = 'Error: $e';
      _orderChannels = [];
      print('[TableProvider] fetchTablesByOutlet Error: $e');
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
    filteredTables = filteredTables.where((table) => table.location == locationName).toList();

    // Filter by status if provided
    if (statusFilter != null && statusFilter != 'all') {
      switch (statusFilter) {
        case 'available':
          filteredTables = filteredTables.where((table) => table.status == TableStatus.available).toList();
          break;
        case 'occupied':
          filteredTables = filteredTables.where((table) => table.status == TableStatus.occupied).toList();
          break;
        case 'reserved':
          filteredTables = filteredTables.where((table) => table.status == TableStatus.reserved).toList();
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
        print('[Error] Missing authentication credentials');
        return false;
      }

      print('[Table Manager] Table $tableName tapped - Status: available');
      print('[Popup] Options shown: Occupy & Order, Reserve');

      // Step 1: Create new order using saveOrderHead API
      final orderResponse = await ApiService.saveOrderHead(
        token: token,
        orderChannelId: tableId,
        waiterId: waiterId ?? userId, // Use userId as fallback
        customerName: 'Walk-in Customer',
        outletId: _outletId,
        userId: userId,
      );

      if (orderResponse != null && orderResponse.isSuccess == true) {
        final orderId = orderResponse.data?.orderId;
        final generatedOrderNo = orderResponse.data?.generatedOrderNo;

        if (orderId != null && generatedOrderNo != null) {
          print('[API Call] saveOrderHead Success - Order Created');
          print('[Order Created] ID: $orderId');
          print('[Order Created] Number: $generatedOrderNo');

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

        print('[Error] Failed to create order - API response: ${orderResponse?.message}');
        return false;
      }
    } catch (e) {
      print('[Error] Creating order: $e');
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
            generatedOrderNo: generatedOrderNo ?? 'ORD/${DateTime.now().millisecondsSinceEpoch}',
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
  Future<void> loadCartStateForOrder(String orderId) async {
    try {
      final token = _getAuthToken();
      if (token == null) return;
      print('[Table Manager] Loading cart for order: $orderId');
      print('[API Call] getOrderDetailById - Order $orderId');
      final orderDetails = await ApiService.getOrderDetailById(
        token: token,
        orderId: orderId,
      );

      if (orderDetails != null && orderDetails.isSuccess == true && orderDetails.data != null) {
        // Convert order details to cart items
        final cartItems = orderDetails.data!.first.orderDetailList
                ?.map(
                  (item) => {
                    'productId': item.productId,
                    'productName': item.productName,
                    'quantity': item.productQty,
                    'price': item.itemPrice,
                    'totalPrice': item.totPrice,
                  },
                )
                ?.toList() ??
            [];

        _orderCartStates[orderId] = cartItems;
        _currentOrderId = orderId;

        print('[Cart Loaded] Order $orderId with ${cartItems.length} items');
        notifyListeners(); // CRITICAL: Notify when cart state changes
      }
    } catch (e) {
      print('[Error] Loading cart state: $e');
    }
  }

  /// Remove order from table (API-driven) - FIXED
  Future<bool> removeOrderFromTable(String tableId, String orderId) async {
    try {
      final token = _getAuthToken();
      final userId = HiveService.getUserId();
      if (token == null || userId == null) return false;

      // Call UpdateOrderHeadStatus API to cancel/remove order
      final result = await ApiService.updateOrderHeadStatus(
        token: token,
        orderHeadId: orderId,
        statusId: 7, // Assuming 7 means cancelled/removed
        userId: userId,
      );

      if (result != null && result['isSuccess'] == true) {
        print('[Order Removed] ID: $orderId');

        // Update local state immediately
        final tableIndex = _tables.indexWhere((t) => t.id == tableId);
        if (tableIndex != -1) {
          final currentOrders = _tables[tableIndex].activeOrders.where((order) => order.orderId != orderId).toList();
          final newStatus = currentOrders.isEmpty ? TableStatus.available : TableStatus.occupied;

          _tables[tableIndex] = _tables[tableIndex].copyWith(
            activeOrders: currentOrders,
            status: newStatus,
          );

          if (currentOrders.isEmpty) {
            print('[API Call] Table $tableId -> Available (no more orders)');
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
      print('[Error] Removing order: $e');
      return false;
    }
    return false;
  }

  /// Set current active order - NEWLY ADDED METHOD
  void setCurrentOrder(String orderId) {
    _currentOrderId = orderId;
    print('[Navigation] Redirecting to Menu with Order ID $orderId');
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
    print('[Cart] Cleared cart for order: $orderId');
    notifyListeners();
  }

  /// Add item to current order's cart - NEWLY ADDED METHOD
  void addItemToCart(String orderId, Map<String, dynamic> item) {
    if (_orderCartStates[orderId] == null) {
      _orderCartStates[orderId] = [];
    }
    _orderCartStates[orderId]!.add(item);
    print('[Cart] Added item to order $orderId: ${item['productName']}');
    notifyListeners();
  }

  /// Update item quantity in cart - NEWLY ADDED METHOD
  void updateItemQuantity(String orderId, String productId, int quantity) {
    if (_orderCartStates[orderId] == null) return;

    final items = _orderCartStates[orderId]!;
    final itemIndex = items.indexWhere((item) => item['productId'] == productId);

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

    _orderCartStates[orderId]!.removeWhere((item) => item['productId'] == productId);
    print('[Cart] Removed item from order $orderId: $productId');
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
    // This is now handled by API calls and refresh
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
