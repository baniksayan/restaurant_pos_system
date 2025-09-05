import 'package:flutter/material.dart';

import 'order_channel_list_api_response_model.dart' as new_api;
import 'tables_api_response_model.dart' as legacy_api;

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  final String location;
  final TableStatus status;
  final bool kotGenerated;
  final bool billGenerated;
  final ReservationInfo? reservationInfo;
  final List<ActiveOrder> activeOrders; // NEW: Multiple orders support

  const RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    required this.location,
    required this.status,
    required this.kotGenerated,
    required this.billGenerated,
    this.reservationInfo,
    this.activeOrders = const [], // NEW: Default empty list
  });

  // NEW: Check if table has multiple orders (shared table)
  bool get isSharedTable => activeOrders.length > 1;

  // NEW: Check if table has any orders
  bool get hasActiveOrders => activeOrders.isNotEmpty;

  // NEW: Get order count
  int get orderCount => activeOrders.length;

  RestaurantTable copyWith({
    String? id,
    String? name,
    int? capacity,
    String? location,
    TableStatus? status,
    bool? kotGenerated,
    bool? billGenerated,
    ReservationInfo? reservationInfo,
    List<ActiveOrder>? activeOrders,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      status: status ?? this.status,
      kotGenerated: kotGenerated ?? this.kotGenerated,
      billGenerated: billGenerated ?? this.billGenerated,
      reservationInfo: reservationInfo ?? this.reservationInfo,
      activeOrders: activeOrders ?? this.activeOrders,
    );
  }

  Color get statusColor {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
      case TableStatus.outOfOrder:
        return Colors.grey;
    }
  }

  bool get isBookable {
    return status == TableStatus.available;
  }
}

// NEW: Active Order class for multiple orders per table
class ActiveOrder {
  final String orderId;
  final String generatedOrderNo;
  final String orderStatus;
  final bool isBilled;

  const ActiveOrder({
    required this.orderId,
    required this.generatedOrderNo,
    required this.orderStatus,
    required this.isBilled,
  });

  // Factory for NEW API (OrderChannelListByType)
  factory ActiveOrder.fromNewApiOrderList(new_api.OrderList orderList) {
    return ActiveOrder(
      orderId: orderList.orderId ?? '',
      generatedOrderNo: orderList.generatedOrderNo ?? '',
      orderStatus: orderList.orderStatus ?? '',
      isBilled: orderList.isBilled ?? false,
    );
  }

  // Factory for LEGACY API (TablesApiResponseModel)
  factory ActiveOrder.fromLegacyApiOrderList(legacy_api.OrderList orderList) {
    return ActiveOrder(
      orderId: orderList.orderId ?? '',
      generatedOrderNo: orderList.generatedOrderNo ?? '',
      orderStatus: orderList.orderStatus ?? '',
      isBilled: orderList.isBilled ?? false,
    );
  }

  // Generic factory method for backward compatibility
  factory ActiveOrder.fromOrderList(dynamic orderList) {
    return ActiveOrder(
      orderId: orderList.orderId ?? '',
      generatedOrderNo: orderList.generatedOrderNo ?? '',
      orderStatus: orderList.orderStatus ?? '',
      isBilled: orderList.isBilled ?? false,
    );
  }
}

// ✅ FIXED: Added outOfOrder to enum
enum TableStatus { available, occupied, reserved, outOfOrder }

class ReservationInfo {
  final String startTime;
  final String endTime;
  final String occasion;
  final int guestCount;
  final DateTime reservationDate;
  final double totalAmount;
  final String customerName;
  final String? specialRequests;

  const ReservationInfo({
    required this.startTime,
    required this.endTime,
    required this.occasion,
    required this.guestCount,
    required this.reservationDate,
    required this.totalAmount,
    required this.customerName,
    this.specialRequests,
  });

  ReservationInfo copyWith({
    String? startTime,
    String? endTime,
    String? occasion,
    int? guestCount,
    DateTime? reservationDate,
    double? totalAmount,
    String? customerName,
    String? specialRequests,
  }) {
    return ReservationInfo(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      occasion: occasion ?? this.occasion,
      guestCount: guestCount ?? this.guestCount,
      reservationDate: reservationDate ?? this.reservationDate,
      totalAmount: totalAmount ?? this.totalAmount,
      customerName: customerName ?? this.customerName,
      specialRequests: specialRequests ?? this.specialRequests,
    );
  }

  String get timeRange => '$startTime - $endTime';

  bool get isToday {
    final now = DateTime.now();
    return reservationDate.year == now.year &&
        reservationDate.month == now.month &&
        reservationDate.day == now.day;
  }
}
