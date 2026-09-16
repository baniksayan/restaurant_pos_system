/// The tenant's own profile — name, address, GST number, and real currency
/// (code + symbol, not assumed). Backed by Setting/GetCompanyInfo, fetched
/// once after login and cached (see HiveService.saveCompanyInfo) rather than
/// refetched per screen.
class CompanyInfoResponse {
  final CompanyInfo? data;
  final String message;
  final bool isSuccess;
  final int statusCode;

  CompanyInfoResponse({
    this.data,
    required this.message,
    required this.isSuccess,
    required this.statusCode,
  });

  factory CompanyInfoResponse.fromJson(Map<String, dynamic> json) {
    return CompanyInfoResponse(
      data: json['data'] != null ? CompanyInfo.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
      statusCode: json['statusCode'] ?? 0,
    );
  }
}

class CompanyInfo {
  final int companyId;
  final String companyName;
  final String companyAddress;
  final String companyPinNo;
  final String gstNo;
  final String contactNo;
  final String currencyCode;
  final String currencySymbol;
  final String logoFileName;
  final String website;

  CompanyInfo({
    required this.companyId,
    required this.companyName,
    required this.companyAddress,
    required this.companyPinNo,
    required this.gstNo,
    required this.contactNo,
    required this.currencyCode,
    required this.currencySymbol,
    required this.logoFileName,
    required this.website,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      companyId: (json['companyId'] is num) ? (json['companyId'] as num).toInt() : 0,
      companyName: json['companyName'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      companyPinNo: json['companyPinNo'] ?? '',
      gstNo: json['gSTNo'] ?? json['gstNo'] ?? '',
      contactNo: json['contactNo'] ?? '',
      currencyCode: json['currencyCode'] ?? '',
      currencySymbol: json['currencySymbol'] ?? '',
      logoFileName: json['logoFileName'] ?? '',
      website: json['website'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyPinNo': companyPinNo,
      'gstNo': gstNo,
      'contactNo': contactNo,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'logoFileName': logoFileName,
      'website': website,
    };
  }
}
