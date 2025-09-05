class OrderDetailApiResponseModel {
  List<OrderDetailData>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  OrderDetailApiResponseModel({this.data, this.message, this.isSuccess, this.statusCode});

  OrderDetailApiResponseModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <OrderDetailData>[];
      json['data'].forEach((v) {
        data!.add(OrderDetailData.fromJson(v));
      });
    }
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }
}

class OrderDetailData {
  String? orderId;
  String? orderNo;
  String? orderChannelId;
  String? fullOrderStatus;
  String? channelType;
  String? channelName;
  String? waiterId;
  String? waiterName;
  int? outletId;
  int? billNo;
  bool? isBilled;
  bool? isPaid;
  List<OrderDetailList>? orderDetailList;
  String? billId;

  OrderDetailData({
    this.orderId,
    this.orderNo,
    this.orderChannelId,
    this.fullOrderStatus,
    this.channelType,
    this.channelName,
    this.waiterId,
    this.waiterName,
    this.outletId,
    this.billNo,
    this.isBilled,
    this.isPaid,
    this.orderDetailList,
    this.billId
  });

  OrderDetailData.fromJson(Map<String, dynamic> json) {
    orderId = json['orderId'];
    orderNo = json['orderNo'];
    orderChannelId = json['orderChannelId'];
    fullOrderStatus = json['fullOrderStatus'];
    channelType = json['channelType'];
    channelName = json['channelName'];
    waiterId = json['waiterId'];
    waiterName = json['waiterName'];
    outletId = json['outletId'];
    billNo = json['billNo'];
    isBilled = json['isBilled'];
    isPaid = json['isPaid'];
    if (json['orderDetailList'] != null) {
      orderDetailList = <OrderDetailList>[];
      json['orderDetailList'].forEach((v) {
        orderDetailList!.add(OrderDetailList.fromJson(v));
      });
    }
    billId = json['billId'];
  }
}

class OrderDetailList {
  String? orderDetailId;
  String? createdOn;
  String? productName;
  int? productQty;
  String? uom;
  int? orderStatusId;
  String? statusSystemName;
  String? status;
  String? instruction;
  String? kotNo;
  String? kotSystemName;
  String? kotStatusName;
  int? itemPrice;
  int? totPrice;
  int? discountPerc;
  int? discountAmount;
  String? customerPhNumber;
  String? orderTokenNo;
  String? kotId;
  String? generatedBillNo;
  String? productId;

  OrderDetailList({
    this.orderDetailId,
    this.createdOn,
    this.productName,
    this.productQty,
    this.uom,
    this.orderStatusId,
    this.statusSystemName,
    this.status,
    this.instruction,
    this.kotNo,
    this.kotSystemName,
    this.kotStatusName,
    this.itemPrice,
    this.totPrice,
    this.discountPerc,
    this.discountAmount,
    this.customerPhNumber,
    this.orderTokenNo,
    this.kotId,
    this.generatedBillNo,
    this.productId
  });

  OrderDetailList.fromJson(Map<String, dynamic> json) {
    orderDetailId = json['orderDetailId'];
    createdOn = json['createdOn'];
    productName = json['productName'];
    productQty = json['productQty'];
    uom = json['uom'];
    orderStatusId = json['orderStatusId'];
    statusSystemName = json['statusSystemName'];
    status = json['status'];
    instruction = json['instruction'];
    kotNo = json['kotNo'];
    kotSystemName = json['kotSystemName'];
    kotStatusName = json['kotStatusName'];
    itemPrice = json['itemPrice'];
    totPrice = json['totPrice'];
    discountPerc = json['discountPerc'];
    discountAmount = json['discountAmount'];
    customerPhNumber = json['customerPhNumber'];
    orderTokenNo = json['orderTokenNo'];
    kotId = json['kotId'];
    generatedBillNo = json['generatedBillNo'];
    productId = json['productId'];
  }
}
