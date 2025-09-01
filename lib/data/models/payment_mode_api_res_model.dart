class PaymentModeApiResModel {
  List<PaymentModeData>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  PaymentModeApiResModel({
    this.data, 
    this.message, 
    this.isSuccess, 
    this.statusCode
  });

  PaymentModeApiResModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <PaymentModeData>[];
      json['data'].forEach((v) {
        data!.add(PaymentModeData.fromJson(v));
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

class PaymentModeData {
  int? paymentModeId;
  String? modeName;

  PaymentModeData({this.paymentModeId, this.modeName});

  PaymentModeData.fromJson(Map<String, dynamic> json) {
    paymentModeId = json['paymentModeId'];
    modeName = json['modeName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['paymentModeId'] = paymentModeId;
    data['modeName'] = modeName;
    return data;
  }

  // Helper method to get display icon
  String getIcon() {
    switch (modeName?.toLowerCase()) {
      case 'cash':
        return '💵';
      case 'card':
        return '💳';
      case 'upi':
        return '📱';
      default:
        return '💰';
    }
  }

  // Helper method to get payment method key for UI
  String getMethodKey() {
    switch (modeName?.toLowerCase()) {
      case 'cash':
        return 'cash';
      case 'card':
        return 'card';
      case 'upi':
        return 'upi';
      default:
        return 'other';
    }
  }
}
