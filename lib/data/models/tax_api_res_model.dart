class TaxApiResModel {
  List<TaxData>? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  TaxApiResModel({this.data, this.message, this.isSuccess, this.statusCode});

  /// Standard fallback restaurant GST components (CGST 5% + SGST 5% = 10% GST).
  /// Ensures the POS system operates seamlessly without blocking bill generation
  /// if the remote tax API endpoint is temporarily unavailable or returns empty.
  factory TaxApiResModel.defaultRestaurantGst() {
    return TaxApiResModel(
      isSuccess: true,
      message: 'Default GST (10%)',
      statusCode: 200,
      data: [
        TaxData(
          taxComponentId: 1,
          componentName: 'CGST',
          currentPercentage: 5.0,
        ),
        TaxData(
          taxComponentId: 2,
          componentName: 'SGST',
          currentPercentage: 5.0,
        ),
      ],
    );
  }

  TaxApiResModel.fromJson(Map<dynamic, dynamic> json) {
    if (json['data'] != null && json['data'] is List) {
      data = <TaxData>[];
      for (final v in (json['data'] as List)) {
        if (v is Map) {
          data!.add(TaxData.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }
    message = json['message']?.toString();
    isSuccess = json['isSuccess'] == true || json['isSuccess'] == 1;
    statusCode = json['statusCode'] is int
        ? json['statusCode'] as int
        : int.tryParse(json['statusCode']?.toString() ?? '');
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
    return data!.fold(
      0.0,
      (sum, tax) => sum + (tax.currentPercentage?.toDouble() ?? 0.0),
    );
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
  double? currentPercentage; // Changed from int to double

  TaxData({this.taxComponentId, this.componentName, this.currentPercentage});

  TaxData.fromJson(Map<dynamic, dynamic> json) {
    taxComponentId = json['taxComponentId'] is int
        ? json['taxComponentId'] as int
        : int.tryParse(json['taxComponentId']?.toString() ?? '');
    componentName = json['componentName']?.toString();
    // Handle both int and double values from API or Hive
    if (json['currentPercentage'] != null) {
      final p = json['currentPercentage'];
      currentPercentage =
          p is num ? p.toDouble() : double.tryParse(p.toString());
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['taxComponentId'] = taxComponentId;
    data['componentName'] = componentName;
    data['currentPercentage'] = currentPercentage;
    return data;
  }
}
