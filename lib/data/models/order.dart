import 'menu_item.dart';

enum OrderStatus { pending, preparing, ready, completed, cancelled }

class Order {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final DateTime createdAt;
  final OrderStatus status;
  final double totalAmount;

  Order({
    required this.id,
    required this.tableId,
    required this.items,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
  });

  Order copyWith({
    String? id,
    String? tableId,
    List<OrderItem>? items,
    DateTime? createdAt,
    OrderStatus? status,
    double? totalAmount,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}

class OrderItem {
  final MenuItem menuItem;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.menuItem,
    required this.quantity,
    this.notes,
  });
}
