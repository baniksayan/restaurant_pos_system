class ApiConstants {
  ApiConstants._();

  // Base URL
  static String baseUrl = "https://posapi.uvanij.com/api/";

  // Auth endpoints
  static const String auth = "User/authenticate";

  // Payment modes endpoints
  static const String getPaymentModes = 'api/Order/GetPaymentMode';

  // Payments already recorded against a bill. Needed to work out how much is
  // still owed on a partially-paid bill — without it the payment screen shows
  // the full bill total again on a second visit.
  static const String getPaymentDetailsByBillId = 'Order/GetPaymentDtByBillId';

  // Table by outlet and type
  static const String getTablesByOutlet = 'Setting/OrderChannelListByType';

  // Order endpoints
  static const String createOrderHead = 'Order/saveOrderHead';

  // KOT endpoints
  static const String createKotWithOrderDetails =
      'Order/CreateKotWithOrderDetails';

  /// Fires a KOT for the order lines already saved on the server, without
  /// sending any items. CreateKotWithOrderDetails saves the items and then
  /// creates the KOT as two separate, non-transactional steps server-side, so
  /// this is the correct endpoint to retry with when the items were persisted
  /// but the KOT step failed — retrying the combined call would insert the
  /// same items a second time.
  static const String createKotWithoutBatch = 'Order/CreateKotWithoutBatch';

  // Product endpoints
  static const String getItemSearch = 'Product/GetItemSearch';

  // Order Channel Types
  static const String getOrderChannelTypes = 'Setting/GetOrderChannelTypes';
}

class ApiMethods {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';
}
