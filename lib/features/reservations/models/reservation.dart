class Reservation {
  final String id;
  final String tableId;
  final String tableName;
  final String customerName;  // NEW: Customer name
  final String customerPhone; // NEW: Customer phone
  final int persons;
  final DateTime fromTime;
  final DateTime toTime;
  final String occasion;
  final String? specialNotes; // NEW: Special notes
  final double basePrice;
  final double finalPrice;
  final double advanceAmount; // NEW: Advance payment
  final double remainingAmount; // NEW: Remaining amount
  final bool decoration;
  final DateTime createdAt;
  final String status;
  final String? billNumber; // NEW: Bill number for advance payment

  Reservation({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.customerName,
    required this.customerPhone,
    required this.persons,
    required this.fromTime,
    required this.toTime,
    required this.occasion,
    this.specialNotes,
    required this.basePrice,
    required this.finalPrice,
    required this.advanceAmount,
    required this.remainingAmount,
    this.decoration = false,
    required this.createdAt,
    this.status = 'confirmed',
    this.billNumber,
  });

  Duration get duration => toTime.difference(fromTime);
  
  double get durationInHours => duration.inMinutes / 60.0;
  
  // Calculate minimum advance amount (20% of total or ₹100, whichever is higher)
  static double getMinAdvanceAmount(double totalAmount) {
    final twentyPercent = totalAmount * 0.2;
    return twentyPercent < 100 ? 100 : twentyPercent;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'tableName': tableName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'persons': persons,
      'fromTime': fromTime.toIso8601String(),
      'toTime': toTime.toIso8601String(),
      'occasion': occasion,
      'specialNotes': specialNotes,
      'basePrice': basePrice,
      'finalPrice': finalPrice,
      'advanceAmount': advanceAmount,
      'remainingAmount': remainingAmount,
      'decoration': decoration,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'billNumber': billNumber,
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      tableId: json['tableId'],
      tableName: json['tableName'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      persons: json['persons'],
      fromTime: DateTime.parse(json['fromTime']),
      toTime: DateTime.parse(json['toTime']),
      occasion: json['occasion'],
      specialNotes: json['specialNotes'],
      basePrice: json['basePrice'].toDouble(),
      finalPrice: json['finalPrice'].toDouble(),
      advanceAmount: json['advanceAmount'].toDouble(),
      remainingAmount: json['remainingAmount'].toDouble(),
      decoration: json['decoration'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'confirmed',
      billNumber: json['billNumber'],
    );
  }
}
