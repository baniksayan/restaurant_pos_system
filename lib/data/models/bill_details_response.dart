class BillDetailsResponse {
  final BillDetailsData? data;
  final String message;
  final bool isSuccess;
  final int statusCode;

  BillDetailsResponse({
    this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
  });

  factory BillDetailsResponse.fromJson(Map<String, dynamic> json) {
    return BillDetailsResponse(
      data:
          json['data'] != null ? BillDetailsData.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
      statusCode: json['statusCode'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data?.toJson(),
      'message': message,
      'isSuccess': isSuccess,
      'statusCode': statusCode,
    };
  }
}

class BillDetailsData {
  final CompanyDetails companyDt;
  final BillHeadDetails billHeadDt;
  final List<OrderChannelDetails> orderChanelDt;
  final List<TaxInfo> taxInf;
  final List<BillOrderDetails> billOrderDt;
  final List<PaymentDetail> paymentDetail;

  BillDetailsData({
    required this.companyDt,
    required this.billHeadDt,
    required this.orderChanelDt,
    required this.taxInf,
    required this.billOrderDt,
    required this.paymentDetail,
  });

  factory BillDetailsData.fromJson(Map<String, dynamic> json) {
    return BillDetailsData(
      companyDt: CompanyDetails.fromJson(json['companyDt'] ?? {}),
      billHeadDt: BillHeadDetails.fromJson(json['billHeadDt'] ?? {}),
      orderChanelDt:
          (json['orderChanelDt'] as List<dynamic>?)
              ?.map((item) => OrderChannelDetails.fromJson(item))
              .toList() ??
          [],
      taxInf:
          (json['taxInf'] as List<dynamic>?)
              ?.map((item) => TaxInfo.fromJson(item))
              .toList() ??
          [],
      billOrderDt:
          (json['billOrderDt'] as List<dynamic>?)
              ?.map((item) => BillOrderDetails.fromJson(item))
              .toList() ??
          [],
      paymentDetail:
          (json['paymentDetail'] as List<dynamic>?)
              ?.map((item) => PaymentDetail.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyDt': companyDt.toJson(),
      'billHeadDt': billHeadDt.toJson(),
      'orderChanelDt': orderChanelDt.map((item) => item.toJson()).toList(),
      'taxInf': taxInf.map((item) => item.toJson()).toList(),
      'billOrderDt': billOrderDt.map((item) => item.toJson()).toList(),
      'paymentDetail': paymentDetail.map((item) => item.toJson()).toList(),
    };
  }
}

class CompanyDetails {
  final String companyName;
  final String companyAddress;
  final String? companyPinNo;
  final String? gstNo;
  final String? contactNo;

  CompanyDetails({
    required this.companyName,
    required this.companyAddress,
    this.companyPinNo,
    this.gstNo,
    this.contactNo,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      companyName: json['companyName'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      companyPinNo: json['companyPinNo'],
      gstNo: json['gstNo'],
      contactNo: json['contactNo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPinNo': companyPinNo,
      'gstNo': gstNo,
      'contactNo': contactNo,
    };
  }
}

class BillHeadDetails {
  final String billNo;
  final String billDate;
  final String billCreatedBy;
  final double discountPerc;
  final double discountAmnt;
  final double specDisPer;
  final double specDisAmt;
  final double amountAfterDisc;
  final double billAmountExclTax;
  final double billAmountInclTax; // This is the main amount we'll use
  final String customerName;
  final String custMobNo;
  final double returnToCustomer;
  final String outletAddress;

  BillHeadDetails({
    required this.billNo,
    required this.billDate,
    required this.billCreatedBy,
    required this.discountPerc,
    required this.discountAmnt,
    required this.specDisPer,
    required this.specDisAmt,
    required this.amountAfterDisc,
    required this.billAmountExclTax,
    required this.billAmountInclTax,
    required this.customerName,
    required this.custMobNo,
    required this.returnToCustomer,
    required this.outletAddress,
  });

  factory BillHeadDetails.fromJson(Map<String, dynamic> json) {
    return BillHeadDetails(
      billNo: json['billNo'] ?? '',
      billDate: json['billDate'] ?? '',
      billCreatedBy: json['billCreatedBy'] ?? '',
      discountPerc: (json['discountPerc'] ?? 0).toDouble(),
      discountAmnt: (json['discountAmnt'] ?? 0).toDouble(),
      specDisPer: (json['specDisPer'] ?? 0).toDouble(),
      specDisAmt: (json['specDisAmt'] ?? 0).toDouble(),
      amountAfterDisc: (json['amountAfterDisc'] ?? 0).toDouble(),
      billAmountExclTax: (json['billAmountExclTax'] ?? 0).toDouble(),
      billAmountInclTax: (json['billAmountInclTax'] ?? 0).toDouble(),
      customerName: json['customerName'] ?? '',
      custMobNo: json['custMobNo'] ?? '',
      returnToCustomer: (json['returnToCustomer'] ?? 0).toDouble(),
      outletAddress: json['outletAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billNo': billNo,
      'billDate': billDate,
      'billCreatedBy': billCreatedBy,
      'discountPerc': discountPerc,
      'discountAmnt': discountAmnt,
      'specDisPer': specDisPer,
      'specDisAmt': specDisAmt,
      'amountAfterDisc': amountAfterDisc,
      'billAmountExclTax': billAmountExclTax,
      'billAmountInclTax': billAmountInclTax,
      'customerName': customerName,
      'custMobNo': custMobNo,
      'returnToCustomer': returnToCustomer,
      'outletAddress': outletAddress,
    };
  }
}

class OrderChannelDetails {
  final String channelType;
  final String channelName;

  OrderChannelDetails({required this.channelType, required this.channelName});

  factory OrderChannelDetails.fromJson(Map<String, dynamic> json) {
    return OrderChannelDetails(
      channelType: json['channelType'] ?? '',
      channelName: json['channelName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'channelType': channelType, 'channelName': channelName};
  }
}

class TaxInfo {
  final String componentName;
  final double taxPercentage;

  TaxInfo({required this.componentName, required this.taxPercentage});

  factory TaxInfo.fromJson(Map<String, dynamic> json) {
    return TaxInfo(
      componentName: json['componentName'] ?? '',
      taxPercentage: (json['taxPercentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'componentName': componentName, 'taxPercentage': taxPercentage};
  }
}

class BillOrderDetails {
  final String orderId;
  final String orderNo;
  final String orderDate;
  final String waiterName;
  final String itemName;
  final double orderQty;
  final String uom;
  final double itemPrice;
  final double totalItemPrice;

  BillOrderDetails({
    required this.orderId,
    required this.orderNo,
    required this.orderDate,
    required this.waiterName,
    required this.itemName,
    required this.orderQty,
    required this.uom,
    required this.itemPrice,
    required this.totalItemPrice,
  });

  factory BillOrderDetails.fromJson(Map<String, dynamic> json) {
    return BillOrderDetails(
      orderId: json['orderId'] ?? '',
      orderNo: json['orderNo'] ?? '',
      orderDate: json['orderDate'] ?? '',
      waiterName: json['waiterName'] ?? '',
      itemName: json['itemName'] ?? '',
      orderQty: (json['orderQty'] ?? 0).toDouble(),
      uom: json['uom'] ?? '',
      itemPrice: (json['itemPrice'] ?? 0).toDouble(),
      totalItemPrice: (json['totalItemPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderNo': orderNo,
      'orderDate': orderDate,
      'waiterName': waiterName,
      'itemName': itemName,
      'orderQty': orderQty,
      'uom': uom,
      'itemPrice': itemPrice,
      'totalItemPrice': totalItemPrice,
    };
  }
}

class PaymentDetail {
  // Add properties as needed based on future requirements
  // Currently empty as per the API response

  PaymentDetail();

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}
