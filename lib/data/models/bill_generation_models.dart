// Model for GetOrderDetalForBill API Response
class GetOrderDetailForBillResponse {
  final OrderDetailForBill? data;
  final String message;
  final bool isSuccess;
  final int statusCode;

  GetOrderDetailForBillResponse({
    required this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
  });

  factory GetOrderDetailForBillResponse.fromJson(Map<String, dynamic> json) {
    return GetOrderDetailForBillResponse(
      data:
          json['data'] != null
              ? OrderDetailForBill.fromJson(json['data'])
              : null,
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
      statusCode: json['statusCode'] ?? 0,
    );
  }
}

class OrderDetailForBill {
  final String orderId;
  final String generatedOrderNo;
  final String customerName;
  final String customerPhoneNo;
  final double totalPrice;
  final String orderDetailId;

  OrderDetailForBill({
    required this.orderId,
    required this.generatedOrderNo,
    required this.customerName,
    required this.customerPhoneNo,
    required this.totalPrice,
    required this.orderDetailId,
  });

  factory OrderDetailForBill.fromJson(Map<String, dynamic> json) {
    return OrderDetailForBill(
      orderId: json['orderId'] ?? '',
      generatedOrderNo: json['generatedOrderNo'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhoneNo: json['customerPhoneNo'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      orderDetailId: json['orderDetailId'] ?? '',
    );
  }
}

// Model for getCustomerByMobileNo API Response
class CustomerByMobileResponse {
  final CustomerData? data;
  final String message;
  final bool isSuccess;
  final int statusCode;

  CustomerByMobileResponse({
    required this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
  });

  factory CustomerByMobileResponse.fromJson(Map<String, dynamic> json) {
    return CustomerByMobileResponse(
      data: json['data'] != null ? CustomerData.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
      statusCode: json['statusCode'] ?? 0,
    );
  }
}

class CustomerData {
  final String customerId;
  final String customerName;
  final String customerFirstName;
  final String customerLastName;
  final String dob;
  final String? emailId;

  CustomerData({
    required this.customerId,
    required this.customerName,
    required this.customerFirstName,
    required this.customerLastName,
    required this.dob,
    this.emailId,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerFirstName: json['customerFirstName'] ?? '',
      customerLastName: json['customerLastName'] ?? '',
      dob: json['dob'] ?? '',
      emailId: json['emailId'],
    );
  }
}

// Model for CreateBill API Response
class CreateBillResponse {
  final BillData? data;
  final String message;
  final bool isSuccess;
  final int statusCode;

  CreateBillResponse({
    required this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
  });

  factory CreateBillResponse.fromJson(Map<String, dynamic> json) {
    return CreateBillResponse(
      data: json['data'] != null ? BillData.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
      statusCode: json['statusCode'] ?? 0,
    );
  }
}

class BillData {
  final String billId;
  final double returnToCustomer;
  final String response;
  final int billNo;
  final String generatedBillNo;

  BillData({
    required this.billId,
    required this.returnToCustomer,
    required this.response,
    required this.billNo,
    required this.generatedBillNo,
  });

  factory BillData.fromJson(Map<String, dynamic> json) {
    return BillData(
      billId: json['billId'] ?? '',
      returnToCustomer: (json['returnToCustomer'] ?? 0.0).toDouble(),
      response: json['response'] ?? '',
      billNo: json['billNo'] ?? 0,
      generatedBillNo: json['generatedBillNo'] ?? '',
    );
  }
}

// Model for CreateBill API Request
class CreateBillRequest {
  final String customerFirstName;
  final String customerLastName;
  final String contactNo;
  final String paidAmount;
  final int paymentModeId;
  final int discountPercBillHd;
  final String customerIdUI;
  final String itemList;
  final int splDisPer;
  final String splDisReason;
  final int outletId;
  final String billPrefix;
  final List<dynamic> paymentDetails;

  CreateBillRequest({
    required this.customerFirstName,
    required this.customerLastName,
    required this.contactNo,
    required this.paidAmount,
    required this.paymentModeId,
    required this.discountPercBillHd,
    required this.customerIdUI,
    required this.itemList,
    required this.splDisPer,
    required this.splDisReason,
    required this.outletId,
    required this.billPrefix,
    required this.paymentDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerFirstName': customerFirstName,
      'customerLastName': customerLastName,
      'contactNo': contactNo,
      'paidAmount': paidAmount,
      'paymentModeId': paymentModeId,
      'discountPercBillHd': discountPercBillHd,
      'customerIdUI': customerIdUI,
      'itemList': itemList,
      'splDisPer': splDisPer,
      'splDisReason': splDisReason,
      'outletId': outletId,
      'billPrefix': billPrefix,
      'paymentDetails': paymentDetails,
    };
  }
}

// Model for SavePayment API Request
class SavePaymentRequest {
  final String billId;
  final List<PaymentDetail> paymentDetails;

  SavePaymentRequest({required this.billId, required this.paymentDetails});

  Map<String, dynamic> toJson() {
    return {
      'billId': billId,
      'paymentDetails':
          paymentDetails.map((detail) => detail.toJson()).toList(),
    };
  }
}

class PaymentDetail {
  /// Payment row status written to Payment.Status. The server flattens each
  /// entry to "amount#refId#modeId#cardNo#status#returnAmt" before calling
  /// SP_SavePayment, so omitting this left every row stored with the default
  /// 0. 2 = settled, which is what the billing counter client sends.
  static const int statusSettled = 2;

  final double paymentAmount;
  final int modeId;
  final String refId;
  final String cardNo;
  final double returnAmt;
  final int status;

  PaymentDetail({
    required this.paymentAmount,
    required this.modeId,
    required this.refId,
    required this.cardNo,
    required this.returnAmt,
    this.status = statusSettled,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentAmount': paymentAmount,
      'modeId': modeId,
      'refId': refId,
      'cardNo': cardNo,
      'status': status,
      'returnAmt': returnAmt,
    };
  }
}

// Model for SavePayment API Response
class SavePaymentResponse {
  final dynamic data;
  final String message;
  final bool isSuccess;
  final int statusCode;

  SavePaymentResponse({
    required this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
  });

  factory SavePaymentResponse.fromJson(Map<String, dynamic> json) {
    return SavePaymentResponse(
      data: json['data'],
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
      statusCode: json['statusCode'] ?? 0,
    );
  }
}
