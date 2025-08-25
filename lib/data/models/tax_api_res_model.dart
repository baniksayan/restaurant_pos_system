class TaxApiResModel {
  List<TaxData>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  TaxApiResModel({this.data, this.message, this.isSuccess, this.statusCode});

  TaxApiResModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <TaxData>[];
      json['data'].forEach((v) {
        data!.add(TaxData.fromJson(v));
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

  // Helper method to get total GST percentage
  double getTotalGstPercentage() {
    if (data == null) return 0.0;
    return data!.fold(0.0, (sum, tax) => sum + (tax.currentPercentage?.toDouble() ?? 0.0));
  }

  // Helper method to get CGST percentage
  double getCgstPercentage() {
    if (data == null) return 0.0;
    final cgst = data!.firstWhere(
      (tax) => tax.componentName?.toUpperCase() == 'CGST',
      orElse: () => TaxData(),
    );
    return cgst.currentPercentage?.toDouble() ?? 0.0;
  }

  // Helper method to get SGST percentage
  double getSgstPercentage() {
    if (data == null) return 0.0;
    final sgst = data!.firstWhere(
      (tax) => tax.componentName?.toUpperCase() == 'SGST',
      orElse: () => TaxData(),
    );
    return sgst.currentPercentage?.toDouble() ?? 0.0;
  }
}

class TaxData {
  int? taxComponentId;
  String? componentName;
  int? currentPercentage;

  TaxData({this.taxComponentId, this.componentName, this.currentPercentage});

  TaxData.fromJson(Map<String, dynamic> json) {
    taxComponentId = json['taxComponentId'];
    componentName = json['componentName'];
    currentPercentage = json['currentPercentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['taxComponentId'] = taxComponentId;
    data['componentName'] = componentName;
    data['currentPercentage'] = currentPercentage;
    return data;
  }
}
