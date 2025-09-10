import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/data/models/order_management_model.dart';
import 'package:restaurant_pos_system/data/models/order_channel_list_api_response_model.dart';
import 'package:restaurant_pos_system/services/api_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class OrdersManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<OrderItem> _tableOrders = [];
  List<OrderItem> _phoneOrders = [];
  List<OrderItem> _takeawayOrders = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OrderItem> get tableOrders => List.unmodifiable(_tableOrders);
  List<OrderItem> get phoneOrders => List.unmodifiable(_phoneOrders);
  List<OrderItem> get takeawayOrders => List.unmodifiable(_takeawayOrders);

  OrdersManagementProvider();

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final token = HiveService.getAuthToken();
    final outletId = 47;
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
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[OrdersProvider] Error fetching $channelType: $e');
    }
  }

  bool _isFromToday(Map item) {
    final today = DateTime.now();
    // Try a few keys that may contain dates
    final candidates = <String>[
      'custDOB',
      'orderTime',
      'orderDate',
      'createdDate',
      'generatedDate',
    ];
    for (final key in candidates) {
      if (item.containsKey(key) && item[key] is String) {
        try {
          final dt = DateTime.parse(item[key]).toLocal();
          if (dt.year == today.year &&
              dt.month == today.month &&
              dt.day == today.day){
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
      final statusStr = (item['orderStatus'] ?? '').toString();
      final amountRaw = item['amount'];
      final amount =
          amountRaw is num
              ? amountRaw.toDouble()
              : double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;

      DateTime orderTime = DateTime.now();
      if (item.containsKey('custDOB') && item['custDOB'] is String) {
        try {
          orderTime = DateTime.parse(item['custDOB']).toLocal();
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
      if (kDebugMode) print('[OrdersProvider] map error: $e');
      return null;
    }
  }

  OrderStatusType _mapStatus(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('placed') ||
        lower.contains('pending') ||
        lower.contains('await'))
      return OrderStatusType.pending;
    if (lower.contains('accept')) return OrderStatusType.accepted;
    if (lower.contains('prepare')) return OrderStatusType.preparing;
    if (lower.contains('ready')) return OrderStatusType.ready;
    if (lower.contains('deliver')) return OrderStatusType.delivered;
    if (lower.contains('cancel')) return OrderStatusType.cancelled;
    return OrderStatusType.pending;
  }
}
