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

class OrderChannelResponse {
  final List<OrderChannel> data;
  final String message;
  final bool isSuccess;
  final int statusCode;

  OrderChannelResponse({
    required this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
  });

  factory OrderChannelResponse.fromJson(Map<String, dynamic> json) {
    return OrderChannelResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => OrderChannel.fromJson(item))
              .toList() ??
          [],
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
      statusCode: json['statusCode'] ?? 0,
    );
  }
}

class OrderHeadRequest {
  final String orderChannelId;
  final String waiterId;
  final String custPhoneNo;
  final String ordPrefix;
  final String tokenNo;
  final String orderIdentifier;
  final int totalAdult;
  final int totalChild;
  final String customerName;
  final String orderIdUI;
  final int outletId;
  final String custEmailId;
  final String custDob;
  final String customerIdUI;
  final String userId;

  OrderHeadRequest({
    required this.orderChannelId,
    required this.waiterId,
    required this.custPhoneNo,
    required this.ordPrefix,
    required this.tokenNo,
    required this.orderIdentifier,
    required this.totalAdult,
    required this.totalChild,
    required this.customerName,
    required this.orderIdUI,
    required this.outletId,
    required this.custEmailId,
    required this.custDob,
    required this.customerIdUI,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderChannelId': orderChannelId,
      'waiterId': waiterId,
      'custPhoneNo': custPhoneNo,
      'ordPrefix': ordPrefix,
      'tokenNo': tokenNo,
      'orderIdentifier': orderIdentifier,
      'totalAdult': totalAdult,
      'totalChild': totalChild,
      'customerName': customerName,
      'orderIdUI': orderIdUI,
      'outletId': outletId,
      'custEmailId': custEmailId,
      'custDob': custDob,
      'customerIdUI': customerIdUI,
      'userId': userId,
    };
  }
}
