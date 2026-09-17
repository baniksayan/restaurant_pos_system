import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/data/models/create_kot_with_order_details_api_res_model.dart';
import 'package:restaurant_pos_system/data/models/order.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class OrderProvider with ChangeNotifier {
  final List _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  // Order Head Creation Properties
  String? _createdOrderId;
  String? _generatedOrderNo;
  int? _orderNo;

  // Getters
  List get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get createdOrderId => _createdOrderId;
  String? get generatedOrderNo => _generatedOrderNo;
  int? get orderNo => _orderNo;

  void addOrder(Order order) {
    _orders.add(order);
    notifyListeners();
  }

  void updateOrder(Order order) {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
      notifyListeners();
    }
  }

  void setCurrentOrder(Order? order) {
    _currentOrder = order;
    notifyListeners();
  }

  // Create Order Head via API
  Future<bool> createOrderHead({
    required String orderChannelId,
    required String waiterId,
    required String customerName,
    required int outletId,
    required String userId,
    String? custPhoneNo,
    int? totalAdult,
    int? totalChild,
    String? custEmailId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.createOrderHead(
        orderChannelId: orderChannelId,
        waiterId: waiterId,
        customerName: customerName,
        outletId: outletId,
        userId: userId,
        custPhoneNo: custPhoneNo,
        totalAdult: totalAdult,
        totalChild: totalChild,
        custEmailId: custEmailId,
      );

      if (result != null && result.isSuccess == true) {
        _createdOrderId = result.data?.orderId;
        _generatedOrderNo = result.data?.generatedOrderNo;
        _orderNo = result.data?.orderNo;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result?.data?.response ?? 'Failed to create order head';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error creating order head: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create KOT with Order Details
  Future<CreateKotWithOrderDetailsApiResModel?> createKotWithOrderDetails({
    required String userId,
    required int outletId,
    required String orderId,
    String kotNote = "",
    required List<Map<String, dynamic>>
    cartItems, // Changed from List<CartItem>
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Convert cart items to match the exact Postman format that works
      final orderDetails =
          cartItems.map((item) {
            // Match exact Postman format and field order
            final orderDetail = <String, dynamic>{
              "productId": item['id'],
              "productName": item['name'],
              "categoryId": item['categoryId'] ?? "",
              "categoryName": item['categoryName'] ?? "",
              "productPrice": item['price'],
              "discountPercentage": item['discountPercentage'] ?? 0,
              "uom": item['uom'] ?? "Plate",
              "quantity": item['quantity'],
              "note": item['specialNotes'] ?? "",
            };

            return orderDetail;
          }).toList();

      if (kDebugMode) {
        debugPrint('createKotWithOrderDetails payload: $orderDetails');
      }

      final result = await ApiService.createKotWithOrderDetails(
        userId: userId,
        outletId: outletId,
        orderId: orderId,
        kotNote: kotNote,
        orderDetails: orderDetails,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Error creating KOT with order details: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Clear order head data
  void clearOrderHead() {
    _createdOrderId = null;
    _generatedOrderNo = null;
    _orderNo = null;
    _error = null;
    notifyListeners();
  }

  /// Wipes all in-memory state on logout.
  void reset() => clearOrderHead();

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Create Phone/Takeaway Order
  Future<bool> createPhoneTakeawayOrder({
    required String orderChannelType,
    required String customerName,
    required String customerPhone,
  }) async {
    _error = null;
    // Do NOT set _isLoading here — createOrderHead manages it and will
    // set it true then false itself. Setting it true here and relying on
    // createOrderHead to clear it means any early-return path above that
    // call leaves _isLoading stuck true, blocking the KOT button.

    try {
      final userId = HiveService.getUserId();
      final waiterId = HiveService.getWaiterId();
      final outletId = HiveService.getOutletId();
      final token = HiveService.getAuthToken();

      if (userId == null || waiterId == null || outletId == null || token.isEmpty) {
        _error = 'Missing user authentication data';
        notifyListeners();
        return false;
      }

      // 'Phone' and 'PhoneOrder' are both used as sentinels in different
      // places — normalise to what the channel-list endpoint expects.
      final apiChannelType = (orderChannelType == 'PhoneOrder') ? 'Phone' : orderChannelType;

      final channelsResponse = await ApiService.getOrderChannelListByType(
        token: token,
        orderChannelType: apiChannelType,
        outletId: outletId,
      );

      if (channelsResponse == null ||
          channelsResponse.data == null ||
          channelsResponse.data!.isEmpty) {
        _error = 'No $orderChannelType channels available';
        notifyListeners();
        return false;
      }

      final orderChannel = channelsResponse.data!.first;

      return await createOrderHead(
        orderChannelId: orderChannel.orderChannelId!,
        waiterId: waiterId,
        customerName: customerName,
        outletId: outletId,
        userId: userId,
        custPhoneNo: customerPhone,
        totalAdult: 1,
        totalChild: 0,
      );
    } catch (e) {
      _error = 'Error creating $orderChannelType order: $e';
      notifyListeners();
      return false;
    } finally {
      // Ensure loading is always cleared regardless of which path was taken.
      _isLoading = false;
      notifyListeners();
    }
  }
}
