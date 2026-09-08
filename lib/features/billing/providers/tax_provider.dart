import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/tax_api_res_model.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class TaxProvider with ChangeNotifier {
  TaxApiResModel? _taxData;
  bool _isLoading = false;
  String? _error;

  TaxApiResModel? get taxData => _taxData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get total GST percentage (CGST + SGST)
  double get totalGstPercentage {
    return _taxData?.getTotalGstPercentage() ?? 0; // Default fallback
  }

  // Get CGST percentage
  double get cgstPercentage {
    return _taxData?.getCgstPercentage() ?? 0; // Default fallback
  }

  // Get SGST percentage
  double get sgstPercentage {
    return _taxData?.getSgstPercentage() ?? 0; // Default fallback
  }

  // Check if taxes are loaded
  bool get hasTaxData => _taxData != null;

  // Initialize tax data from Hive or API
  Future<void> initializeTaxData() async {
    debugPrint('🔄 INITIALIZING TAX DATA...');

    // Debug what's currently in Hive
    debugHiveData();

    // First try to load from Hive
    await _loadTaxDataFromHive();

    debugPrint('After Hive load - hasTaxData: $hasTaxData');

    // Check if we have valid data or if it's expired
    final isExpired = HiveService.isTaxDataExpired();
    debugPrint('Tax data expiry check: $isExpired');

    // Force API fetch if:
    // 1. No data in memory (_taxData == null)
    // 2. Data is expired
    // 3. Data exists but is empty/invalid
    bool needsApiFetch =
        _taxData == null || isExpired || (_taxData?.data?.isEmpty ?? true);

    if (needsApiFetch) {
      debugPrint(
        '📡 Need to fetch from API - Reasons: taxData=${_taxData == null}, expired=$isExpired, empty=${(_taxData?.data?.isEmpty ?? true)}',
      );

      // Get outlet ID for API call
      final outletId = HiveService.getOutletId();
      debugPrint('Outlet ID for API call: $outletId');

      if (outletId != null && outletId > 0) {
        await fetchTaxes(outletId);
      } else {
        debugPrint('❌ No outlet ID available for tax data fetch');
        // If no outlet ID, try to get it from auth data
        final authData = HiveService.getAuthData();
        final fallbackOutletId = authData?.data?.location?.locationId;
        debugPrint('Trying fallback outlet ID from auth: $fallbackOutletId');

        if (fallbackOutletId != null && fallbackOutletId > 0) {
          HiveService.setOutletId(fallbackOutletId);
          await fetchTaxes(fallbackOutletId);
        }
      }
    } else {
      debugPrint('✅ Using valid tax data from Hive - no API call needed');
    }

    debugPrint(
      '🏁 TAX INITIALIZATION COMPLETE - hasTaxData: $hasTaxData, dataCount: ${_taxData?.data?.length}',
    );
  }

  // Manual method to force refresh tax data from API
  Future<void> refreshTaxData() async {
    final outletId = HiveService.getOutletId();
    if (outletId != null && outletId > 0) {
      await fetchTaxes(outletId);
    }
  }

  // Debug method to check what's in Hive
  void debugHiveData() {
    debugPrint('=== HIVE DEBUG INFO ===');
    final savedData = HiveService.getTaxData();
    final timestamp = HiveService.getTaxDataTimestamp();
    final isExpired = HiveService.isTaxDataExpired();
    final outletId = HiveService.getOutletId();

    debugPrint('Hive tax data exists: ${savedData != null}');
    debugPrint('Data timestamp: $timestamp');
    debugPrint('Is expired: $isExpired');
    debugPrint('Outlet ID: $outletId');
    debugPrint('Current _taxData is null: ${_taxData == null}');
    debugPrint('hasTaxData: $hasTaxData');

    if (savedData != null) {
      debugPrint('Saved data keys: ${savedData.keys}');
    }
    debugPrint('=== END HIVE DEBUG ===');
  }

  // Load tax data from Hive storage
  Future<void> _loadTaxDataFromHive() async {
    try {
      debugPrint('=== LOADING TAX DATA FROM HIVE ===');
      final savedTaxData = HiveService.getTaxData();
      debugPrint('Hive tax data retrieved: ${savedTaxData != null}');

      if (savedTaxData != null) {
        debugPrint('Tax data content: $savedTaxData');
        final result = TaxApiResModel.fromJson(savedTaxData);
        debugPrint(
          'Parsed tax result - isSuccess: ${result.isSuccess}, data count: ${result.data?.length}',
        );

        if (result.isSuccess == true &&
            result.data != null &&
            result.data!.isNotEmpty) {
          _taxData = result;
          _error = null;
          debugPrint(
            '✅ Tax data loaded from Hive: ${_taxData?.data?.length} components',
          );

          // Log each tax component
          _taxData?.data?.forEach((tax) {
            debugPrint('  - ${tax.componentName}: ${tax.currentPercentage}%');
          });

          notifyListeners();
        } else {
          debugPrint(
            '❌ Tax data invalid - isSuccess: ${result.isSuccess}, hasData: ${result.data != null}',
          );
        }
      } else {
        debugPrint('❌ No tax data found in Hive');
      }
      debugPrint('=== HIVE LOAD COMPLETE ===');
    } catch (e) {
      debugPrint('❌ Error loading tax data from Hive: $e');
    }
  }

  Future<void> fetchTaxes(int companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Fetching tax data from API for company: $companyId');

      // Get the Map response from API
      final response = await ApiService.getAllTaxes(companyId: companyId);

      if (response != null) {
        // Convert Map to TaxApiResModel
        final result = TaxApiResModel.fromJson(response);

        if (result.isSuccess == true) {
          _taxData = result;
          _error = null;

          // Save to Hive for future use
          HiveService.saveTaxData(response);

          debugPrint(
            'Tax data fetched and saved: ${_taxData?.data?.length} components',
          );
          debugPrint(
            'CGST: $cgstPercentage%, SGST: $sgstPercentage%, Total: $totalGstPercentage%',
          );
        } else {
          _error = result.message ?? 'Failed to fetch tax data';
          debugPrint('Tax API returned error: $_error');
        }
      } else {
        _error = 'Failed to fetch tax data - no response';
        debugPrint('Tax API returned no response');
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('Exception fetching tax data: $e');
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

  // Get tax breakdown for display
  Map<String, dynamic> getTaxBreakdown(double subtotal) {
    return {
      'subtotal': subtotal,
      'cgstPercentage': cgstPercentage,
      'sgstPercentage': sgstPercentage,
      'cgstAmount': calculateCgstAmount(subtotal),
      'sgstAmount': calculateSgstAmount(subtotal),
      'totalTaxPercentage': totalGstPercentage,
      'totalTaxAmount': calculateGstAmount(subtotal),
      'totalAmount': subtotal + calculateGstAmount(subtotal),
      'isDataFromApi': hasTaxData,
    };
  }

  void clearTaxData() {
    _taxData = null;
    _error = null;
    HiveService.clearTaxData();
    notifyListeners();
  }
}
