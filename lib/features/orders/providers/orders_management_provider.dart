import 'package:flutter/foundation.dart';
import '../models/order_management_model.dart';
import 'package:restaurant_pos_system/data/models/order_channel_list_api_response_model.dart';
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
      // Fetch for each channel type in parallel
      debugPrint(
        '[OrdersProvider] Starting fetch for channel types: Table, Phone, Takeaway',
      );
      await Future.wait([
        _fetchByChannelType(token, outletId, 'Table'),
        _fetchByChannelType(token, outletId, 'Phone'),
        _fetchByChannelType(token, outletId, 'Takeaway'),
      ]);
      debugPrint('[OrdersProvider] All channel fetches completed');

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

  Future<void> _fetchByChannelType(
    String token,
    int outletId,
    String channelType,
  ) async {
    try {
      debugPrint(
        '[OrdersProvider] _fetchByChannelType START - channelType=$channelType',
      );

      // Prepare and log request body for OrderChannelListByType
      final requestBody = {
        'orderChanelType': channelType,
        'outletId': outletId,
      };
      debugPrint(
        '[OrdersProvider] Calling OrderChannelListByType with body: $requestBody',
      );

      final OrderChannelListApiResponseModel? response =
          await ApiService.getOrderChannelListByType(
            token: token,
            outletId: outletId,
            orderChannelType: channelType,
          );

      debugPrint(
        '[OrdersProvider] OrderChannelListByType response: ${response?.isSuccess == true ? 'success' : 'null/failed'}',
      );

      if (response == null || response.isSuccess != true) return;

      final channelIds =
          response.data
              ?.where(
                (t) =>
                    (t.channelType ?? '').toLowerCase() ==
                    channelType.toLowerCase(),
              )
              .map((t) => t.orderChannelId)
              .whereType<String>()
              .toList() ??
          [];

      debugPrint(
        '[OrdersProvider] Found ${channelIds.length} channelIds for $channelType: ${channelIds.isNotEmpty ? channelIds.join(', ') : '<none>'}',
      );

      if (channelIds.isEmpty) return;

      // Call getRunningTable for all channels in parallel
      debugPrint(
        '[OrdersProvider] Calling getRunningTable for each channel (parallel)',
      );
      final futures =
          channelIds.map((id) {
            final body = {
              'searchString': '',
              'outletId': outletId,
              'orderChannelId': id,
              'isDesc': true,
            };
            debugPrint(
              '[OrdersProvider] getRunningTable request body for channel $id: $body',
            );
            return ApiService.getRunningTable(
              token: token,
              outletId: outletId,
              orderChannelId: id,
            );
          }).toList();

      final results = await Future.wait(futures);

      debugPrint(
        '[OrdersProvider] getRunningTable responses received: ${results.length}',
      );

      // Aggregate orders and filter for today's date
      final List<OrderItem> aggregated = [];
      for (var i = 0; i < results.length; i++) {
        final res = results[i];
        final channelId = channelIds.length > i ? channelIds[i] : '<unknown>';
        if (res == null) {
          debugPrint(
            '[OrdersProvider] getRunningTable returned null for channel $channelId',
          );
          continue;
        }
        final data = res['data'];
        if (data is List) {
          debugPrint(
            '[OrdersProvider] Channel $channelId returned ${data.length} items',
          );
          for (final item in data) {
            if (item is Map) {
              final id = (item['orderId'] ?? '<no-id>').toString();
              if (!_isFromToday(item)) {
                debugPrint(
                  '[OrdersProvider] Skipping order $id (not from today)',
                );
                continue;
              }

              final order = _mapToOrderItem(item, channelType);
              if (order != null) {
                debugPrint(
                  '[OrdersProvider] Mapped order ${order.orderId} - table:${order.tableNumber} amount:${order.totalAmount}',
                );
                aggregated.add(order);
              } else {
                debugPrint(
                  '[OrdersProvider] Failed to map order for item: $item',
                );
              }
            }
          }
        } else {
          debugPrint(
            '[OrdersProvider] Unexpected response data for channel $channelId: ${res.runtimeType}',
          );
        }
      }

      // Update proper list
      switch (channelType.toLowerCase()) {
        case 'table':
          _tableOrders = aggregated;
          break;
        case 'phone':
          _phoneOrders = aggregated;
          break;
        case 'takeaway':
          _takeawayOrders = aggregated;
          break;
      }
      debugPrint(
        '[OrdersProvider] Finished aggregation for $channelType - total kept: ${aggregated.length}',
      );

      // Re-apply search if there's an active search query
      if (_searchQuery.isNotEmpty) {
        _performSearch();
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[OrdersProvider] Error fetching $channelType: $e');
    }
  }

  bool _isFromToday(Map item) {
    final today = DateTime.now();
    // Try a few keys that may contain dates
    final candidates = <String>['createdOn'];
    for (final key in candidates) {
      if (item.containsKey(key) && item[key] is String) {
        try {
          final dt = DateTime.parse(item[key]).toLocal();
          if (dt.year == today.year &&
              dt.month == today.month &&
              dt.day == today.day) {
            return true;
          }
        } catch (_) {
          // ignore parse errors
        }
      }
    }

    // Fallback: check if generatedOrderNo contains today's ddmmyy or yymmdd patterns
    if (item.containsKey('generatedOrderNo') &&
        item['generatedOrderNo'] is String) {
      final gen = item['generatedOrderNo'] as String;
      final now = DateTime.now();
      final ddmmyy =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${(now.year % 100).toString().padLeft(2, '0')}';
      if (gen.contains(ddmmyy)) return true;
    }

    return false;
  }

  OrderItem? _mapToOrderItem(Map item, String channelType) {
    try {
      final orderId = (item['orderId'] ?? '').toString();
      final customerName =
          (item['customerName'] ?? item['channelName'] ?? '').toString();
      final phone =
          (item['customerPhNumber'] ?? item['customerPhNo'] ?? '').toString();
      final statusStr = (item['status'] ?? '').toString();
      final amountRaw = item['totPrice'];
      final amount =
          amountRaw is num
              ? amountRaw.toDouble()
              : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;

      DateTime orderTime = DateTime.now();
      if (item.containsKey('createdOn') && item['createdOn'] is String) {
        try {
          orderTime = DateTime.parse(item['createdOn']).toLocal();
        } catch (_) {}
      }

      final tableName = (item['channelName'] ?? '').toString();
      final waiterName = (item['waiterName'] ?? '').toString();

      return OrderItem(
        orderId: orderId,
        customerName: customerName.isNotEmpty ? customerName : 'Guest',
        phoneNumber: phone.isNotEmpty ? phone : null,
        orderType:
            channelType == 'Table'
                ? 'Table Orders'
                : channelType == 'Phone'
                ? 'Phone Orders'
                : 'Takeaway',
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
