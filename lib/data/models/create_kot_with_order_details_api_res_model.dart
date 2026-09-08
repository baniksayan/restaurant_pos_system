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
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = message;
    data['isSuccess'] = isSuccess;
    data['statusCode'] = statusCode;
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
            ? KotDetail.fromJson(json['kotDetail'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['response'] = response;
    data['kotStatus'] = kotStatus;
    data['kotHeadId'] = kotHeadId;
    if (kotDetail != null) {
      data['kotDetail'] = kotDetail!.toJson();
    }
    return data;
  }
}

class KotDetail {
  String? kotNo;
  String? kotDateTime;
  String? customerName;
  String? customerPhoneNo;
  String? waiterName;
  String? channelName;
  String? orderId;
  String? orderNo;
  String? kotDateTimeLocal;
  String? kotNote;
  String? orderIdentifier;
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
        itemList!.add(ItemList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['kotNo'] = kotNo;
    data['kotDateTime'] = kotDateTime;
    data['customerName'] = customerName;
    data['customerPhoneNo'] = customerPhoneNo;
    data['waiterName'] = waiterName;
    data['channelName'] = channelName;
    data['orderId'] = orderId;
    data['orderNo'] = orderNo;
    data['kotDateTimeLocal'] = kotDateTimeLocal;
    data['kotNote'] = kotNote;
    data['orderIdentifier'] = orderIdentifier;
    if (itemList != null) {
      data['itemList'] = itemList!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['itemName'] = itemName;
    data['itemQty'] = itemQty;
    data['uom'] = uom;
    data['itemNote'] = itemNote;
    return data;
  }
}
