import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/services/pdf_service.dart';
import 'package:restaurant_pos_system/services/api_service.dart';
import 'package:restaurant_pos_system/data/models/payment_mode_api_res_model.dart';
import 'package:restaurant_pos_system/data/models/bill_generation_models.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import '../../../core/constants/currency_constants.dart';

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

  double calculateGST(double subtotal) {
    return subtotal * 0.05;
  }

  double calculateTotal(double subtotal, double gst) {
    return subtotal + gst;
  }

  // Enhanced: Implement 3-step API flow for bill generation
  Future generateBill({
    required List cartItems,
    required String orderNumber,
    required double subtotal,
    required double gstAmount,
    required double total,
    String? orderId, // Add orderId parameter
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
          "00000000-0000-0000-0000-000000000000"; // Default customer ID
      if (orderDetail != null && orderDetail.customerPhoneNo.isNotEmpty) {
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

      if (orderId != null && orderId.isNotEmpty && orderDetail != null) {
        // Full order flow - use orderDetail data
        debugPrint('BillingProvider - Using full order flow with orderDetail');
        debugPrint(
          'BillingProvider - Creating bill with customerId: $customerId',
        );

        final createBillRequest = CreateBillRequest(
          customerFirstName: "",
          customerLastName: "",
          contactNo: orderDetail.customerPhoneNo,
          paidAmount: "0.00",
          paymentModeId: _selectedPaymentMode?.paymentModeId ?? 1,
          discountPercBillHd: 0,
          customerIdUI: customerId,
          itemList: orderDetail.orderDetailId,
          splDisPer: 0,
          splDisReason: "",
          outletId:
              HiveService.getOutletId() ??
              0, // No fallback - validation will catch this
          billPrefix: "BL",
          paymentDetails: [],
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
          customerFirstName: "",
          customerLastName: "",
          contactNo: _customerPhone ?? "",
          paidAmount: "0.00",
          paymentModeId: _selectedPaymentMode?.paymentModeId ?? 1,
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
          paymentDetails: [],
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

      // Step 4: Generate PDF (existing logic)
      debugPrint('=== STEP 4: GENERATE PDF ===');
      debugPrint('BillingProvider - Generating PDF for bill...');

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
