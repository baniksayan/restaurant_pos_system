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
    final Map<String, dynamic> data = Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    data['isSuccess'] = this.isSuccess;
    data['statusCode'] = this.statusCode;
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
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['orderChannelId'] = this.orderChannelId;
    data['channelType'] = this.channelType;
    data['name'] = this.name;
    data['capacity'] = this.capacity;
    if (this.orderList != null) {
      data['orderList'] = this.orderList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class OrderList {
  String? orderId;
  bool? isBilled;
  String? orderStatus;
  String? generatedOrderNo;

  OrderList({
    this.orderId,
    this.isBilled,
    this.orderStatus,
    this.generatedOrderNo,
  });

  OrderList.fromJson(Map<String, dynamic> json) {
    orderId = json['orderId'];
    isBilled = json['isBilled'];
    orderStatus = json['orderStatus'];
    generatedOrderNo = json['generatedOrderNo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['orderId'] = this.orderId;
    data['isBilled'] = this.isBilled;
    data['orderStatus'] = this.orderStatus;
    data['generatedOrderNo'] = this.generatedOrderNo;
    return data;
  }
}
