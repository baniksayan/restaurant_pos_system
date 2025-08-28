class CreateKotWithOrderDetailsApiResModel {
  Data? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  CreateKotWithOrderDetailsApiResModel({
    this.data,
    this.message,
    this.isSuccess,
    this.statusCode,
  });

  CreateKotWithOrderDetailsApiResModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = this.message;
    data['isSuccess'] = this.isSuccess;
    data['statusCode'] = this.statusCode;
    return data;
  }
}

class Data {
  String? response;
  int? kotStatus;
  String? kotHeadId;
  KotDetail? kotDetail;

  Data({this.response, this.kotStatus, this.kotHeadId, this.kotDetail});

  Data.fromJson(Map<String, dynamic> json) {
    response = json['response'];
    kotStatus = json['kotStatus'];
    kotHeadId = json['kotHeadId'];
    kotDetail =
        json['kotDetail'] != null
            ? new KotDetail.fromJson(json['kotDetail'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['response'] = this.response;
    data['kotStatus'] = this.kotStatus;
    data['kotHeadId'] = this.kotHeadId;
    if (this.kotDetail != null) {
      data['kotDetail'] = this.kotDetail!.toJson();
    }
    return data;
  }
}

class KotDetail {
  String? kotNo;
  String? kotDateTime;
  Null? customerName;
  Null? customerPhoneNo;
  String? waiterName;
  String? channelName;
  String? orderId;
  String? orderNo;
  String? kotDateTimeLocal;
  String? kotNote;
  Null? orderIdentifier;
  List<ItemList>? itemList;

  KotDetail({
    this.kotNo,
    this.kotDateTime,
    this.customerName,
    this.customerPhoneNo,
    this.waiterName,
    this.channelName,
    this.orderId,
    this.orderNo,
    this.kotDateTimeLocal,
    this.kotNote,
    this.orderIdentifier,
    this.itemList,
  });

  KotDetail.fromJson(Map<String, dynamic> json) {
    kotNo = json['kotNo'];
    kotDateTime = json['kotDateTime'];
    customerName = json['customerName'];
    customerPhoneNo = json['customerPhoneNo'];
    waiterName = json['waiterName'];
    channelName = json['channelName'];
    orderId = json['orderId'];
    orderNo = json['orderNo'];
    kotDateTimeLocal = json['kotDateTimeLocal'];
    kotNote = json['kotNote'];
    orderIdentifier = json['orderIdentifier'];
    if (json['itemList'] != null) {
      itemList = <ItemList>[];
      json['itemList'].forEach((v) {
        itemList!.add(new ItemList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['kotNo'] = this.kotNo;
    data['kotDateTime'] = this.kotDateTime;
    data['customerName'] = this.customerName;
    data['customerPhoneNo'] = this.customerPhoneNo;
    data['waiterName'] = this.waiterName;
    data['channelName'] = this.channelName;
    data['orderId'] = this.orderId;
    data['orderNo'] = this.orderNo;
    data['kotDateTimeLocal'] = this.kotDateTimeLocal;
    data['kotNote'] = this.kotNote;
    data['orderIdentifier'] = this.orderIdentifier;
    if (this.itemList != null) {
      data['itemList'] = this.itemList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ItemList {
  String? itemName;
  num? itemQty;
  String? uom;
  String? itemNote;

  ItemList({this.itemName, this.itemQty, this.uom, this.itemNote});

  ItemList.fromJson(Map<String, dynamic> json) {
    itemName = json['itemName'];
    itemQty = json['itemQty'];
    uom = json['uom'];
    itemNote = json['itemNote'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['itemName'] = this.itemName;
    data['itemQty'] = this.itemQty;
    data['uom'] = this.uom;
    data['itemNote'] = this.itemNote;
    return data;
  }
}
