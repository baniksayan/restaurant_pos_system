// lib/data/models/table.dart
enum TableStatus { 
  available, 
  occupied, 
  reserved,
}

class TableModel {
  final String id;
  final String name;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;
  final bool kotGenerated;
  final bool billGenerated;
  final DateTime? lastUpdated;

  // 👈 FIX: Use TableModel constructor, not RestaurantTable
  const TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    this.kotGenerated = false,
    this.billGenerated = false,
    this.lastUpdated,
  });

  // 👈 FIX: Return TableModel, not RestaurantTable
  TableModel copyWith({
    String? id,
    String? name,
    int? capacity,
    TableStatus? status,
    String? currentOrderId,
    bool? kotGenerated,
    bool? billGenerated,
    DateTime? lastUpdated,
  }) {
    return TableModel( // 👈 FIX: Use TableModel constructor
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      kotGenerated: kotGenerated ?? this.kotGenerated,
      billGenerated: billGenerated ?? this.billGenerated,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
