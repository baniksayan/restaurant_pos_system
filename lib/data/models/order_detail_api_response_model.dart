class OrderDetailApiResponseModel {
  List<OrderDetailData>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  OrderDetailApiResponseModel({
    this.data,
    this.message,
    this.isSuccess,
    this.statusCode,
  });

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
  String? generatedBillNo;
  List<String>? paymentModes;

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
    this.billId,
    this.generatedBillNo,
    this.paymentModes,
  });

  OrderDetailData.fromJson(Map<String, dynamic> json) {
    orderId = json['orderId'];
    orderNo = json['orderNo'];
    orderChannelId = json['orderChannelId'];
    fullOrderStatus = json['fullOrderStatus'];
    channelType = json['channelType'];
    channelName = json['channelName'];
    waiterId = json['waiterId'];
    waiterName = (json['waiterName'] ??
            json['waiter_name'] ??
            json['staffName'] ??
            json['waiter'] ??
            json['serverName'] ??
            json['createdBy'] ??
            json['userName'])
        ?.toString();
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
    generatedBillNo = (json['generatedBillNo'] ??
            json['generatedBillNumber'] ??
            json['billNumber'] ??
            json['bill_no'] ??
            json['formattedBillNo'])
        ?.toString();

    final rawModes = json['paymentModes'] ??
        json['paymentMode'] ??
        json['paymentMethod'] ??
        json['paymentMethods'];
    if (rawModes is List) {
      paymentModes = rawModes
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawModes is String && rawModes.trim().isNotEmpty) {
      paymentModes = rawModes
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
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
  num? itemPrice;
  num? totPrice;
  num? discountPerc;
  num? discountAmount;

  String? customerPhNumber;
  String? orderTokenNo;
  String? kotId;
  String? generatedBillNo;
  String? productId;
  String? imageThumbUrl;
  String? imageUrl;

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
    this.productId,
    this.imageThumbUrl,
    this.imageUrl,
  });

  OrderDetailList.fromJson(Map<String, dynamic> json) {
    orderDetailId = json['orderDetailId'];
    createdOn = json['createdOn'];
    productName = json['productName'];
    var pq = json['productQty'];
    if (pq == null) {
      productQty = null;
    } else if (pq is int) {
      productQty = pq;
    } else if (pq is String) {
      productQty = int.tryParse(pq) ?? double.tryParse(pq)?.toInt();
    } else if (pq is num) {
      productQty = pq.toInt();
    } else {
      productQty = null;
    }
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
    imageThumbUrl = json['imageThumbUrl'];
    imageUrl = json['imageUrl'];
  }
}
