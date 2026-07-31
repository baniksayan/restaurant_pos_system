import 'package:shared_preferences/shared_preferences.dart';

class UpiStorageService {
  static const String _keyUpiId = 'restaurant_upi_id';
  static const String _keyMerchantName = 'restaurant_merchant_name';
  static const String defaultUpiId = '8768412832@ptsbi';
  static const String defaultMerchantName = 'WiZARD Restaurant';

  /// Get configured UPI ID from SharedPreferences
  static Future<String> getUpiId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final upiId = prefs.getString(_keyUpiId);
      if (upiId != null && upiId.trim().isNotEmpty) {
        return upiId.trim();
      }
    } catch (_) {}
    return defaultUpiId;
  }

  /// Save new UPI ID to SharedPreferences
  static Future<bool> setUpiId(String upiId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyUpiId, upiId.trim());
    } catch (_) {
      return false;
    }
  }

  /// Get merchant/restaurant name for UPI payments
  static Future<String> getMerchantName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyMerchantName);
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {}
    return defaultMerchantName;
  }

  /// Save merchant/restaurant name to SharedPreferences
  static Future<bool> setMerchantName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyMerchantName, name.trim());
    } catch (_) {
      return false;
    }
  }
}
