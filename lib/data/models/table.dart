enum TableStatus { available, occupied, reserved, cleaning }

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;
  final bool kotGenerated;          // ADD THIS PROPERTY
  final bool billGenerated;         // ADD THIS PROPERTY
  final DateTime? lastUpdated;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    this.kotGenerated = false,       // ADD THIS WITH DEFAULT VALUE
    this.billGenerated = false,      // ADD THIS WITH DEFAULT VALUE
    this.lastUpdated,
  });

  RestaurantTable copyWith({
    String? id,
    String? name,
    int? capacity,
    TableStatus? status,
    String? currentOrderId,
    bool? kotGenerated,              // ADD THIS TO COPYWITH
    bool? billGenerated,             // ADD THIS TO COPYWITH
    DateTime? lastUpdated,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      kotGenerated: kotGenerated ?? this.kotGenerated,        // ADD THIS
      billGenerated: billGenerated ?? this.billGenerated,     // ADD THIS
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
