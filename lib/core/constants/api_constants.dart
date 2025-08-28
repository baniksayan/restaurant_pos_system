// lib/core/constants/api_constants.dart
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class ApiConstants {
  ApiConstants._();

  // Base URL
  static String baseUrl = "https://posapi.uvanij.com/api/";
  static String accessToken = HiveService.getAuthToken();

  // Auth endpoints
  static const String auth = "User/authenticate";

  // Payment modes endpoints
  static const String getPaymentModes = 'api/Order/GetPaymentMode';

  // Table by outlet and type
  static const String getTablesByOutlet = 'Setting/OrderChannelListByType';

  // Order endpoints
  static const String createOrderHead = 'Order/saveOrderHead';

  // KOT endpoints
  static const String createKotWithOrderDetails = 'Order/CreateKotWithOrderDetails';

}

class ApiMethods {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';
}
