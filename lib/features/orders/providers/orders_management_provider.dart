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
  // No backend endpoint exists for this channel yet — always empty, never
  // reassigned, so nothing here fabricates sample orders to fill it.
  final List<OrderItem> _channelPartnerOrders = [];

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

  // Date range — defaults to today
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;

  OrdersManagementProvider();

  Future<void> fetchOrdersForRange(DateTime from, DateTime to) async {
    _fromDate = from;
    _toDate = to;
    await fetchAllOrders();
  }

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
      //
      // Channel Partner (Zomato/Swiggy/etc.) has no backend endpoint at all
      // — no controller action anywhere in PosWebApi fetches or updates
      // third-party orders. That tab stays empty rather than showing
      // fabricated sample orders, which used to look like a live feed.
      await _fetchOrders(outletId);
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

  /// Loads orders for the selected date range and buckets them by channel type.
  Future<void> _fetchOrders(int outletId) async {
    final rows = await ApiService.getOrderHeadList(
      outletId: outletId,
      from: _fromDate,
      to: _toDate,
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

    // Sp_GetOrderHeadList has no ORDER BY guarantee callers can rely on
    // (and no pageNumber/pageSize on ReqOrderHeadList either — the server
    // hands back the whole range in one response) — newest first is sorted
    // here so the most recently placed order is always what the waiter
    // sees at the top of each tab.
    int byNewest(OrderItem a, OrderItem b) => b.orderTime.compareTo(a.orderTime);
    table.sort(byNewest);
    phone.sort(byNewest);
    takeaway.sort(byNewest);

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

  /// Builds a list row from a Sp_GetOrderHeadList record.
  OrderItem? _mapToOrderItem(Map item, String channelType) {
    try {
      final orderId = (item['orderId'] ?? '').toString();
      if (orderId.isEmpty) return null;

      final channelNameStr = (item['channelName'] ?? '').toString().trim();
      final rawCustomerName = (item['customerName'] ?? '').toString().trim();
      final customerName =
          rawCustomerName.isNotEmpty ? rawCustomerName : channelNameStr;

      // Table orders show which table this is for, same as the Reprint and
      // Tables screens — "New Table (Walk-in Customer)" rather than just the
      // customer name, which by itself doesn't say where they're sitting.
      // Phone/Takeaway have no table to add, so they stay as just the name.
      final displayName =
          channelType.toLowerCase() == 'table' &&
                  channelNameStr.isNotEmpty &&
                  customerName.isNotEmpty &&
                  customerName != channelNameStr
              ? '$channelNameStr ($customerName)'
              : customerName;

      final phone = (item['customerPhNumber'] ?? '').toString();
      final statusStr = (item['status'] ?? '').toString();

      final paidRaw = item['isPaid'];
      final isPaid =
          paidRaw is num
              ? paidRaw.toInt()
              : int.tryParse(paidRaw?.toString() ?? '') ?? 0;

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
      final tableName = channelNameStr;
      final waiterName = (item['waiterName'] ?? '').toString();

      return OrderItem(
        orderId: orderId,
        customerName: displayName.isNotEmpty ? displayName : 'Guest',
        phoneNumber: phone.isNotEmpty ? phone : null,
        orderType: switch (channelType.toLowerCase()) {
          'table' => 'Table Orders',
          'phone' => 'Phone Orders',
          _ => 'Takeaway',
        },
        // The order's own workflow status (Order Placed/Preparing/...) never
        // advances to anything billing-related — a fully paid dine-in order
        // still reads "Order Placed" — so a finished order is recognised
        // from IsPaid instead, or the badge would call it "Pending" forever.
        status: isPaid >= 1 ? OrderStatusType.completed : _mapStatus(statusStr),
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

}
