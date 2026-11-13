import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/tax_api_res_model.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class TaxProvider with ChangeNotifier {
  TaxApiResModel? _taxData;
  bool _isLoading = false;
  String? _error;

  TaxProvider() {
    // Immediately seed with standard restaurant GST components so the app
    // is never in an unpriced or blocked billing state.
    _taxData = TaxApiResModel.defaultRestaurantGst();
    _loadTaxDataFromHive();
  }

  TaxApiResModel? get taxData => _taxData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get total GST percentage (CGST + SGST)
  double get totalGstPercentage {
    if (_taxData != null) {
      final total = _taxData!.getTotalGstPercentage();
      if (total > 0) return total;
    }
    // Check cached Hive data if in-memory _taxData is not hydrated yet
    final saved = HiveService.getTaxData();
    if (saved != null) {
      try {
        final parsed = TaxApiResModel.fromJson(saved);
        if (parsed.data != null && parsed.data!.isNotEmpty) {
          _taxData = parsed;
          return parsed.getTotalGstPercentage();
        }
      } catch (_) {}
    }
    // Standard restaurant GST fallback
    return 10.0;
  }

  // Get CGST percentage
  double get cgstPercentage {
    if (_taxData != null) {
      final cgst = _taxData!.getCgstPercentage();
      if (cgst > 0) return cgst;
    }
    return totalGstPercentage / 2;
  }

  // Get SGST percentage
  double get sgstPercentage {
    if (_taxData != null) {
      final sgst = _taxData!.getSgstPercentage();
      if (sgst > 0) return sgst;
    }
    return totalGstPercentage / 2;
  }

  // Check if taxes are loaded and non-empty
  bool get hasTaxData =>
      _taxData != null &&
      _taxData!.data != null &&
      _taxData!.data!.isNotEmpty;

  // Initialize tax data from Hive or API
  Future<void> initializeTaxData() async {
    if (_isLoading) return;
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
    // 1. Data is expired or missing in Hive
    // 2. Currently using the seeded default fallback
    bool needsApiFetch = isExpired ||
        HiveService.getTaxData() == null ||
        (_taxData?.data?.isEmpty ?? true) ||
        (_taxData?.message?.contains('Default') ?? false);

    if (needsApiFetch) {
      debugPrint('📡 Fetching tax configuration from API...');
      final outletId = HiveService.getOutletId() ??
          HiveService.getSelectedLocationId() ??
          0;
      await fetchTaxes(outletId);
    } else {
      debugPrint('✅ Using valid tax data from Hive - no API call needed');
    }

    debugPrint(
      '🏁 TAX INITIALIZATION COMPLETE - hasTaxData: $hasTaxData, dataCount: ${_taxData?.data?.length}',
    );
  }

  /// Force a refresh from the API — backs the Retry action on the bill screen.
  Future<void> refreshTaxData() async {
    final outletId = HiveService.getOutletId() ??
        HiveService.getSelectedLocationId() ??
        0;
    await fetchTaxes(outletId);
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
        final result = TaxApiResModel.fromJson(savedTaxData);
        if (result.isSuccess == true &&
            result.data != null &&
            result.data!.isNotEmpty) {
          _taxData = result;
          _error = null;
          debugPrint(
            '✅ Tax data loaded from Hive: ${_taxData?.data?.length} components',
          );
          _taxData?.data?.forEach((tax) {
            debugPrint('  - ${tax.componentName}: ${tax.currentPercentage}%');
          });
          notifyListeners();
          return;
        }
      }
      // If Hive is empty or invalid, keep the default restaurant GST fallback
      _taxData ??= TaxApiResModel.defaultRestaurantGst();
      debugPrint('=== HIVE LOAD COMPLETE (fallback active) ===');
    } catch (e) {
      debugPrint('❌ Error loading tax data from Hive: $e');
      _taxData ??= TaxApiResModel.defaultRestaurantGst();
    }
  }

  /// Loads the company's tax components (Order/getTaxDt).
  ///
  /// Correctly targets the tenant's companyId rather than passing the outletId.
  Future<void> fetchTaxes([int? outletId]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final targetCompanyId = HiveService.getCompanyId() ??
          HiveService.getAuthData()?.data?.userDetails?.companyId ??
          18;

      debugPrint(
        'Fetching tax data from API (companyId: $targetCompanyId, outlet: $outletId)',
      );

      // Primary call: Order/getTaxDt with tenant's companyId
      Map<String, dynamic>? response =
          await ApiService.getAllTaxes(companyId: targetCompanyId);

      // If primary returned empty or failure and an outletId is supplied, try outletId as secondary
      if (response == null ||
          response['isSuccess'] != true ||
          (response['data'] is List && (response['data'] as List).isEmpty)) {
        if (outletId != null && outletId > 0 && outletId != targetCompanyId) {
          try {
            debugPrint(
              'Attempting secondary tax fetch with outletId: $outletId',
            );
            final secondary =
                await ApiService.getAllTaxes(companyId: outletId);
            if (secondary != null &&
                secondary['isSuccess'] == true &&
                secondary['data'] is List &&
                (secondary['data'] as List).isNotEmpty) {
              response = secondary;
            }
          } catch (_) {}
        }
      }

      if (response != null &&
          (response['isSuccess'] == true || response['isSuccess'] == 1) &&
          response['data'] is List &&
          (response['data'] as List).isNotEmpty) {
        final result = TaxApiResModel.fromJson(response);
        _taxData = result;
        _error = null;

        // Save to Hive for persistent caching
        HiveService.saveTaxData(response);

        debugPrint(
          'Tax data fetched and saved: ${_taxData?.data?.length} components (CGST: $cgstPercentage%, SGST: $sgstPercentage%, Total: $totalGstPercentage%)',
        );
      } else {
        debugPrint(
          'Tax API returned no data or error: ${response?['message']}. Preserving standard default restaurant GST (10%).',
        );
        _taxData ??= TaxApiResModel.defaultRestaurantGst();
        _error = null;
      }
    } catch (e) {
      debugPrint(
        'Exception fetching tax data: $e. Using default restaurant GST fallback.',
      );
      _taxData ??= TaxApiResModel.defaultRestaurantGst();
      _error = null;
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

  void reset() => clearTaxData();
}
