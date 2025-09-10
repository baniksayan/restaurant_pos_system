enum OrderStatusType {
  pending,
  accepted,
  preparing,
  ready,
  delivered,
  cancelled,
  completed,
}

class OrderItem {
  final String orderId;
  final String customerName;
  final String? phoneNumber;
  final String orderType;
  final OrderStatusType status;
  final double totalAmount;
  final DateTime orderTime;
  final DateTime? acceptedTime;
  final DateTime? expectedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? tableNumber;
  final String? waiterId;
  final String? waiterName;
  final List<OrderItemDetail> items; // Fixed reference
  final String? platformName;

  const OrderItem({
    required this.orderId,
    required this.customerName,
    this.phoneNumber,
    required this.orderType,
    required this.status,
    required this.totalAmount,
    required this.orderTime,
    this.acceptedTime,
    this.expectedDeliveryTime,
    this.actualDeliveryTime,
    this.tableNumber,
    this.waiterId,
    this.waiterName,
    required this.items,
    this.platformName,
  });

  // Copy with method for state updates
  OrderItem copyWith({
    OrderStatusType? status,
    DateTime? acceptedTime,
    DateTime? expectedDeliveryTime,
    DateTime? actualDeliveryTime,
  }) {
    return OrderItem(
      orderId: orderId,
      customerName: customerName,
      phoneNumber: phoneNumber,
      orderType: orderType,
      status: status ?? this.status,
      totalAmount: totalAmount,
      orderTime: orderTime,
      acceptedTime: acceptedTime ?? this.acceptedTime,
      expectedDeliveryTime: expectedDeliveryTime ?? this.expectedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      tableNumber: tableNumber,
      waiterId: waiterId,
      waiterName: waiterName,
      items: items,
      platformName: platformName,
    );
  }

  // Helper methods
  String get statusDisplayText {
    switch (status) {
      case OrderStatusType.pending:
        return 'Awaiting Response';
      case OrderStatusType.accepted:
        return 'Processing Order';
      case OrderStatusType.preparing:
        return 'Preparing Food';
      case OrderStatusType.ready:
        return 'Ready for Pickup';
      case OrderStatusType.delivered:
        return 'Delivered';
      case OrderStatusType.cancelled:
        return 'Cancelled';
      case OrderStatusType.completed:
        return 'Completed';
    }
  }
}

// Fixed OrderItemDetail class
class OrderItemDetail {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;

  const OrderItemDetail({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });
}
