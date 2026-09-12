class OrderChannelListApiResponseModel {
  List<TableData>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  OrderChannelListApiResponseModel({
    this.data,
    this.message,
    this.isSuccess,
    this.statusCode,
  });

  OrderChannelListApiResponseModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <TableData>[];
      json['data'].forEach((v) {
        data!.add(TableData.fromJson(v));
      });
    }
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = message;
    data['isSuccess'] = isSuccess;
    data['statusCode'] = statusCode;
    return data;
  }
}

class TableData {
  String? orderChannelId;
  String? channelType;
  String? name;
  int? capacity;
  List<OrderList>? orderList;

  TableData({
    this.orderChannelId,
    this.channelType,
    this.name,
    this.capacity,
    this.orderList,
  });

  TableData.fromJson(Map<String, dynamic> json) {
    orderChannelId = json['orderChannelId'];
    channelType = json['channelType'];
    name = json['name'];
    capacity = json['capacity'];
    if (json['orderList'] != null) {
      orderList = <OrderList>[];
      json['orderList'].forEach((v) {
        orderList!.add(OrderList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orderChannelId'] = orderChannelId;
    data['channelType'] = channelType;
    data['name'] = name;
    data['capacity'] = capacity;
    if (orderList != null) {
      data['orderList'] = orderList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class OrderList {
  String? orderId;
  bool? isBilled;
  String? orderStatus;
  String? generatedOrderNo;

  // Guest counts, so several groups sharing one table can be told apart and
  // the table card can show how full it is. Null until
  // Sp_GetOrderChannelListByType is updated to select them (they already exist
  // on OrderHead), so this is safe to ship ahead of the SQL change.
  int? totalAdult;
  int? totalChild;

  OrderList({
    this.orderId,
    this.isBilled,
    this.orderStatus,
    this.generatedOrderNo,
    this.totalAdult,
    this.totalChild,
  });

  OrderList.fromJson(Map<String, dynamic> json) {
    orderId = json['orderId'];
    isBilled = json['isBilled'];
    orderStatus = json['orderStatus'];
    generatedOrderNo = json['generatedOrderNo'];
    totalAdult = json['totalAdult'];
    totalChild = json['totChild'] ?? json['totalChild'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orderId'] = orderId;
    data['isBilled'] = isBilled;
    data['orderStatus'] = orderStatus;
    data['generatedOrderNo'] = generatedOrderNo;
    data['totalAdult'] = totalAdult;
    data['totChild'] = totalChild;
    return data;
  }
}
