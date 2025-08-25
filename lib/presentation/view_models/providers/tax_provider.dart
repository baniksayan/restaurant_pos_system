import 'package:flutter/material.dart';
import '../../../data/models/tax_api_res_model.dart';
import '../../../services/api_service.dart';

class TaxProvider with ChangeNotifier {
  TaxApiResModel? _taxData;
  bool _isLoading = false;
  String? _error;

  TaxApiResModel? get taxData => _taxData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get total GST percentage (CGST + SGST)
  double get totalGstPercentage {
    return _taxData?.getTotalGstPercentage() ?? 18.0; // Fallback to 18%
  }

  // Get CGST percentage
  double get cgstPercentage {
    return _taxData?.getCgstPercentage() ?? 9.0;
  }

  // Get SGST percentage
  double get sgstPercentage {
    return _taxData?.getSgstPercentage() ?? 9.0;
  }

  // Check if taxes are loaded
  bool get hasTaxData => _taxData != null;

  // Initialize tax data (method name was missing)
  Future<void> initializeTaxData(int companyId) async {
    await fetchTaxes(companyId);
  }

  Future<void> fetchTaxes(int companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the Map response from API
      final response = await ApiService.getAllTaxes(companyId: companyId);

      if (response != null) {
        // Convert Map to TaxApiResModel
        final result = TaxApiResModel.fromJson(response);

        if (result.isSuccess == true) {
          _taxData = result;
          _error = null;
        } else {
          _error = result.message ?? 'Failed to fetch tax data';
        }
      } else {
        _error = 'Failed to fetch tax data';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate GST amount for given subtotal
  double calculateGstAmount(double subtotal) {
    return subtotal * (totalGstPercentage / 100);
  }

  // Calculate CGST amount for given subtotal
  double calculateCgstAmount(double subtotal) {
    return subtotal * (cgstPercentage / 100);
  }

  // Calculate SGST amount for given subtotal
  double calculateSgstAmount(double subtotal) {
    return subtotal * (sgstPercentage / 100);
  }

  void clearTaxData() {
    _taxData = null;
    _error = null;
    notifyListeners();
  }
}
