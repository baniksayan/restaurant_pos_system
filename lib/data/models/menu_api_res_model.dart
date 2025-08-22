class MenuApiResModel {
  List<Data>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  MenuApiResModel({this.data, this.message, this.isSuccess, this.statusCode});

  MenuApiResModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    data['isSuccess'] = this.isSuccess;
    data['statusCode'] = this.statusCode;
    return data;
  }
}

class Data {
  String? productId;
  String? categoryId;
  String? categoryName;
  String? productName;
  String? productAlias;
  String? productNumber;
  String? productSKU;
  String? description;
  String? productRemarks;
  String? uom;
  num? productPrice;
  int? imageId;
  String? imageUrl;
  String? imageThumbUrl;
  int? offerID;
  num? discountPercentage;
  int? effectivePrice;
  bool? pureVeg;
  int? meuSectionId;

  Data({
    this.productId,
    this.categoryId,
    this.categoryName,
    this.productName,
    this.productAlias,
    this.productNumber,
    this.productSKU,
    this.description,
    this.productRemarks,
    this.uom,
    this.productPrice,
    this.imageId,
    this.imageUrl,
    this.imageThumbUrl,
    this.offerID,
    this.discountPercentage,
    this.effectivePrice,
    this.pureVeg,
    this.meuSectionId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    productId = json['productId'];
    categoryId = json['categoryId'];
    categoryName = json['categoryName'];
    productName = json['productName'];
    productAlias = json['productAlias'];
    productNumber = json['productNumber'];
    productSKU = json['productSKU'];
    description = json['description'];
    productRemarks = json['productRemarks'];
    uom = json['uom'];
    productPrice = json['productPrice'];
    imageId = json['imageId'];
    imageUrl = json['imageUrl'];
    imageThumbUrl = json['imageThumbUrl'];
    offerID = json['offerID'];
    discountPercentage = json['discountPercentage'];
    effectivePrice = json['effectivePrice'];
    pureVeg = json['pureVeg'];
    meuSectionId = json['meuSectionId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['productId'] = this.productId;
    data['categoryId'] = this.categoryId;
    data['categoryName'] = this.categoryName;
    data['productName'] = this.productName;
    data['productAlias'] = this.productAlias;
    data['productNumber'] = this.productNumber;
    data['productSKU'] = this.productSKU;
    data['description'] = this.description;
    data['productRemarks'] = this.productRemarks;
    data['uom'] = this.uom;
    data['productPrice'] = this.productPrice;
    data['imageId'] = this.imageId;
    data['imageUrl'] = this.imageUrl;
    data['imageThumbUrl'] = this.imageThumbUrl;
    data['offerID'] = this.offerID;
    data['discountPercentage'] = this.discountPercentage;
    data['effectivePrice'] = this.effectivePrice;
    data['pureVeg'] = this.pureVeg;
    data['meuSectionId'] = this.meuSectionId;
    return data;
  }
}
