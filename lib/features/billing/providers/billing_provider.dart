import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/shared/services/pdf_service.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/models/payment_mode_api_res_model.dart';
import 'package:restaurant_pos_system/data/models/bill_generation_models.dart';
// Prefixed: bill_details_response.dart's own PaymentDetail (a *response*
// row: mode/amount/change from getBillDetailByBillId) would otherwise
// collide with bill_generation_models.dart's PaymentDetail (the *request*
// shape SavePayment/createBill take) — both used, unprefixed, in this file.
import 'package:restaurant_pos_system/data/models/bill_details_response.dart'
    as receipt;
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';

class BillingProvider extends ChangeNotifier {
  bool _isGenerating = false;
  bool _isLoadingPaymentModes = false;
  String? _customerPhone;
  String _countryCode = "+91";
  String? _errorMessage;
  List<PaymentModeData> _paymentModes = [];
  PaymentModeData? _selectedPaymentMode;
  String? _billId; // Store billId from CreateBill response

  BillingProvider() {
    debugPrint('BillingProvider - Instance created');
  }

  // Getters
  bool get isGenerating => _isGenerating;
  bool get isLoadingPaymentModes => _isLoadingPaymentModes;
  String? get customerPhone => _customerPhone;
  String get countryCode => _countryCode;
  String? get errorMessage => _errorMessage;
  List<PaymentModeData> get paymentModes => _paymentModes;
  PaymentModeData? get selectedPaymentMode => _selectedPaymentMode;
  String? get billId {
    debugPrint('BillingProvider - BillId accessed: $_billId');
    return _billId;
  }

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

  void clearBillId() {
    _billId = null;
    debugPrint('BillingProvider - Bill ID cleared');
    notifyListeners();
  }

