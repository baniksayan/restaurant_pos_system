class CreateKotWithOrderDetailsApiResModel {
  Data? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  CreateKotWithOrderDetailsApiResModel({this.data, this.message, this.isSuccess, this.statusCode});

  CreateKotWithOrderDetailsApiResModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
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
    kotDetail = json['kotDetail'] != null ? KotDetail.fromJson(json['kotDetail']) : null;
  }
}

class KotDetail {
  String? kotNo;
  String? kotDateTime;
  String? waiterName;
  String? channelName;
  String? orderId;
  String? orderNo;
  String? kotDateTimeLocal;
  String? kotNote;
  List<ItemList>? itemList;

  KotDetail(
      {this.kotNo,
      this.kotDateTime,
      this.waiterName,
      this.channelName,
      this.orderId,
      this.orderNo,
      this.kotDateTimeLocal,
      this.kotNote,
      this.itemList});

  KotDetail.fromJson(Map<String, dynamic> json) {
    kotNo = json['kotNo'];
    kotDateTime = json['kotDateTime'];
    waiterName = json['waiterName'];
    channelName = json['channelName'];
    orderId = json['orderId'];
    orderNo = json['orderNo'];
    kotDateTimeLocal = json['kotDateTimeLocal'];
    kotNote = json['kotNote'];
    if (json['itemList'] != null) {
      itemList = <ItemList>[];
      json['itemList'].forEach((v) {
        itemList!.add(ItemList.fromJson(v));
      });
    }
  }
}

class ItemList {
  String? itemName;
  int? itemQty;
  String? uom;
  String? itemNote;

  ItemList({this.itemName, this.itemQty, this.uom, this.itemNote});

  ItemList.fromJson(Map<String, dynamic> json) {
    itemName = json['itemName'];
    itemQty = json['itemQty'];
    uom = json['uom'];
    itemNote = json['itemNote'];
  }
}
