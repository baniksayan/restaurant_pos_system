import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/services/pdf_service.dart';

class BillingProvider extends ChangeNotifier {
  bool _isGenerating = false;
  String? _customerPhone;
  String _countryCode = "+91";
  String? _errorMessage;

  bool get isGenerating => _isGenerating;
  String? get customerPhone => _customerPhone;
  String get countryCode => _countryCode;
  String? get errorMessage => _errorMessage;

  void setCustomerPhone(String? phone) {
    _customerPhone = phone;
    notifyListeners();
  }

  void setCountryCode(String code) {
    _countryCode = code;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fix: Accept dynamic list and handle type conversion
  double calculateSubtotal(List<dynamic> cartItems) {
    return cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  double calculateGST(double subtotal) {
    return subtotal * 0.18;
  }

  double calculateTotal(double subtotal, double gst) {
    return subtotal + gst;
  }

  // Fix: Accept dynamic list instead of specific type
  Future<dynamic> generateBill({
    required List<dynamic> cartItems,
    required String orderNumber,
    required double subtotal,
    required double gstAmount,
    required double total,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final billBytes = await PDFService.generateCustomerBill(
        items: cartItems, // Let PDFService handle the type conversion
        tableId: cartItems.first.tableId,
        tableName: cartItems.first.tableName,
        orderNumber: orderNumber,
        orderTime: DateTime.now(),
        subtotal: subtotal,
        gstAmount: gstAmount,
        total: total,
      );

      _isGenerating = false;
      notifyListeners();
      return billBytes;
    } catch (e) {
      _errorMessage = 'Error generating bill: $e';
      _isGenerating = false;
      notifyListeners();
      rethrow;
    }
  }
}
