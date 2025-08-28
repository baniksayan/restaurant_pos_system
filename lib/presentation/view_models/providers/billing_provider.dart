import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/services/pdf_service.dart';
import 'package:restaurant_pos_system/services/api_service.dart';
import 'package:restaurant_pos_system/data/models/payment_mode_api_res_model.dart';

class BillingProvider extends ChangeNotifier {
  bool _isGenerating = false;
  bool _isLoadingPaymentModes = false;
  String? _customerPhone;
  String _countryCode = "+91";
  String? _errorMessage;
  List<PaymentModeData> _paymentModes = [];
  PaymentModeData? _selectedPaymentMode;

  // Getters
  bool get isGenerating => _isGenerating;
  bool get isLoadingPaymentModes => _isLoadingPaymentModes;
  String? get customerPhone => _customerPhone;
  String get countryCode => _countryCode;
  String? get errorMessage => _errorMessage;
  List<PaymentModeData> get paymentModes => _paymentModes;
  PaymentModeData? get selectedPaymentMode => _selectedPaymentMode;

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

  void setSelectedPaymentMode(PaymentModeData? paymentMode) {
    _selectedPaymentMode = paymentMode;
    notifyListeners();
  }

  // Load payment modes from API
  Future<void> loadPaymentModes() async {
    _isLoadingPaymentModes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getAllPaymentModes();
      
      if (response != null && response.isSuccess == true && response.data != null) {
        _paymentModes = response.data!;
        
        // Auto-select first payment mode if none selected
        if (_selectedPaymentMode == null && _paymentModes.isNotEmpty) {
          _selectedPaymentMode = _paymentModes.first;
        }
        
        if (kDebugMode) {
          debugPrint('Loaded ${_paymentModes.length} payment modes');
        }
      } else {
        _errorMessage = response?.message ?? 'Failed to load payment modes';
        if (kDebugMode) {
          debugPrint('Failed to load payment modes: ${response?.message}');
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading payment modes: $e';
      if (kDebugMode) {
        debugPrint('Error loading payment modes: $e');
      }
    } finally {
      _isLoadingPaymentModes = false;
      notifyListeners();
    }
  }

  // Fix: Accept dynamic list and handle type conversion
  double calculateSubtotal(List cartItems) {
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
  Future generateBill({
    required List cartItems,
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
