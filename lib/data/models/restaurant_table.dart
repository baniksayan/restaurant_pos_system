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

  /// Adults seated, summed across every party on the table. Null when the
  /// server has not reported counts for any order.
  int? get seatedAdults => _sumGuests((o) => o.totalAdult);

  /// Children seated, summed across every party on the table.
  int? get seatedChildren => _sumGuests((o) => o.totalChild);

  /// Sums one guest field across the table's orders, returning null when no
  /// order reported it — "unknown" and "nobody" are different answers.
  int? _sumGuests(int? Function(ActiveOrder order) field) {
    var total = 0;
    var known = false;
    for (final order in activeOrders) {
      final value = field(order);
      if (value != null) {
        total += value;
        known = true;
      }
    }
    return known ? total : null;
  }

  /// Guests currently seated, summed across every party on the table.
  ///
  /// Null when the server has not reported guest counts for any order — the
  /// channel list only carries them once the accompanying
  /// Sp_GetOrderChannelListByType migration is applied. Null means "unknown",
  /// which is different from zero, so callers can hide the figure rather than
  /// claim an empty table.
  int? get seatedGuests {
    var total = 0;
    var known = false;
    for (final order in activeOrders) {
      final guests = order.guestCount;
      if (guests != null) {
        total += guests;
        known = true;
      }
    }
    return known ? total : null;
  }

  /// Seats still free, or null when the guest count or capacity is unknown.
  int? get freeSeats {
    final seated = seatedGuests;
    if (seated == null || capacity <= 0) return null;
    return capacity - seated;
  }

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
        return const Color(0xFF10B981);
      case TableStatus.occupied:
        return const Color(0xFFEF4444);
      case TableStatus.kotGenerated:
        return const Color.fromRGBO(139, 92, 246, 1);
      case TableStatus.billGenerated:
        return const Color(0xFF3B82F6);
      case TableStatus.billSettled:
        return const Color(0xFF06B6D4);
      case TableStatus.reserved:
        return const Color(0xFFF59E0B);
      case TableStatus.outOfOrder:
        return const Color(0xFF64748B);
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.kotGenerated:
        return 'KOT Generated';
      case TableStatus.billGenerated:
        return 'Bill Generated';
      case TableStatus.billSettled:
        return 'Bill Settled';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.outOfOrder:
        return 'Out of Order';
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

  /// Bill generated for THIS order, resolved from local storage.
  ///
  /// Lives per order rather than per table: a table can host several groups
  /// at once, each with its own bill, and the API cannot give a bill id back
  /// (getOrderDetailById returns none), so this is the only record of it.
  final String? billId;

  /// Guests on this order. Null until the channel-list proc returns them.
  final int? totalAdult;
  final int? totalChild;

  const ActiveOrder({
    required this.orderId,
    required this.generatedOrderNo,
    required this.orderStatus,
    required this.isBilled,
    this.billId,
    this.totalAdult,
    this.totalChild,
  });

  /// Guests on this order, or null when the server has not sent the counts.
  int? get guestCount {
    if (totalAdult == null && totalChild == null) return null;
    return (totalAdult ?? 0) + (totalChild ?? 0);
  }

  ActiveOrder copyWith({
    String? orderId,
    String? generatedOrderNo,
    String? orderStatus,
    bool? isBilled,
    String? billId,
    bool clearBillId = false,
    int? totalAdult,
    int? totalChild,
  }) {
    return ActiveOrder(
      orderId: orderId ?? this.orderId,
      generatedOrderNo: generatedOrderNo ?? this.generatedOrderNo,
      orderStatus: orderStatus ?? this.orderStatus,
      isBilled: isBilled ?? this.isBilled,
      billId: clearBillId ? null : (billId ?? this.billId),
      totalAdult: totalAdult ?? this.totalAdult,
      totalChild: totalChild ?? this.totalChild,
    );
  }

  // Factory for NEW API (OrderChannelListByType)
  factory ActiveOrder.fromNewApiOrderList(new_api.OrderList orderList) {
    return ActiveOrder(
      orderId: orderList.orderId ?? '',
      generatedOrderNo: orderList.generatedOrderNo ?? '',
      orderStatus: orderList.orderStatus ?? '',
      isBilled: orderList.isBilled ?? false,
      totalAdult: orderList.totalAdult,
      totalChild: orderList.totalChild,
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

// ✅ ENHANCED: 5-state table status system
enum TableStatus {
  available,
  occupied,
  kotGenerated,
  billGenerated,
  billSettled,
  reserved,
  outOfOrder,
}

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
