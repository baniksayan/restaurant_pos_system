class CreateOrderHeadApiResModel {
  OrderHeadResponseData? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  CreateOrderHeadApiResModel({
    this.data,
    this.message,
    this.isSuccess,
    this.statusCode,
  });

  CreateOrderHeadApiResModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null 
        ? OrderHeadResponseData.fromJson(json['data']) 
        : null;
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = this.message;
    data['isSuccess'] = this.isSuccess;
    data['statusCode'] = this.statusCode;
    return data;
  }
}

class OrderHeadResponseData {
  String? orderId;
  String? generatedOrderNo;
  int? orderNo;
  String? response;

  OrderHeadResponseData({
    this.orderId,
    this.generatedOrderNo,
    this.orderNo,
    this.response,
  });

  OrderHeadResponseData.fromJson(Map<String, dynamic> json) {
    orderId = json['orderId'];
    generatedOrderNo = json['generatedOrderNo'];
    orderNo = json['orderNo'];
    response = json['response'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orderId'] = this.orderId;
    data['generatedOrderNo'] = this.generatedOrderNo;
    data['orderNo'] = this.orderNo;
    data['response'] = this.response;
    return data;
  }
}
