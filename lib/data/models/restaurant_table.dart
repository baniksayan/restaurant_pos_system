// lib/data/models/restaurant_table.dart
// Replace your existing RestaurantTable class with this complete version:

import 'package:flutter/material.dart';

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  final String location;
  final TableStatus status;
  final bool kotGenerated;
  final bool billGenerated;
  final ReservationInfo? reservationInfo; // FIX: Add this property

  const RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    required this.location,
    required this.status,
    required this.kotGenerated,
    required this.billGenerated,
    this.reservationInfo, // FIX: Add to constructor
  });

  RestaurantTable copyWith({
    String? id,
    String? name,
    int? capacity,
    String? location,
    TableStatus? status,
    bool? kotGenerated,
    bool? billGenerated,
    ReservationInfo? reservationInfo,
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
    );
  }

  // Helper method to get status color
  Color get statusColor {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
    }
  }

  // Helper method to check if table is bookable
  bool get isBookable {
    return status == TableStatus.available;
  }
}

enum TableStatus { available, occupied, reserved }

// |  FIX: Complete ReservationInfo class
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

  // Helper to format reservation time display
  String get timeRange => '$startTime - $endTime';

  // Helper to check if reservation is today
  bool get isToday {
    final now = DateTime.now();
    return reservationDate.year == now.year &&
        reservationDate.month == now.month &&
        reservationDate.day == now.day;
  }
}
