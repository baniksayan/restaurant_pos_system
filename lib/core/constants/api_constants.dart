// lib/core/constants/api_constants.dart
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class ApiConstants {
  ApiConstants._();

  // Base URL
  static String baseUrl = "https://posapi.uvanij.com/api/";
  static String accessToken = HiveService.getAuthToken();

  // Auth endpoints
  static const String auth = "User/authenticate";
  static const String register = "api/signup";
  static const String googleLogin = "api/google-login";
  static const String signUp = "api/signup";
  static const String signOut = "api/signout";
  static const String forgotPassword = "api/forget-password";
  static const String resetPassword = "api/reset-password";
  static const String updatePassword = "api/update-password";
  static const String verifyOtp = "api/verify-otp";
  static const String validateOtp = "api/validate-otp";

  // Restaurant-specific endpoints (add as needed)
  static const String getMenu = "api/menu";
  static const String createOrder = "api/orders";
  static const String getTables = "api/tables";
  static const String updateTable = "api/tables";

  static const String getTablesByOutlet =
      "api/api/Setting/OrderChannelListByType";
}

class ApiMethods {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';
}
