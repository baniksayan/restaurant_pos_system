import 'package:flutter/foundation.dart';
import '../models/order_management_model.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class OrdersManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<OrderItem> _tableOrders = [];
  List<OrderItem> _phoneOrders = [];
  List<OrderItem> _takeawayOrders = [];
  List<OrderItem> _channelPartnerOrders = [];

  // Search functionality
  String _searchQuery = '';
  List<OrderItem> _filteredTableOrders = [];
  List<OrderItem> _filteredPhoneOrders = [];
  List<OrderItem> _filteredTakeawayOrders = [];
  List<OrderItem> _filteredChannelPartnerOrders = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<OrderItem> get tableOrders =>
      _searchQuery.isEmpty
          ? List.unmodifiable(_tableOrders)
          : List.unmodifiable(_filteredTableOrders);
  List<OrderItem> get phoneOrders =>
      _searchQuery.isEmpty
          ? List.unmodifiable(_phoneOrders)
          : List.unmodifiable(_filteredPhoneOrders);
  List<OrderItem> get takeawayOrders =>
      _searchQuery.isEmpty
          ? List.unmodifiable(_takeawayOrders)
          : List.unmodifiable(_filteredTakeawayOrders);
  List<OrderItem> get channelPartnerOrders =>
      _searchQuery.isEmpty
          ? List.unmodifiable(_channelPartnerOrders)
          : List.unmodifiable(_filteredChannelPartnerOrders);

  OrdersManagementProvider();

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final token = HiveService.getAuthToken();
    final outletId = HiveService.getOutletId();
    final maskedToken =
        token.isNotEmpty
            ? '${token.substring(0, token.length > 10 ? 10 : token.length)}...'
            : '<empty>';

    debugPrint('[OrdersProvider] fetchAllOrders START');
    debugPrint('[OrdersProvider] outletId=$outletId, token=$maskedToken');

    if (token.isEmpty || outletId == null) {
      _error = 'Auth token or outlet ID missing';
      _isLoading = false;
      debugPrint('[OrdersProvider] Aborting: missing auth or outlet');
      notifyListeners();
      return;
    }

    try {
      // One call covers every channel type. This used to fetch the channels
      // of each type and then query each channel's running orders — 1 + N
      // requests per tab, around 50 for an outlet with 16 tables — and still
      // filtered to today on the client after downloading everything.
      await _fetchOrders(outletId);

      // Generate dummy channel partner orders for UI demonstration
      _generateDummyChannelPartnerOrders();
    } catch (e) {
      _error = 'Failed to load orders: $e';
      debugPrint('[OrdersProvider] Error during fetchAllOrders: $e');
    } finally {
      _isLoading = false;
      debugPrint(
        '[OrdersProvider] fetchAllOrders FINISH - errors=${_error ?? 'none'}',
      );
      notifyListeners();
    }
  }

  /// Search functionality
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    _performSearch();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredTableOrders.clear();
    _filteredPhoneOrders.clear();
    _filteredTakeawayOrders.clear();
    _filteredChannelPartnerOrders.clear();
    notifyListeners();
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _filteredTableOrders.clear();
      _filteredPhoneOrders.clear();
      _filteredTakeawayOrders.clear();
      _filteredChannelPartnerOrders.clear();
      return;
    }

    // Filter table orders
    _filteredTableOrders =
        _tableOrders.where((order) => _matchesSearchQuery(order)).toList();

    // Filter phone orders
    _filteredPhoneOrders =
        _phoneOrders.where((order) => _matchesSearchQuery(order)).toList();

    // Filter takeaway orders
    _filteredTakeawayOrders =
        _takeawayOrders.where((order) => _matchesSearchQuery(order)).toList();

    // Filter channel partner orders
    _filteredChannelPartnerOrders =
        _channelPartnerOrders
            .where((order) => _matchesSearchQuery(order))
            .toList();
  }

  bool _matchesSearchQuery(OrderItem order) {
    final query = _searchQuery;

    // Search in order ID
    if (order.orderId.toLowerCase().contains(query)) return true;

    // Search in customer name
    if (order.customerName.toLowerCase().contains(query)) return true;

    // Search in phone number
    if (order.phoneNumber?.toLowerCase().contains(query) ?? false) return true;

    // Search in order type
    if (order.orderType.toLowerCase().contains(query)) return true;

    // Search in platform name
    if (order.platformName?.toLowerCase().contains(query) ?? false) return true;

    // Search in table number
    if (order.tableNumber?.toLowerCase().contains(query) ?? false) return true;

    // Search in waiter name
    if (order.waiterName?.toLowerCase().contains(query) ?? false) return true;

    // Search in status
    if (order.statusDisplayText.toLowerCase().contains(query)) return true;

    // Search in items
    for (final item in order.items) {
      if (item.productName.toLowerCase().contains(query)) return true;
    }

    return false;
  }

  /// Loads today's orders in one request and buckets them by channel type.
  Future<void> _fetchOrders(int outletId) async {
    final today = DateTime.now();

    final rows = await ApiService.getOrderHeadList(
      outletId: outletId,
      from: today,
      to: today,
    );

    if (rows == null) {
      _error = 'Failed to load orders';
      debugPrint('[OrdersProvider] getOrderHeadList returned null');
      return;
    }

    debugPrint('[OrdersProvider] getOrderHeadList returned ${rows.length} rows');

    final table = <OrderItem>[];
    final phone = <OrderItem>[];
    final takeaway = <OrderItem>[];

    for (final row in rows) {
      // Sp_GetOrderHeadList has no payment filter — it returns every order in
      // the range, settled or not. A live-orders screen wants the ones still
      // in play, so finished orders are dropped here. (The endpoint this
      // replaced, GetRunningTable, filtered them server-side.)
      if (_isSettled(row)) continue;

      final channelType = (row['channelType'] ?? '').toString();
      final order = _mapToOrderItem(row, channelType);
      if (order == null) continue;

      switch (channelType.toLowerCase()) {
        case 'table':
          table.add(order);
          break;
        case 'phone':
          phone.add(order);
          break;
        case 'takeaway':
          takeaway.add(order);
          break;
        default:
          // An order on some other channel type still belongs somewhere
          // visible rather than being silently dropped.
          takeaway.add(order);
      }
    }

    _tableOrders = table;
    _phoneOrders = phone;
    _takeawayOrders = takeaway;

    debugPrint(
      '[OrdersProvider] Bucketed - table:${table.length} '
      'phone:${phone.length} takeaway:${takeaway.length}',
    );

    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  /// Whether this order is finished and should drop off the live list.
  ///
  /// `isPaid` arrives once the Sp_GetOrderHeadList migration is applied; until
  /// then it is absent and nothing is filtered, which is the behaviour before
  /// that column existed. Cancelled orders are dropped too — they are not
  /// coming back, and leaving them on the list is how the table grid ended up
  /// showing dozens of stale orders.
  bool _isSettled(Map row) {
    final paid = row['isPaid'];
    final isPaid =
        paid is num ? paid.toInt() : int.tryParse(paid?.toString() ?? '') ?? 0;
    if (isPaid >= 1) return true;

    final status = (row['status'] ?? '').toString().toLowerCase();
    return status.contains('cancel');
  }

  /// Builds a list row from a Sp_GetOrderHeadList record.
  OrderItem? _mapToOrderItem(Map item, String channelType) {
    try {
      final orderId = (item['orderId'] ?? '').toString();
      if (orderId.isEmpty) return null;

      final customerName =
          (item['customerName'] ?? '').toString().trim().isNotEmpty
              ? (item['customerName'] as Object).toString().trim()
              : (item['channelName'] ?? '').toString();

      final phone = (item['customerPhNumber'] ?? '').toString();
      final statusStr = (item['status'] ?? '').toString();

      // `amount` arrives once the Sp_GetOrderHeadList migration is applied;
      // until then it is absent and the card shows 0 rather than a wrong
      // figure. The previous code read `totPrice`, which no endpoint here
      // returns, so the amount was always 0 anyway.
      final amountRaw = item['amount'];
      final amount =
          amountRaw is num
              ? amountRaw.toDouble()
              : double.tryParse(amountRaw?.toString() ?? '') ?? 0.0;

      final orderTime = _parseCreatedOn(item['createdOn']);
      final tableName = (item['channelName'] ?? '').toString();
      final waiterName = (item['waiterName'] ?? '').toString();

      return OrderItem(
        orderId: orderId,
        customerName: customerName.isNotEmpty ? customerName : 'Guest',
        phoneNumber: phone.isNotEmpty ? phone : null,
        orderType: switch (channelType.toLowerCase()) {
          'table' => 'Table Orders',
          'phone' => 'Phone Orders',
          _ => 'Takeaway',
        },
        status: _mapStatus(statusStr),
        totalAmount: amount,
        orderTime: orderTime,
        tableNumber: tableName.isNotEmpty ? tableName : null,
        waiterId: (item['waiterId'] ?? '').toString(),
        waiterName: waiterName.isNotEmpty ? waiterName : null,
        items: const [],
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[OrdersProvider] map error: $e');
      return null;
    }
  }

  /// Sp_GetOrderHeadList formats CreatedOn as 'dd/MM/yyyy, hh:mm:ss', which
  /// DateTime.parse cannot read — it expects ISO-8601. Parsed by hand so the
  /// list can be ordered and timestamped correctly rather than every row
  /// falling back to "now".
  DateTime _parseCreatedOn(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return DateTime.now();
    final text = raw.trim();

    final match = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4})(?:,?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(text);

    if (match != null) {
      return DateTime(
        int.parse(match.group(3)!),
        int.parse(match.group(2)!),
        int.parse(match.group(1)!),
        int.tryParse(match.group(4) ?? '0') ?? 0,
        int.tryParse(match.group(5) ?? '0') ?? 0,
        int.tryParse(match.group(6) ?? '0') ?? 0,
      );
    }

    return DateTime.tryParse(text)?.toLocal() ?? DateTime.now();
  }

  OrderStatusType _mapStatus(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('placed') ||
        lower.contains('pending') ||
        lower.contains('await')) {
      return OrderStatusType.pending;
    }
    if (lower.contains('accept')) return OrderStatusType.accepted;
    if (lower.contains('prepare')) return OrderStatusType.preparing;
    if (lower.contains('ready')) return OrderStatusType.ready;
    if (lower.contains('deliver')) return OrderStatusType.delivered;
    if (lower.contains('cancel')) return OrderStatusType.cancelled;
    return OrderStatusType.pending;
  }

  /// Generate dummy channel partner orders for UI demonstration
  void _generateDummyChannelPartnerOrders() {
    final now = DateTime.now();

    _channelPartnerOrders = [
      OrderItem(
        orderId: 'ZO001234',
        customerName: 'Sarah Miller',
        phoneNumber: '+91 9876543210',
        orderType: 'Zomato',
        status: OrderStatusType.pending,
        totalAmount: 850.00,
        orderTime: now.subtract(const Duration(minutes: 2)),
        expectedDeliveryTime: now.add(const Duration(minutes: 28)),
        items: [
          const OrderItemDetail(
            productId: 'item_001',
            productName: 'Chicken Biryani',
            quantity: 2,
            price: 299.00,
            imageUrl: null,
          ),
          const OrderItemDetail(
            productId: 'item_002',
            productName: 'Paneer Butter Masala',
            quantity: 1,
            price: 250.00,
            imageUrl: null,
          ),
        ],
        platformName: 'Zomato',
      ),
      OrderItem(
        orderId: 'SW002156',
        customerName: 'Rajesh Kumar',
        phoneNumber: '+91 8765432109',
        orderType: 'Swiggy',
        status: OrderStatusType.preparing,
        totalAmount: 650.50,
        orderTime: now.subtract(const Duration(minutes: 12)),
        acceptedTime: now.subtract(const Duration(minutes: 10)),
        expectedDeliveryTime: now.add(const Duration(minutes: 18)),
        items: [
          const OrderItemDetail(
            productId: 'item_003',
            productName: 'Margherita Pizza',
            quantity: 1,
            price: 450.00,
            imageUrl: null,
          ),
          const OrderItemDetail(
            productId: 'item_004',
            productName: 'Garlic Bread',
            quantity: 2,
            price: 100.00,
            imageUrl: null,
          ),
        ],
        platformName: 'Swiggy',
      ),
      OrderItem(
        orderId: 'UE003789',
        customerName: 'Priya Sharma',
        phoneNumber: '+91 7654321098',
        orderType: 'Uber Eats',
        status: OrderStatusType.ready,
        totalAmount: 420.00,
        orderTime: now.subtract(const Duration(minutes: 25)),
        acceptedTime: now.subtract(const Duration(minutes: 23)),
        expectedDeliveryTime: now.add(const Duration(minutes: 5)),
        items: [
          const OrderItemDetail(
            productId: 'item_005',
            productName: 'Veg Hakka Noodles',
            quantity: 1,
            price: 180.00,
            imageUrl: null,
          ),
          const OrderItemDetail(
            productId: 'item_006',
            productName: 'Chicken Manchurian',
            quantity: 1,
            price: 240.00,
            imageUrl: null,
          ),
        ],
        platformName: 'Uber Eats',
      ),
      OrderItem(
        orderId: 'ZO004521',
        customerName: 'Amit Patel',
        phoneNumber: '+91 6543210987',
        orderType: 'Zomato',
        status: OrderStatusType.pending,
        totalAmount: 1200.00,
        orderTime: now.subtract(const Duration(minutes: 1)),
        expectedDeliveryTime: now.add(const Duration(minutes: 29)),
        items: [
          const OrderItemDetail(
            productId: 'item_007',
            productName: 'Tandoori Chicken (Full)',
            quantity: 1,
            price: 500.00,
            imageUrl: null,
          ),
          const OrderItemDetail(
            productId: 'item_008',
            productName: 'Butter Naan',
            quantity: 4,
            price: 60.00,
            imageUrl: null,
          ),
          const OrderItemDetail(
            productId: 'item_009',
            productName: 'Dal Makhani',
            quantity: 1,
            price: 220.00,
            imageUrl: null,
          ),
        ],
        platformName: 'Zomato',
      ),
      OrderItem(
        orderId: 'FD005693',
        customerName: 'Neha Singh',
        phoneNumber: '+91 5432109876',
        orderType: 'FoodPanda',
        status: OrderStatusType.accepted,
        totalAmount: 380.00,
        orderTime: now.subtract(const Duration(minutes: 8)),
        acceptedTime: now.subtract(const Duration(minutes: 7)),
        expectedDeliveryTime: now.add(const Duration(minutes: 22)),
        items: [
          const OrderItemDetail(
            productId: 'item_010',
            productName: 'Masala Dosa',
            quantity: 2,
            price: 120.00,
            imageUrl: null,
          ),
          const OrderItemDetail(
            productId: 'item_011',
            productName: 'Filter Coffee',
            quantity: 2,
            price: 70.00,
            imageUrl: null,
          ),
        ],
        platformName: 'FoodPanda',
      ),
    ];

    debugPrint(
      '[OrdersProvider] Generated ${_channelPartnerOrders.length} dummy channel partner orders',
    );

    // Re-apply search if there's an active search query
    if (_searchQuery.isNotEmpty) {
      _performSearch();
    }
  }
}
