import 'package:flutter/material.dart';

class OrderChannelTypesModel {
  List<OrderChannelTypeData>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  OrderChannelTypesModel({this.data, this.message, this.isSuccess, this.statusCode});

  OrderChannelTypesModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <OrderChannelTypeData>[];
      json['data'].forEach((v) {
        data!.add(OrderChannelTypeData.fromJson(v));
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

class OrderChannelTypeData {
  String? orderChannelType;
  String? typeName;

  OrderChannelTypeData({this.orderChannelType, this.typeName});

  OrderChannelTypeData.fromJson(Map<String, dynamic> json) {
    orderChannelType = json['orderChannelType'];
    typeName = json['typeName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orderChannelType'] = orderChannelType;
    data['typeName'] = typeName;
    return data;
  }
}

enum OrderType {
  dineIn,
  phoneOrder,
  takeaway
}

extension OrderTypeExtension on OrderType {
  String get displayName {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-in';
      case OrderType.phoneOrder:
        return 'Phone Order';
      case OrderType.takeaway:
        return 'Takeaway';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.dineIn:
        return Icons.restaurant;
      case OrderType.phoneOrder:
        return Icons.phone;
      case OrderType.takeaway:
        return Icons.shopping_bag;
    }
  }

  String get channelType {
    switch (this) {
      case OrderType.dineIn:
        return 'Table';
      case OrderType.phoneOrder:
        return 'PhoneOrder';
      case OrderType.takeaway:
        return 'Takeaway';
    }
  }
}
