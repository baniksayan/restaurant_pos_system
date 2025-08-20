// lib/data/models/reservation.dart
class Reservation {
  final String id;
  final String tableId;
  final String tableName;
  final int persons;
  final DateTime fromTime;
  final DateTime toTime;
  final String occasion;
  final double basePrice;
  final double finalPrice;
  final bool decoration;
  final bool advanceOrder;
  final DateTime createdAt;
  final String status;

  Reservation({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.persons,
    required this.fromTime,
    required this.toTime,
    required this.occasion,
    required this.basePrice,
    required this.finalPrice,
    this.decoration = false,
    this.advanceOrder = false,
    required this.createdAt,
    this.status = 'confirmed',
  });

  Duration get duration => toTime.difference(fromTime);
  
  double get durationInHours => duration.inMinutes / 60.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'tableName': tableName,
      'persons': persons,
      'fromTime': fromTime.toIso8601String(),
      'toTime': toTime.toIso8601String(),
      'occasion': occasion,
      'basePrice': basePrice,
      'finalPrice': finalPrice,
      'decoration': decoration,
      'advanceOrder': advanceOrder,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      tableId: json['tableId'],
      tableName: json['tableName'],
      persons: json['persons'],
      fromTime: DateTime.parse(json['fromTime']),
      toTime: DateTime.parse(json['toTime']),
      occasion: json['occasion'],
      basePrice: json['basePrice'].toDouble(),
      finalPrice: json['finalPrice'].toDouble(),
      decoration: json['decoration'] ?? false,
      advanceOrder: json['advanceOrder'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'confirmed',
    );
  }
}