  // Load payment modes from API
  Future<void> loadPaymentModes() async {
    _isLoadingPaymentModes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getAllPaymentModes();

      if (response != null &&
          response.isSuccess == true &&
          response.data != null) {
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

  /// GST amount for [subtotal] at [gstPercentage].
  ///
  /// [gstPercentage] must be the live CGST+SGST rate from TaxProvider
  /// (Order/getTaxDt). It is never hardcoded here: the server computes the
  /// bill from its own TaxComponent rows inside SP_CreateBill, so a fixed
  /// rate on this side makes the amount shown/printed to the customer
  /// diverge from what is actually charged.
  double calculateGST(double subtotal, double gstPercentage) {
    return subtotal * (gstPercentage / 100);
  }

  /// The server always rounds the final payable amount UP to a whole
  /// currency unit — SP_CreateBill computes
  /// `BillAmountInclTax = CEILING(AmountAfterDiscHd + TaxAmt)`, not a plain
  /// sum. Without matching that here, this screen would show/collect e.g.
  /// ₹47.75 while the bill it creates is actually ₹48 — the bill records
  /// ₹47.75 as paid, ₹0.25 short, and sits at "Partially Paid" until that
  /// last quarter-rupee is collected separately. Ceiling here keeps what
  /// the cashier is shown and asked to collect equal to what the bill
  /// will actually require to read as fully settled.
  double calculateTotal(double subtotal, double gst) {
    return (subtotal + gst).ceilToDouble();
  }

  // Enhanced: Implement 3-step API flow for bill generation
  Future generateBill({
    required List cartItems,
    required String orderNumber,
    required double subtotal,
    required double gstAmount,
    required double total,
    String? orderId, // Add orderId parameter
    // Split-bill support: bill only these OrderDetailIds instead of every
    // unbilled item on the order. Null/empty falls back to the original
    // "bill everything still unbilled" behaviour — every existing caller is
    // unaffected. See SP_CreateBill's @ItemList — it already accepts a
    // subset, this just stops the app from always sending the full set.
    List<String>? selectedOrderDetailIds,
    // Customer info collected up front by the checkout flow (phone number,
    // then name — auto-filled if the phone matched an existing customer).
    // When supplied these win outright and Step 2's own phone-based lookup
    // is skipped; existing callers that don't pass them keep the original
    // behaviour untouched.
    String? customerPhoneOverride,
    String? customerFirstNameOverride,
    String? customerLastNameOverride,
    String? customerIdOverride,
    // Tenders taken before the bill exists — SP_CreateBill accepts payment
    // details inline and settles the bill in the same call SP_SavePayment
    // would otherwise need a second round-trip for. Empty means "bill now,
    // collect payment later" (unchanged pay-later behaviour).
    List<PaymentDetail> paymentDetails = const [],
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('=== BILL GENERATION DEBUG START ===');
      debugPrint('BillingProvider - Order Number: $orderNumber');
      debugPrint('BillingProvider - Order ID: $orderId');
      debugPrint(
        'BillingProvider - Subtotal: ${CurrencyConstants.symbol}$subtotal',
      );
      debugPrint(
        'BillingProvider - GST Amount: ${CurrencyConstants.symbol}$gstAmount',
      );
      debugPrint('BillingProvider - Total: ${CurrencyConstants.symbol}$total');
      debugPrint('BillingProvider - Cart Items Count: ${cartItems.length}');

      // Step 1: Get Order Details for Bill (if orderId is provided)
      OrderDetailForBill? orderDetail;
      if (orderId != null && orderId.isNotEmpty) {
        debugPrint('=== STEP 1: GET ORDER DETAILS FOR BILL ===');
        debugPrint(
          'BillingProvider - Calling GetOrderDetalForBill API with orderId: $orderId',
        );

        final orderDetailResponse = await ApiService.getOrderDetailForBill(
          orderId: orderId,
        );

        debugPrint('BillingProvider - GetOrderDetalForBill Response:');
        debugPrint('Success: ${orderDetailResponse?.isSuccess}');
        debugPrint('Message: ${orderDetailResponse?.message}');
        debugPrint('Status Code: ${orderDetailResponse?.statusCode}');

        if (orderDetailResponse?.isSuccess == true &&
            orderDetailResponse?.data != null) {
          orderDetail = orderDetailResponse!.data!;
          debugPrint('BillingProvider - Order Details Retrieved:');
          debugPrint('Generated Order No: ${orderDetail.generatedOrderNo}');
          debugPrint('Customer Name: ${orderDetail.customerName}');
          debugPrint('Customer Phone: ${orderDetail.customerPhoneNo}');
          debugPrint(
            'Total Price: ${CurrencyConstants.symbol}${orderDetail.totalPrice}',
          );
          debugPrint('Order Detail ID: ${orderDetail.orderDetailId}');
        } else {
          debugPrint(
            'BillingProvider - ERROR: Failed to get order details for bill',
          );
          throw Exception('Failed to get order details for bill');
        }
      } else {
        debugPrint('BillingProvider - No orderId provided, skipping Step 1');
      }

      // Step 2: Get Customer by Mobile Number (if customer phone is provided and order detail has phone)
      String customerId =
          customerIdOverride ??
          "00000000-0000-0000-0000-000000000000"; // Default customer ID
      String? resolvedFirstName = customerFirstNameOverride;
      String? resolvedLastName = customerLastNameOverride;
      final effectivePhone =
          (customerPhoneOverride != null && customerPhoneOverride.isNotEmpty)
              ? customerPhoneOverride
              : (orderDetail?.customerPhoneNo ?? _customerPhone ?? '');

      if (customerIdOverride != null) {
        debugPrint(
          'BillingProvider - Customer already resolved by caller: '
          '$customerIdOverride ($resolvedFirstName $resolvedLastName)',
        );
      } else if (orderDetail != null && orderDetail.customerPhoneNo.isNotEmpty) {
        debugPrint('=== STEP 2: GET CUSTOMER BY MOBILE ===');
        debugPrint(
          'BillingProvider - Calling getCustomerByMobileNo API with: ${orderDetail.customerPhoneNo}',
        );

        final customerResponse = await ApiService.getCustomerByMobileNo(
          contactNo: orderDetail.customerPhoneNo,
        );

        debugPrint('BillingProvider - getCustomerByMobileNo Response:');
        debugPrint('Success: ${customerResponse?.isSuccess}');
        debugPrint('Message: ${customerResponse?.message}');
        debugPrint('Status Code: ${customerResponse?.statusCode}');

        if (customerResponse?.isSuccess == true &&
            customerResponse?.data != null) {
          customerId = customerResponse!.data!.customerId;
          resolvedFirstName = customerResponse.data!.customerFirstName;
          resolvedLastName = customerResponse.data!.customerLastName;
          debugPrint('BillingProvider - Customer Details Retrieved:');
          debugPrint('Customer ID: $customerId');
          debugPrint('Customer Name: ${customerResponse.data!.customerName}');
          debugPrint(
            'Customer First Name: ${customerResponse.data!.customerFirstName}',
          );
          debugPrint(
            'Customer Last Name: ${customerResponse.data!.customerLastName}',
          );
        } else {
          debugPrint(
            'BillingProvider - Customer not found or error, using default customer ID',
          );
        }
      } else {
        debugPrint(
          'BillingProvider - No customer phone provided, using default customer ID',
        );
      }

      // Step 3: Create Bill
      debugPrint('=== STEP 3: CREATE BILL ===');
      debugPrint('BillingProvider - OrderId check: $orderId');
      debugPrint('BillingProvider - OrderDetail check: ${orderDetail != null}');

      // What was actually tendered, and in what mode — @PaidAmount and
      // @PaymentModeId on SP_CreateBill, and the per-tender rows it forwards
      // straight into SP_SavePayment. Empty means pay-later: the bill is
      // created with nothing paid, same as every existing caller today.
      final paidAmountTotal = paymentDetails.fold<double>(
        0,
        (sum, p) => sum + p.paymentAmount,
      );
      final paymentDetailsJson =
          paymentDetails.map((p) => p.toJson()).toList();
      final effectivePaymentModeId =
          paymentDetails.isNotEmpty
              ? paymentDetails.first.modeId
              : (_selectedPaymentMode?.paymentModeId ?? 1);

      if (orderId != null && orderId.isNotEmpty && orderDetail != null) {
        // Full order flow - use orderDetail data
        debugPrint('BillingProvider - Using full order flow with orderDetail');
        debugPrint(
          'BillingProvider - Creating bill with customerId: $customerId',
        );

        // A split bill sends only the items the cashier picked; otherwise
        // bill every unbilled item on the order, as before.
        final itemList =
            (selectedOrderDetailIds != null &&
                    selectedOrderDetailIds.isNotEmpty)
                ? selectedOrderDetailIds.join(',')
                : orderDetail.orderDetailId;
        debugPrint(
          'BillingProvider - itemList for createBill (split: '
          '${selectedOrderDetailIds != null}): $itemList',
        );

        final createBillRequest = CreateBillRequest(
          customerFirstName: resolvedFirstName ?? "",
          customerLastName: resolvedLastName ?? "",
          contactNo: effectivePhone,
          paidAmount: paidAmountTotal.toStringAsFixed(2),
          paymentModeId: effectivePaymentModeId,
          discountPercBillHd: 0,
          customerIdUI: customerId,
          itemList: itemList,
          splDisPer: 0,
          splDisReason: "",
          outletId:
              HiveService.getOutletId() ??
              0, // No fallback - validation will catch this
          billPrefix: "BL",
          paymentDetails: paymentDetailsJson,
        );

        debugPrint(
          'BillingProvider - CreateBill Request Body (with orderDetail):',
        );
        debugPrint(createBillRequest.toJson().toString());

        final billResponse = await ApiService.createBill(
          request: createBillRequest,
        );

        debugPrint('BillingProvider - CreateBill Response:');
        debugPrint('Success: ${billResponse?.isSuccess}');
        debugPrint('Message: ${billResponse?.message}');
        debugPrint('Status Code: ${billResponse?.statusCode}');

        if (billResponse?.isSuccess == true) {
          _billId = billResponse!.data?.billId; // Store billId
          debugPrint('BillingProvider - Bill Created Successfully:');
          debugPrint('Bill ID: $_billId');
          debugPrint(
            'Generated Bill No: ${billResponse.data?.generatedBillNo}',
          );
          debugPrint('Bill No: ${billResponse.data?.billNo}');
          debugPrint(
            'Return To Customer: ${CurrencyConstants.symbol}${billResponse.data?.returnToCustomer}',
          );
        } else {
          debugPrint('BillingProvider - ERROR: Failed to create bill via API');
          throw Exception('Failed to create bill via API');
        }
      } else {
        // Fallback - create bill without full order flow (for legacy/simple billing)
        debugPrint(
          'BillingProvider - Using fallback bill creation (no orderDetail)',
        );
        debugPrint(
          'BillingProvider - OrderId: $orderId, OrderDetail: ${orderDetail != null}',
        );

        // Create a simplified bill request
        final createBillRequest = CreateBillRequest(
          customerFirstName: resolvedFirstName ?? "",
          customerLastName: resolvedLastName ?? "",
          contactNo: effectivePhone,
          paidAmount: paidAmountTotal.toStringAsFixed(2),
          paymentModeId: effectivePaymentModeId,
          discountPercBillHd: 0,
          customerIdUI: customerId,
          itemList:
              "", // Empty for now - might need to generate from cart items
          splDisPer: 0,
          splDisReason: "",
          outletId:
              HiveService.getOutletId() ??
              0, // No fallback - validation will catch this
          billPrefix: "BL",
          paymentDetails: paymentDetailsJson,
        );

        debugPrint('BillingProvider - CreateBill Request Body (fallback):');
        debugPrint(createBillRequest.toJson().toString());

        final billResponse = await ApiService.createBill(
          request: createBillRequest,
        );

        debugPrint('BillingProvider - CreateBill Fallback Response:');
        debugPrint('Success: ${billResponse?.isSuccess}');
        debugPrint('Message: ${billResponse?.message}');
        debugPrint('Status Code: ${billResponse?.statusCode}');

        if (billResponse?.isSuccess == true) {
          _billId = billResponse!.data?.billId; // Store billId
          debugPrint('BillingProvider - Fallback Bill Created Successfully:');
          debugPrint('Bill ID: $_billId');
          debugPrint(
            'Generated Bill No: ${billResponse.data?.generatedBillNo}',
          );
          debugPrint('Bill No: ${billResponse.data?.billNo}');
          debugPrint(
            'Return To Customer: ${CurrencyConstants.symbol}${billResponse.data?.returnToCustomer}',
          );
        } else {
          debugPrint(
            'BillingProvider - ERROR: Failed to create fallback bill via API',
          );
          throw Exception('Failed to create bill via API');
        }
      }

      // Step 3.5: Fetch the bill exactly as the server recorded it — real
      // company details (name/address/GST number) and the real tax it
      // computed — so the printed PDF matches what was actually charged
      // instead of a client-side approximation. Falls back to the
      // already-computed subtotal/gstAmount/total (and PDFService's own
      // placeholder company info) if this call fails; billing must never
      // be blocked by a PDF-cosmetics fetch.
      String? realCompanyName;
      String? realCompanyAddress;
      String? realCompanyPhone;
      String? realCompanyGstNo;
      double pdfSubtotal = subtotal;
      double pdfGstAmount = gstAmount;
      double pdfTotal = total;
      String pdfGstLabel = 'GST';
      String? realBillNo;
      String? realCustomerName;
      String? realCustomerPhone;
      double realDiscountAmount = 0;
      List<receipt.PaymentDetail>? realPayments;

      if (_billId != null && _billId!.isNotEmpty) {
        try {
          final billDetailsResponse = await ApiService.getBillDetailByBillId(
            billId: _billId!,
          );
          final billData = billDetailsResponse?.data;
          if (billDetailsResponse?.isSuccess == true && billData != null) {
            realCompanyName = billData.companyDt.companyName;
            realCompanyAddress = billData.companyDt.companyAddress;
            realCompanyPhone = billData.companyDt.contactNo;
            realCompanyGstNo = billData.companyDt.gstNo;

            pdfSubtotal = billData.billHeadDt.amountAfterDisc;
            pdfTotal = billData.billHeadDt.billAmountInclTax;
            final realGst = pdfTotal - pdfSubtotal;
            pdfGstAmount = realGst > 0 ? realGst : 0;

            if (billData.taxInf.isNotEmpty) {
              final totalPct = billData.taxInf.fold<double>(
                0,
                (sum, t) => sum + t.taxPercentage,
              );
              pdfGstLabel =
                  'GST (${totalPct % 1 == 0 ? totalPct.toStringAsFixed(0) : totalPct.toStringAsFixed(1)}%)';
            }

            realBillNo = billData.billHeadDt.billNo;
            realCustomerName = billData.billHeadDt.customerName;
            realCustomerPhone = billData.billHeadDt.custMobNo;
            realDiscountAmount =
                billData.billHeadDt.discountAmnt + billData.billHeadDt.specDisAmt;
            realPayments = billData.paymentDetail;
          }
        } catch (e) {
          debugPrint(
            'BillingProvider - Could not fetch real bill details for PDF, '
            'falling back to computed totals: $e',
          );
        }
      }

      // Step 4: Generate PDF — 80mm thermal receipt, the format this
      // industry actually prints on, not an A4 invoice.
      debugPrint('=== STEP 4: GENERATE PDF ===');
      debugPrint('BillingProvider - Generating PDF for bill...');

      final billBytes = await PDFService.generateThermalBill(
        items: cartItems, // Let PDFService handle the type conversion
        tableId: cartItems.first.tableId,
        tableName: cartItems.first.tableName,
        orderNumber: orderNumber,
        orderTime: DateTime.now(),
        subtotal: pdfSubtotal,
        gstAmount: pdfGstAmount,
        total: pdfTotal,
        companyName: realCompanyName,
        companyAddress: realCompanyAddress,
        companyPhone: realCompanyPhone,
        companyGstNo: realCompanyGstNo,
        gstLabel: pdfGstLabel,
        billNo: realBillNo,
        customerName: realCustomerName,
        customerPhone: realCustomerPhone,
        discountAmount: realDiscountAmount,
        payments: realPayments,
      );

      debugPrint('BillingProvider - PDF generated successfully');
      debugPrint('BillingProvider - Final stored billId: $_billId');
      debugPrint('=== BILL GENERATION DEBUG END ===');

      _isGenerating = false;
      notifyListeners();
      return billBytes;
    } catch (e) {
      _errorMessage = 'Error generating bill: $e';
      _isGenerating = false;
      notifyListeners();
      debugPrint('=== BILL GENERATION ERROR ===');
      debugPrint('BillingProvider - Bill generation error: $e');
      debugPrint('BillingProvider - Error Type: ${e.runtimeType}');
      debugPrint('BillingProvider - Current billId: $_billId');
      rethrow;
    }
  }
}
