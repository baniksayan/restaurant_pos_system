class OrderChannel {
  final String orderChannelId;
  final String channelType;
  final String name;
  final int capacity;
  final List<OrderInfo> orderList;

  OrderChannel({
    required this.orderChannelId,
    required this.channelType,
    required this.name,
    required this.capacity,
    required this.orderList,
  });

  factory OrderChannel.fromJson(Map<String, dynamic> json) {
    return OrderChannel(
      orderChannelId: json['orderChannelId'],
      channelType: json['channelType'],
      name: json['name'],
      capacity: json['capacity'],
      orderList: json['orderList'] == null
          ? []
          : List<OrderInfo>.from(
              (json['orderList'] as List).map((x) => OrderInfo.fromJson(x)),
            ),
    );
  }
}

class OrderInfo {
  final String orderId;
  final bool isBilled;
  final String? orderStatus;
  final String? generatedOrderNo;

  OrderInfo({
    required this.orderId,
    required this.isBilled,
    this.orderStatus,
    this.generatedOrderNo,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      orderId: json['orderId'],
      isBilled: json['isBilled'] ?? false,
      orderStatus: json['orderStatus'],
      generatedOrderNo: json['generatedOrderNo'],
    );
  }
}
