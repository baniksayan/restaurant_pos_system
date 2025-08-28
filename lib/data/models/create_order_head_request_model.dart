class CreateOrderHeadRequestModel {
  String orderChannelId;
  String waiterId;
  String custPhoneNo;
  String ordPrefix;
  String tokenNo;
  String orderIdentifier;
  int totalAdult;
  int totalChild;
  String customerName;
  String orderIdUI;
  int outletId;
  String custEmailId;
  String custDob;
  String customerIdUI;
  String userId;

  CreateOrderHeadRequestModel({
    required this.orderChannelId,
    required this.waiterId,
    this.custPhoneNo = "",
    this.ordPrefix = "OD",
    this.tokenNo = "",
    this.orderIdentifier = "",
    this.totalAdult = 0,
    this.totalChild = 0,
    required this.customerName,
    this.orderIdUI = "00000000-0000-0000-0000-000000000000",
    required this.outletId,
    this.custEmailId = "",
    this.custDob = "",
    this.customerIdUI = "00000000-0000-0000-0000-000000000000",
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      "orderChannelId": orderChannelId,
      "waiterId": waiterId,
      "custPhoneNo": custPhoneNo,
      "ordPrefix": ordPrefix,
      "tokenNo": tokenNo,
      "orderIdentifier": orderIdentifier,
      "totalAdult": totalAdult,
      "totalChild": totalChild,
      "customerName": customerName,
      "orderIdUI": orderIdUI,
      "outletId": outletId,
      "custEmailId": custEmailId,
      "custDob": custDob,
      "customerIdUI": customerIdUI,
      "userId": userId,
    };
  }
}
