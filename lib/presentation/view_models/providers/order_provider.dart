import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/data/models/create_kot_with_order_details_api_res_model.dart';
import '../../../data/models/order.dart';
import '../../../services/api_service.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/models/order_channel_list_api_response_model.dart';

class OrderProvider with ChangeNotifier {
  List _orders = [];
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get required data from Hive
      final userId = HiveService.getUserId();
      final waiterId = HiveService.getWaiterId();
      final outletId = HiveService.getOutletId();

      if (userId == null || waiterId == null || outletId == null) {
        _error = 'Missing user authentication data';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Step 1: Get order channels by type
      final token = HiveService.getAuthToken();
      if (token.isEmpty) {
        _error = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Map orderChannelType to API expected format
      String apiChannelType = orderChannelType;
      if (orderChannelType == 'PhoneOrder') {
        apiChannelType = 'Phone';
      }

      final channelsResponse = await ApiService.getOrderChannelListByType(
        token: token,
        orderChannelType: apiChannelType,
        outletId: outletId,
      );

      if (channelsResponse == null ||
          channelsResponse.data == null ||
          channelsResponse.data!.isEmpty) {
        _error = 'No $orderChannelType channels available';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Use the first available channel
      final orderChannel = channelsResponse.data!.first;

      // Step 2: Create order head
      final success = await createOrderHead(
        orderChannelId: orderChannel.orderChannelId!,
        waiterId: waiterId,
        customerName: customerName,
        outletId: outletId,
        userId: userId,
        custPhoneNo: customerPhone,
        totalAdult: 0,
        totalChild: 0,
      );

      return success;
    } catch (e) {
      _error = 'Error creating $orderChannelType order: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
