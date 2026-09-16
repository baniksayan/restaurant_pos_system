import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import 'package:restaurant_pos_system/features/order_taking/views/cart_view.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import '../models/order_management_model.dart';
import 'package:restaurant_pos_system/shared/services/pdf_service.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/order_detail_api_response_model.dart';
import 'package:restaurant_pos_system/data/models/bill_details_response.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/features/billing/widgets/bill_pdf_viewer_dialog.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class OrderDetailView extends StatefulWidget {
  final OrderItem order;

  const OrderDetailView({super.key, required this.order});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  // API-backed state
  bool _loading = true;
  String? _error;
  OrderDetailApiResponseModel? _detailModel;

  bool _isBilled = false;
  bool _isKOTGenerated = true;
  final String _paymentMode = 'Cash';

  // Track if cart has been loaded to prevent duplicates
  bool _cartLoaded = false;

  // The real bill — company details, exact tax, exact discount — fetched
  // from Order/getBillDetailByBillId once we know this order has a billId.
  // getOrderDetailById (which _detailModel comes from) has no tax data at
  // all: tax is computed once, at billing time, and stored per-bill, not
  // per-order. This is the only accurate source for it.
  BillDetailsData? _billDetails;
  bool _loadingBillDetails = false;

  // Every bill raised against this order — a split bill produces more than
  // one, and getOrderDetailById only ever reports a single billId/billNo
  // (whichever OrderDetails row happens to be first), so that alone can't
  // list them all. Fetched via the same GetBillForReprint the Reprint
  // screen uses, then narrowed to this order's GeneratedOrderNo.
  List<PendingBill> _bills = [];
  bool _loadingBills = false;
  String? _printingBillId;

  // Derived values computed from API response (fallback to widget.order where appropriate)
  double get _subtotal {
    if (_billDetails != null) {
      return _billDetails!.billHeadDt.amountAfterDisc;
    }
    if (_detailModel?.data != null &&
        _detailModel!.data!.isNotEmpty &&
        _detailModel!.data!.first.orderDetailList != null) {
      final list = _detailModel!.data!.first.orderDetailList!;
      double s = 0.0;
      for (final d in list) {
        s += (d.totPrice ?? 0).toDouble();
      }
      return s;
    }
    return widget.order.totalAmount;
  }

  /// Real tax amount once the bill is loaded; `0` beforehand — there is
  /// genuinely no tax figure to show until a bill exists (see [_billDetails]).
  double get _gstAmount {
    if (_billDetails == null) return 0.0;
    final gst =
        _billDetails!.billHeadDt.billAmountInclTax -
        _billDetails!.billHeadDt.amountAfterDisc;
    return gst > 0 ? gst : 0.0;
  }

  /// e.g. "GST (5%)" once the real tax components are known, else a plain
  /// "GST" label so we're never showing a guessed percentage.
  String get _gstLabel {
    if (_billDetails == null || _billDetails!.taxInf.isEmpty) return 'GST';
    final totalPct = _billDetails!.taxInf.fold<double>(
      0,
      (sum, t) => sum + t.taxPercentage,
    );
    final pctStr =
        totalPct % 1 == 0
            ? totalPct.toStringAsFixed(0)
            : totalPct.toStringAsFixed(1);
    return 'GST ($pctStr%)';
  }

  double get _serviceCharge => 0.0; // backend not providing
  double get _discount {
    if (_billDetails != null) {
      return _billDetails!.billHeadDt.discountAmnt +
          _billDetails!.billHeadDt.specDisAmt;
    }
    return 0.0;
  }

  double get _grandTotal {
    if (_billDetails != null) return _billDetails!.billHeadDt.billAmountInclTax;
    return _subtotal + _gstAmount + _serviceCharge - _discount;
  }

  String get _createdOnString {
    if (_detailModel?.data != null &&
        _detailModel!.data!.isNotEmpty &&
        _detailModel!.data!.first.orderDetailList != null &&
        _detailModel!.data!.first.orderDetailList!.isNotEmpty) {
      final d = _detailModel!.data!.first.orderDetailList!.first.createdOn;
      if (d != null && d.isNotEmpty) return d;
    }
    return widget.order.orderTime.toString();
  }

  String? get _kotNo {
    if (_detailModel?.data != null &&
        _detailModel!.data!.isNotEmpty &&
        _detailModel!.data!.first.orderDetailList != null &&
        _detailModel!.data!.first.orderDetailList!.isNotEmpty) {
      return _detailModel!.data!.first.orderDetailList!.first.kotNo;
    }
    return null;
  }

  String? get _orderNo {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.orderNo;
    }
    return null;
  }

  String? get _billNo {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.billNo?.toString();
    }
    return null;
  }

  String? get _billId {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.billId;
    }
    return null;
  }

  bool get _isActuallyBilled {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.isBilled ?? false;
    }
    return _isBilled;
  }

  bool get _isActuallyPaid {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.isPaid ?? false;
    }
    return false;
  }

  String? get _channelName {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.channelName;
    }
    return null;
  }

  String? get _waiterName {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.waiterName;
    }
    return null;
  }

  String? get _fullOrderStatus {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      return _detailModel!.data!.first.fullOrderStatus;
    }
    return null;
  }

  String? get _instructions {
    if (_detailModel?.data != null &&
        _detailModel!.data!.isNotEmpty &&
        _detailModel!.data!.first.orderDetailList != null &&
        _detailModel!.data!.first.orderDetailList!.isNotEmpty) {
      return _detailModel!.data!.first.orderDetailList!.first.instruction ?? '';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _isBilled =
        widget.order.status == OrderStatusType.completed ||
        widget.order.status == OrderStatusType.delivered;
    // Set KOT status based on order status
    _isKOTGenerated =
        widget.order.status.index >= OrderStatusType.accepted.index;

    // Load order detail from API
    _loadOrderDetail();
  }

  @override
  void dispose() {
    // Reset cart loaded state when leaving order details
    _cartLoaded = false;
    super.dispose();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = HiveService.getAuthToken();
    final orderId = widget.order.orderId;

    if (token.isEmpty || orderId.isEmpty) {
      setState(() {
        _error = 'Missing token or order id';
        _loading = false;
      });
      return;
    }

    try {
      final resp = await ApiService.getOrderDetailById(
        token: token,
        orderId: orderId,
      );

      if (resp != null &&
          resp.isSuccess == true &&
          resp.data != null &&
          resp.data!.isNotEmpty) {
        setState(() {
          _detailModel = resp;
          _loading = false;
        });
        // Now that we know whether this order is billed and (if so) its
        // billId, fetch the real bill for the tax/company data that
        // getOrderDetailById simply doesn't have.
        unawaited(_loadBillDetailsIfNeeded());
        unawaited(_loadAllBills());
      } else {
        setState(() {
          _error = resp?.message ?? 'No details found';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load order details: $e';
        _loading = false;
      });
    }
  }

  /// Fetches the real bill (company details, exact tax, exact discount)
  /// once we know this order has one. Safe to call repeatedly — no-ops if
  /// there's no billId, one is already loading, or one's already loaded.
  Future<void> _loadBillDetailsIfNeeded() async {
    final billId = _billId;
    if (!_isActuallyBilled ||
        billId == null ||
        billId.isEmpty ||
        _loadingBillDetails ||
        _billDetails != null) {
      return;
    }

    setState(() => _loadingBillDetails = true);
    try {
      final response = await ApiService.getBillDetailByBillId(billId: billId);
      if (mounted && response?.isSuccess == true && response?.data != null) {
        setState(() => _billDetails = response!.data);
      }
    } catch (e) {
      debugPrint('[OrderDetailView] Error loading bill details: $e');
    } finally {
      if (mounted) setState(() => _loadingBillDetails = false);
    }
  }

  /// Every bill raised against this order, e.g. two or more from a split
  /// bill. GetBillForReprint isn't order-scoped — it returns a day's bills
  /// for the outlet — so results are narrowed to this order's
  /// GeneratedOrderNo client-side, same as the Reprint screen's own window.
  Future<void> _loadAllBills() async {
    final orderNo = _orderNo;
    if (orderNo == null || orderNo.isEmpty || _loadingBills) return;

    final outletId = HiveService.getOutletId();
    if (outletId == null || outletId <= 0) return;

    setState(() => _loadingBills = true);
    try {
      final day = widget.order.orderTime;
      final from = DateTime(day.year, day.month, day.day);
      final to = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final bills = await ApiService.getBillsForReprint(
        outletId: outletId,
        from: from,
        to: to,
      );
      if (!mounted || bills == null) return;
      final matched = bills.where((b) => b.orderNo == orderNo).toList()
        ..sort((a, b) => (b.billDate ?? DateTime(0)).compareTo(a.billDate ?? DateTime(0)));
      setState(() => _bills = matched);
    } catch (e) {
      debugPrint('[OrderDetailView] Error loading bills: $e');
    } finally {
      if (mounted) setState(() => _loadingBills = false);
    }
  }

  /// Prints/previews one specific bill from [_bills] — always the real bill
  /// (Order/getBillDetailByBillId), never a reconstruction, same as
  /// [_viewOrDownloadBill] and the Reprint screen's own bill printing.
  Future<void> _printBill(PendingBill bill) async {
    setState(() => _printingBillId = bill.billId);
    try {
      final response = await ApiService.getBillDetailByBillId(
        billId: bill.billId,
      );
      final billData = response?.data;
      if (!mounted) return;
      if (response?.isSuccess != true || billData == null) {
        AppSnackBar.showError(context, 'Could not load this bill right now.');
        return;
      }

      String gstLabel = 'GST';
      if (billData.taxInf.isNotEmpty) {
        final totalPct = billData.taxInf.fold<double>(
          0,
          (sum, t) => sum + t.taxPercentage,
        );
        gstLabel =
            'GST (${totalPct % 1 == 0 ? totalPct.toStringAsFixed(0) : totalPct.toStringAsFixed(1)}%)';
      }
      final gstAmount =
          billData.billHeadDt.billAmountInclTax -
          billData.billHeadDt.amountAfterDisc;

      final items =
          billData.billOrderDt
              .map(
                (o) => CartItem(
                  id: o.orderId,
                  name: o.itemName,
                  price: o.itemPrice,
                  quantity: o.orderQty.round(),
                  tableId: '',
                  tableName: '',
                ),
              )
              .toList();

      final discountAmount =
          billData.billHeadDt.discountAmnt + billData.billHeadDt.specDisAmt;

      final billBytes = await PDFService.generateThermalBill(
        items: items,
        tableId: bill.orderNo,
        tableName:
            billData.orderChanelDt.isNotEmpty
                ? billData.orderChanelDt.first.channelName
                : bill.orderNo,
        orderNumber: bill.orderNo,
        orderTime: bill.billDate ?? DateTime.now(),
        subtotal: billData.billHeadDt.amountAfterDisc,
        gstAmount: gstAmount > 0 ? gstAmount : 0,
        total: billData.billHeadDt.billAmountInclTax,
        companyName: billData.companyDt.companyName,
        companyAddress: billData.companyDt.companyAddress,
        companyPhone: billData.companyDt.contactNo,
        companyGstNo: billData.companyDt.gstNo,
        gstLabel: gstLabel,
        billNo: billData.billHeadDt.billNo,
        customerName: billData.billHeadDt.customerName,
        customerPhone: billData.billHeadDt.custMobNo,
        discountAmount: discountAmount,
        payments: billData.paymentDetail,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (context) => BillPDFViewerDialog(
              pdfBytes: billBytes,
              orderNumber: bill.billNo.isNotEmpty ? bill.billNo : bill.orderNo,
              fileName: 'Bill_${bill.billNo.isNotEmpty ? bill.billNo : bill.billId}.pdf',
            ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error opening bill: $e');
      }
    } finally {
      if (mounted) setState(() => _printingBillId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadOrderDetail();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              else ...[
                _buildOrderHeader(),
                const SizedBox(height: 20),
                _buildBillingSection(),
                const SizedBox(height: 20),
                _buildBillsSection(),
                const SizedBox(height: 20),
                _buildPriceBreakdown(),
                const SizedBox(height: 20),
                _buildOrderItems(),
                const SizedBox(height: 20),
                _buildCustomerInfo(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBottomActionBar() {
    if (_loading || _error != null) {
      return const SizedBox.shrink();
    }

    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    if (!_isActuallyBilled) {
      // Not billed - go to cart to add items and generate bill
      buttonText = 'Go to Cart';
      buttonColor = AppColors.primary;
      onPressed = _navigateToCart;
    } else if (_isActuallyBilled && !_isActuallyPaid) {
      // Billed but not paid - go to payment
      buttonText = 'Go to Payment';
      buttonColor = AppColors.success;
      onPressed = _navigateToPaymentWithBillId;
    } else {
      // Paid - view/download the real bill that was already created
      buttonText = 'Download Bill';
      buttonColor = AppColors.info;
      onPressed = _viewOrDownloadBill;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Name and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.order.customerName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor().withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    // prefer API value if available
                    _fullOrderStatus ?? '',
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Order Information - Top section instead of sidebar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderInfo('Order ID', _orderNo ?? ''),
                      ),
                      Expanded(
                        child: _buildHeaderInfo(
                          'KOT Status',
                          _isKOTGenerated ? 'Generated' : 'Pending',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderInfo(
                          'Billing Status',
                          _isActuallyBilled
                              ? (_isActuallyPaid ? 'Paid' : 'Billed (Unpaid)')
                              : 'Not Billed',
                        ),
                      ),
                      if (widget.order.orderType == 'Table Orders')
                        Expanded(
                          child: _buildHeaderInfo('Table', _channelName ?? ''),
                        ),
                    ],
                  ),
                  if (widget.order.orderType == 'Table Orders') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderInfo('Waiter', _waiterName ?? ''),
                        ),
                        Expanded(
                          child: _buildHeaderInfo('KOT No', _kotNo ?? ''),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBillingSection() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Billing Information',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Status indicator based on API data
                if (!_isKOTGenerated)
                  const Text(
                    'KOT Required First',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (_isActuallyBilled && _isActuallyPaid)
                  const Text(
                    'Payment Complete',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (_isActuallyBilled && !_isActuallyPaid)
                  const Text(
                    'Awaiting Payment',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'Ready for Billing',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Billing details in a more organized way
            Column(
              children: [
                _buildInfoRow(
                  'Bill Number',
                  _isActuallyBilled
                      ? (_billNo ?? 'Generated')
                      : 'Not Generated',
                ),
                _buildInfoRow(
                  'Payment Status',
                  _isActuallyBilled
                      ? (_isActuallyPaid ? 'Paid' : 'Unpaid')
                      : 'Not Billed',
                ),
                if (_isActuallyBilled && _isActuallyPaid)
                  _buildInfoRow('Payment Mode', _paymentMode),
                _buildInfoRow('Created On', _createdOnString),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lists every bill raised against this order (more than one when it was
  /// split), each with its own print/view action. Hidden while there is
  /// nothing to show — most orders have zero or one bill, and an empty
  /// "Bills" card before the first bill exists would just be noise.
  Widget _buildBillsSection() {
    if (!_loadingBills && _bills.isEmpty) return const SizedBox.shrink();

    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _bills.length > 1 ? 'Bills (${_bills.length})' : 'Bill',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingBills)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              ..._bills.map(_buildBillRow),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(PendingBill bill) {
    final printing = _printingBillId == bill.billId;
    final tone =
        bill.isPaid == 2
            ? AppColors.success
            : bill.isPaid == 1
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textHint.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.billNo.isNotEmpty ? bill.billNo : bill.billId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bill.paymentStatus.isNotEmpty
                            ? bill.paymentStatus
                            : (bill.isPaid == 2 ? 'Paid' : 'Not Paid'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: tone,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${CurrencyConstants.symbol}${bill.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child:
                printing
                    ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : OutlinedButton.icon(
                      onPressed: () => _printBill(bill),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text(
                        'Print',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    double discount = _discount;
    bool hasDiscount = discount > 0;

    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Price Breakdown',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildPriceRow('Item Price', _subtotal),
            _buildPriceRow(_gstLabel, _gstAmount),
            _buildPriceRow('Service Charge', _serviceCharge),

            // Only show discount if it exists
            if (hasDiscount)
              _buildPriceRow('Discount', discount, isDiscount: true),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

            _buildPriceRow('Grand Total', _grandTotal, isFinal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isFinal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isFinal ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: isFinal ? 18 : 16,
                fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${CurrencyConstants.symbol}${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color:
                  isDiscount
                      ? AppColors.success
                      : isFinal
                      ? AppColors.primary
                      : AppColors.textPrimary,
              fontSize: isFinal ? 18 : 16,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Order Items',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Render items from API detail if available, otherwise fall back to existing items
            if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty)
              ...?_detailModel!.data!.first.orderDetailList?.map((d) {
                final qty = d.productQty ?? 0;
                final price = (d.itemPrice ?? 0).toDouble();
                final total = (d.totPrice ?? 0).toDouble();
                return _buildItemRow(d.productName ?? '', qty, price, total);
              })
            else
              ...widget.order.items.map(
                (item) => _buildItemRow(
                  item.productName,
                  item.quantity,
                  item.price,
                  item.quantity * item.price,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(String name, int quantity, double price, double total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textHint.withValues(alpha: 0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                '$quantity × ${CurrencyConstants.symbol}${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // Use a fixed width for price to avoid wrapping
            SizedBox(
              width: 80,
              child: Text(
                '${CurrencyConstants.symbol}${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Customer Information',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Different info based on order type
            Column(
              children: [
                _buildInfoRow('Customer Name', widget.order.customerName),

                // Phone number for all types
                if (widget.order.phoneNumber != null)
                  _buildInfoRow('Phone Number', widget.order.phoneNumber!),

                // Order type info
                _buildInfoRow('Order Type', widget.order.orderType),

                // Platform name for channel partners
                if (widget.order.platformName != null)
                  _buildInfoRow('Platform', widget.order.platformName!),

                // Instructions if any
                if (_detailModel?.data != null &&
                    _detailModel!.data!.isNotEmpty &&
                    _detailModel!.data!.first.orderDetailList != null &&
                    _detailModel!.data!.first.orderDetailList!.isNotEmpty)
                  _buildInfoRow(
                    'Instructions',
                    _detailModel!
                            .data!
                            .first
                            .orderDetailList!
                            .first
                            .instruction ??
                        '',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case OrderStatusType.pending:
        return AppColors.warning;
      case OrderStatusType.accepted:
        return AppColors.info;
      case OrderStatusType.preparing:
        return AppColors.tableCleaning;
      case OrderStatusType.ready:
        return AppColors.success;
      case OrderStatusType.delivered:
        return AppColors.tableAvailable;
      case OrderStatusType.cancelled:
        return AppColors.error;
      case OrderStatusType.completed:
        return AppColors.success;
    }
  }

  void _navigateToPaymentWithBillId() {
    if (_billId == null) {
      AppSnackBar.showError(context, AppStrings.orders.billIdNotAvailable);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentPage(
              orderId: widget.order.orderId.toString(),
              orderNumber: _orderNo ?? widget.order.orderId.toString(),
              totalAmount: _grandTotal,
              billId: _billId,
              tableId:
                  widget.order.orderType == 'Table Orders'
                      ? widget.order.tableNumber
                      : widget.order.orderType == 'Phone Orders'
                      ? 'PhoneOrder'
                      : 'Takeaway',
              onPaymentCompleted: () {
                // Refresh the order details to get updated payment status
                _loadOrderDetail();
              },
            ),
      ),
    );
  }

  void _navigateToCart() async {
    // Load order items into cart first
    await _loadOrderItemsIntoCart();
    if (!mounted) return;

    // Then navigate to cart with appropriate context
    if (widget.order.orderType == 'Table Orders') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CartView(
                tableId: widget.order.tableNumber,
                tableName: 'Table ${widget.order.tableNumber}',
                selectedLocation: 'Main Hall',
              ),
        ),
      );
    } else {
      // For phone/takeaway orders
      _navigateToPhoneTakeawayCart();
    }
  }

  Future<void> _loadOrderItemsIntoCart() async {
    try {
      // Prevent duplicate loading - only load once per order detail view session
      if (_cartLoaded) {
        debugPrint(
          '[OrderDetailView] Cart already loaded, skipping to prevent duplicates',
        );
        return;
      }

      final cartProvider = context.read<AnimatedCartProvider>();

      // Determine the cart context
      String tableId;
      String tableName;

      if (widget.order.orderType == 'Table Orders') {
        tableId = widget.order.tableNumber ?? 'Table1';
        tableName = 'Table ${widget.order.tableNumber}';
      } else if (widget.order.orderType == 'Phone Orders') {
        tableId = 'PhoneOrder';
        tableName = 'Phone Order - ${widget.order.customerName}';
      } else {
        tableId = 'Takeaway';
        tableName = 'Takeaway - ${widget.order.customerName}';
      }

      debugPrint(
        '[OrderDetailView] Loading cart for ${widget.order.orderType}: $tableName',
      );

      // CRITICAL FIX: Clear existing cart data first to prevent duplicates
      cartProvider.clearAllSessionData();

      // Switch to the appropriate cart context
      cartProvider.switchToOrder(
        widget.order.orderId.toString(),
        tableId: tableId,
        tableName: tableName,
      );

      // Prepare items for import using the proper importFromOrderCart method
      List<Map<String, dynamic>> cartItems = [];

      // Load items from API data if available, otherwise use widget data
      if (_detailModel?.data != null &&
          _detailModel!.data!.isNotEmpty &&
          _detailModel!.data!.first.orderDetailList != null) {
        // Convert API response to cart format
        for (final orderDetail in _detailModel!.data!.first.orderDetailList!) {
          final productName = orderDetail.productName ?? 'Unknown Item';
          final price = (orderDetail.itemPrice ?? 0).toDouble();
          final qtyStr = orderDetail.productQty?.toString() ?? '1';
          final quantity = double.tryParse(qtyStr)?.toInt() ?? 1;
          final productId =
              orderDetail.productId ?? orderDetail.orderDetailId ?? '';
          final instruction = orderDetail.instruction;
          final kotNo = orderDetail.kotNo;

          // Create cart item data
          final cartItem = {
            'productId': productId,
            'productName': productName,
            'itemPrice': price,
            'price': price,
            'productQty': quantity,
            'quantity': quantity,
            'instruction': instruction,
            'specialNotes': instruction,
            'isKotGenerated': kotNo?.isNotEmpty == true,
            'kotNo': kotNo,
            'kotNumber': kotNo,
          };

          cartItems.add(cartItem);
        }
      } else {
        // Fallback to widget order items if API data not available
        for (final item in widget.order.items) {
          final cartItem = {
            'productId': item.productName, // Use productName as ID for now
            'productName': item.productName,
            'price': item.price,
            'quantity': item.quantity,
            'isKotGenerated': false,
          };
          cartItems.add(cartItem);
        }
      }

      // Use importFromOrderCart to properly load items (this clears existing and replaces)
      cartProvider.importFromOrderCart(
        cartItems,
        orderId: widget.order.orderId.toString(),
        tableId: tableId,
        tableName: tableName,
        clearExisting: true, // This ensures no duplicates
      );

      // Mark cart as loaded to prevent duplicate loading
      _cartLoaded = true;
      debugPrint(
        '[OrderDetailView] Cart loaded with ${cartItems.length} items',
      );

      // Show success message
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Order items loaded to cart (${cartItems.length} items)',
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      debugPrint('[OrderDetailView] Error loading items into cart: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Error loading order items: $e');
      }
    }
  }

  void _navigateToPhoneTakeawayCart() {
    // Navigate to cart with the order type context
    String tableId =
        widget.order.orderType == 'Phone Orders' ? 'PhoneOrder' : 'Takeaway';
    String tableName =
        widget.order.orderType == 'Phone Orders'
            ? 'Phone Order - ${widget.order.customerName}'
            : 'Takeaway - ${widget.order.customerName}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CartView(
              tableId: tableId,
              tableName: tableName,
              selectedLocation: null,
            ),
      ),
    );
  }

  /// Shows the real bill as a PDF the user can view, print, or save —
  /// covers "I forgot to download it at the counter". Built from the
  /// actual bill (Order/getBillDetailByBillId), never a reconstruction
  /// from local order data, so the company header, tax and totals always
  /// match exactly what was charged. Doesn't touch CartView or any
  /// KOT-related check — this order is already billed, there is nothing
  /// left to gate on.
  Future<void> _viewOrDownloadBill() async {
    if (_billId == null || _billId!.isEmpty) {
      AppSnackBar.showError(context, AppStrings.orders.billIdNotAvailable);
      return;
    }

    if (_billDetails == null) {
      await _loadBillDetailsIfNeeded();
    }
    if (!mounted) return;

    final billData = _billDetails;
    if (billData == null) {
      AppSnackBar.showError(
        context,
        'Could not load this bill right now. Please try again.',
      );
      return;
    }

    try {
      final billBytes = await PDFService.generateThermalBill(
        items: widget.order.items,
        tableId: widget.order.tableNumber ?? '1',
        tableName:
            widget.order.tableNumber != null
                ? 'Table ${widget.order.tableNumber}'
                : 'Table 1',
        orderNumber: widget.order.orderId.toString(),
        orderTime: widget.order.orderTime,
        subtotal: _subtotal,
        gstAmount: _gstAmount,
        total: _grandTotal,
        specialNotes: _instructions,
        companyName: billData.companyDt.companyName,
        companyAddress: billData.companyDt.companyAddress,
        companyPhone: billData.companyDt.contactNo,
        companyGstNo: billData.companyDt.gstNo,
        gstLabel: _gstLabel,
        billNo: _billNo,
        customerName: billData.billHeadDt.customerName,
        customerPhone: billData.billHeadDt.custMobNo,
        discountAmount: _discount,
        payments: billData.paymentDetail,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (context) => BillPDFViewerDialog(
              pdfBytes: billBytes,
              orderNumber: _billNo ?? widget.order.orderId.toString(),
              fileName: 'Bill_${_billNo ?? widget.order.orderId}.pdf',
            ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error opening bill: $e');
      }
    }
  }
}
