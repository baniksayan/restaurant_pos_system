import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/date_time_formatter.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/bill_details_response.dart';
import 'package:restaurant_pos_system/data/models/order_detail_api_response_model.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/features/billing/widgets/bill_pdf_viewer_dialog.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/views/cart_view.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import 'package:restaurant_pos_system/shared/services/pdf_service.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import '../models/order_management_model.dart';

class OrderDetailView extends StatefulWidget {
  final OrderItem order;

  const OrderDetailView({super.key, required this.order});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView>
    with SingleTickerProviderStateMixin {
  // API-backed state
  bool _loading = true;
  String? _error;
  OrderDetailApiResponseModel? _detailModel;

  bool _isBilled = false;
  bool _isKOTGenerated = true;
  final String _paymentMode = 'Cash';

  // Track if cart has been loaded to prevent duplicates
  bool _cartLoaded = false;

  // Real bill data for accurate tax, discount, company header
  BillDetailsData? _billDetails;
  bool _loadingBillDetails = false;

  // Associated bills (for split bills)
  List<PendingBill> _bills = [];
  bool _loadingBills = false;
  String? _printingBillId;

  // Shimmer skeleton animation
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  // Derived financial values
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

  double get _gstAmount {
    if (_billDetails == null) return 0.0;
    final gst =
        _billDetails!.billHeadDt.billAmountInclTax -
        _billDetails!.billHeadDt.amountAfterDisc;
    return gst > 0 ? gst : 0.0;
  }

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

  double get _serviceCharge => 0.0;

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
    return DateTimeFormatter.formatDateTime(widget.order.orderTime);
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
    _isKOTGenerated =
        widget.order.status.index >= OrderStatusType.accepted.index;

    // Multi-stop shimmer skeleton animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    // Initial load
    _loadOrderDetail();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
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
      final matched =
          bills.where((b) => b.orderNo == orderNo).toList()
            ..sort(
              (a, b) => (b.billDate ?? DateTime(0)).compareTo(
                a.billDate ?? DateTime(0),
              ),
            );
      setState(() => _bills = matched);
    } catch (e) {
      debugPrint('[OrderDetailView] Error loading bills: $e');
    } finally {
      if (mounted) setState(() => _loadingBills = false);
    }
  }

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
              fileName:
                  'Bill_${bill.billNo.isNotEmpty ? bill.billNo : bill.billId}.pdf',
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

  // ────────────────────────────────────────────────────────────────────────────
  // Build Method
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // Top App Bar
            _buildTopHeader(context),

            // Content Area with Pull-to-Refresh
            Expanded(
              child: PremiumRefreshIndicator(
                onRefresh: _loadOrderDetail,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child:
                      _loading
                          ? _buildSkeletonLoading()
                          : _error != null
                          ? _buildErrorState()
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hero Overview Card
                              _buildHeroOverviewCard(),
                              const SizedBox(height: 14),

                              // Billing Status Card
                              _buildBillingStatusCard(),
                              const SizedBox(height: 14),

                              // Split / Multiple Bills Card (if available)
                              if (_bills.isNotEmpty || _loadingBills) ...[
                                _buildBillsCard(),
                                const SizedBox(height: 14),
                              ],

                              // Order Items List Card
                              _buildOrderItemsCard(),
                              const SizedBox(height: 14),

                              // Price Breakdown Card
                              _buildPriceBreakdownCard(),

                              // Special Kitchen Instructions (if present)
                              if (_instructions != null &&
                                  _instructions!.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _buildInstructionsCard(),
                              ],
                            ],
                          ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionBar(),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Top App Bar (WhizEats Pro Unified Design)
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildTopHeader(BuildContext context) {
    final String channelLabel =
        widget.order.orderType == 'Table Orders'
            ? (widget.order.tableNumber != null &&
                    widget.order.tableNumber!.isNotEmpty
                ? 'Table ${widget.order.tableNumber}'
                : 'Dine-In')
            : (widget.order.orderType == 'Phone Orders'
                ? 'Phone Order'
                : 'Takeaway');

    final IconData channelIcon =
        widget.order.orderType == 'Table Orders'
            ? Icons.table_restaurant_rounded
            : (widget.order.orderType == 'Phone Orders'
                ? Icons.phone_in_talk_rounded
                : Icons.shopping_bag_rounded);

    final String displayOrderNum =
        _orderNo ?? widget.order.orderId;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                tooltip: 'Back',
              ),
            ),
            const SizedBox(width: 12),

            // Title & Context Subtitle Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Order #$displayOrderNum · $channelLabel',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Channel Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(channelIcon, size: 13, color: AppColors.primaryDark),
                  const SizedBox(width: 4),
                  Text(
                    channelLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Card 1: Hero Overview Card
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildHeroOverviewCard() {
    final statusColor = _getStatusColor();
    final statusText = _fullOrderStatus ?? _formatStatus(widget.order.status);
    final String customerName =
        widget.order.customerName.trim().isNotEmpty
            ? widget.order.customerName.trim()
            : 'Guest Customer';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier 1: Customer Header & Semantic Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.order.phoneNumber != null &&
                        widget.order.phoneNumber!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.order.phoneNumber!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill with Glowing Dot
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Tier 2: 2-Column Metadata Badges Grid
          Row(
            children: [
              Expanded(
                child: _buildMetaBadge(
                  icon: Icons.receipt_outlined,
                  label: 'ORDER NO',
                  value: _orderNo ?? widget.order.orderId,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetaBadge(
                  icon: Icons.soup_kitchen_outlined,
                  label: 'KOT NO',
                  value: _kotNo ?? (_isKOTGenerated ? 'Generated' : 'Pending'),
                  highlight: _kotNo != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetaBadge(
                  icon: Icons.schedule_rounded,
                  label: 'PLACED AT',
                  value: DateTimeFormatter.formatDateTime(
                    widget.order.orderTime,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetaBadge(
                  icon: Icons.badge_outlined,
                  label: 'WAITER / STAFF',
                  value: _waiterName ?? 'Counter Staff',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetaBadge(
                  icon: Icons.table_bar_outlined,
                  label: 'CHANNEL / TABLE',
                  value: _channelName ??
                      (widget.order.tableNumber != null &&
                              widget.order.tableNumber!.isNotEmpty
                          ? 'Table ${widget.order.tableNumber}'
                          : widget.order.orderType),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Card 2: Billing & Settlement Status Card
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildBillingStatusCard() {
    final bool isPaid = _isActuallyBilled && _isActuallyPaid;
    final bool isUnpaidBill = _isActuallyBilled && !_isActuallyPaid;

    final Color statusTone =
        isPaid
            ? const Color(0xFF10B981)
            : isUnpaidBill
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    final String statusBadgeText =
        isPaid
            ? 'PAID · TRANSACTION SETTLED'
            : isUnpaidBill
            ? 'BILLED · PAYMENT PENDING'
            : 'NOT BILLED · BILL GENERATION PENDING';

    final IconData statusIcon =
        isPaid
            ? Icons.check_circle_outline_rounded
            : isUnpaidBill
            ? Icons.pending_actions_rounded
            : Icons.receipt_long_outlined;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          _buildCardHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Billing & Payment',
          ),
          const SizedBox(height: 14),

          // Status Banner Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: statusTone.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusTone.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 16, color: statusTone),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusBadgeText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: statusTone,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Key Value List
          _buildInfoRow(
            'Bill Number',
            _isActuallyBilled
                ? (_billNo ?? 'Generated')
                : 'Not Generated Yet',
            isHighlighted: _isActuallyBilled,
          ),
          _buildInfoRow(
            'Payment Mode',
            isPaid ? _paymentMode : (isUnpaidBill ? 'Pending' : 'N/A'),
          ),
          _buildInfoRow('Billing Date', _createdOnString),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Card 3: Associated / Split Bills Section
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildBillsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.folder_copy_rounded,
            title:
                _bills.length > 1
                    ? 'Generated Bills (${_bills.length})'
                    : 'Generated Bill',
          ),
          const SizedBox(height: 14),

          if (_loadingBills)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            ..._bills.map(_buildSplitBillRow),
        ],
      ),
    );
  }

  Widget _buildSplitBillRow(PendingBill bill) {
    final isPrinting = _printingBillId == bill.billId;
    final tone =
        bill.isPaid == 2
            ? const Color(0xFF10B981)
            : bill.isPaid == 1
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bill.paymentStatus.isNotEmpty
                            ? bill.paymentStatus.toUpperCase()
                            : (bill.isPaid == 2 ? 'PAID' : 'UNPAID'),
                        style: TextStyle(
                          fontSize: 9.5,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child:
                isPrinting
                    ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                    : OutlinedButton.icon(
                      onPressed: () => _printBill(bill),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.print_outlined, size: 14),
                      label: const Text(
                        'Print',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Card 4: Order Items List Card
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildOrderItemsCard() {
    final List<Widget> itemWidgets = [];

    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      final list = _detailModel!.data!.first.orderDetailList;
      if (list != null && list.isNotEmpty) {
        for (final d in list) {
          final qty = d.productQty ?? 0;
          final price = (d.itemPrice ?? 0).toDouble();
          final total = (d.totPrice ?? 0).toDouble();
          itemWidgets.add(
            _buildItemRow(
              name: d.productName ?? 'Item',
              quantity: qty.toInt(),
              price: price,
              total: total,
              instruction: d.instruction,
            ),
          );
        }
      }
    }

    if (itemWidgets.isEmpty) {
      for (final item in widget.order.items) {
        itemWidgets.add(
          _buildItemRow(
            name: item.productName,
            quantity: item.quantity,
            price: item.price,
            total: item.quantity * item.price,
          ),
        );
      }
    }

    final itemCount =
        _detailModel?.data?.first.orderDetailList?.length ??
        widget.order.items.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardHeader(
                icon: Icons.restaurant_menu_rounded,
                title: 'Order Items',
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Items List
          ...itemWidgets,
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required String name,
    required int quantity,
    required double price,
    required double total,
    String? instruction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Qty Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${quantity}x',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyConstants.symbol}${price.toStringAsFixed(2)} each',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Total Price
              Text(
                '${CurrencyConstants.symbol}${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Optional Note / Instruction
          if (instruction != null && instruction.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 13,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      instruction.trim(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Card 5: Price Breakdown Card
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildPriceBreakdownCard() {
    final double discount = _discount;
    final bool hasDiscount = discount > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.calculate_rounded,
            title: 'Price Breakdown',
          ),
          const SizedBox(height: 14),

          _buildPriceRow('Item Subtotal', _subtotal),
          _buildPriceRow(_gstLabel, _gstAmount),
          if (_serviceCharge > 0)
            _buildPriceRow('Service Charge', _serviceCharge),
          if (hasDiscount)
            _buildPriceRow('Discount Applied', discount, isDiscount: true),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          _buildPriceRow('Grand Total', _grandTotal, isFinal: true),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isFinal ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: isFinal ? 15 : 13.5,
              fontWeight: isFinal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${CurrencyConstants.symbol}${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color:
                  isDiscount
                      ? const Color(0xFF10B981)
                      : isFinal
                      ? AppColors.primary
                      : AppColors.textPrimary,
              fontSize: isFinal ? 17.5 : 13.5,
              fontWeight: isFinal ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Card 6: Kitchen Instructions Card (if present)
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.speaker_notes_outlined,
                size: 18,
                color: Color(0xFFD97706),
              ),
              SizedBox(width: 8),
              Text(
                'Kitchen Remarks & Instructions',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _instructions!.trim(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF78350F),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Sticky Bottom Action Bar
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildBottomActionBar() {
    if (_loading || _error != null) {
      return const SizedBox.shrink();
    }

    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    VoidCallback? onPressed;

    if (!_isActuallyBilled) {
      buttonText = 'Go to Cart & Bill';
      buttonIcon = Icons.shopping_cart_checkout_rounded;
      buttonColor = AppColors.primary;
      onPressed = _navigateToCart;
    } else if (_isActuallyBilled && !_isActuallyPaid) {
      buttonText =
          'Proceed to Payment · ${CurrencyConstants.symbol}${_grandTotal.toStringAsFixed(2)}';
      buttonIcon = Icons.payments_rounded;
      buttonColor = const Color(0xFF10B981);
      onPressed = _navigateToPaymentWithBillId;
    } else {
      buttonText = 'View / Print Bill';
      buttonIcon = Icons.receipt_long_rounded;
      buttonColor = AppColors.primary;
      onPressed = _viewOrDownloadBill;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(buttonIcon, size: 18),
            label: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Skeleton Loader & Helper Widgets
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildSkeletonLoading() {
    return Column(
      children: [
        _buildHeroSkeletonCard(),
        const SizedBox(height: 14),
        _buildBillingSkeletonCard(),
        const SizedBox(height: 14),
        _buildItemsSkeletonCard(),
        const SizedBox(height: 14),
        _buildSummarySkeletonCard(),
      ],
    );
  }

  Widget _buildHeroSkeletonCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBone(width: 44, height: 44, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBone(width: 120, height: 16),
                    const SizedBox(height: 6),
                    _buildShimmerBone(width: 80, height: 12),
                  ],
                ),
              ),
              _buildShimmerBone(width: 90, height: 26, radius: 20),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBone(width: 60, height: 10),
                    const SizedBox(height: 6),
                    _buildShimmerBone(width: 100, height: 14),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBone(width: 60, height: 10),
                    const SizedBox(height: 6),
                    _buildShimmerBone(width: 80, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSkeletonCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBone(width: double.infinity, height: 38, radius: 10),
          const SizedBox(height: 12),
          _buildShimmerBone(width: 150, height: 14),
        ],
      ),
    );
  }

  Widget _buildItemsSkeletonCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBone(width: 100, height: 16),
              _buildShimmerBone(width: 50, height: 14),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                _buildShimmerBone(width: 24, height: 24, radius: 6),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBone(width: 140, height: 14),
                      const SizedBox(height: 4),
                      _buildShimmerBone(width: 70, height: 11),
                    ],
                  ),
                ),
                _buildShimmerBone(width: 50, height: 14),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySkeletonCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBone(width: 120, height: 16),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBone(width: 80, height: 13),
              _buildShimmerBone(width: 60, height: 13),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBone(width: 70, height: 13),
              _buildShimmerBone(width: 50, height: 13),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBone(width: 90, height: 18),
              _buildShimmerBone(width: 80, height: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBone({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to Load Order Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? 'An unexpected error occurred.',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadOrderDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  isHighlighted ? AppColors.primary : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case OrderStatusType.pending:
        return const Color(0xFFF59E0B);
      case OrderStatusType.accepted:
        return const Color(0xFF3B82F6);
      case OrderStatusType.preparing:
        return const Color(0xFF8B5CF6);
      case OrderStatusType.ready:
        return const Color(0xFF10B981);
      case OrderStatusType.delivered:
        return const Color(0xFF059669);
      case OrderStatusType.cancelled:
        return const Color(0xFFEF4444);
      case OrderStatusType.completed:
        return const Color(0xFF10B981);
    }
  }

  String _formatStatus(OrderStatusType status) {
    switch (status) {
      case OrderStatusType.pending:
        return 'Pending';
      case OrderStatusType.accepted:
        return 'Accepted';
      case OrderStatusType.preparing:
        return 'Preparing';
      case OrderStatusType.ready:
        return 'Ready';
      case OrderStatusType.delivered:
        return 'Delivered';
      case OrderStatusType.cancelled:
        return 'Cancelled';
      case OrderStatusType.completed:
        return 'Completed';
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Navigation & Business Logic
  // ────────────────────────────────────────────────────────────────────────────

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
                _loadOrderDetail();
              },
            ),
      ),
    );
  }

  void _navigateToCart() async {
    await _loadOrderItemsIntoCart();
    if (!mounted) return;

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
      _navigateToPhoneTakeawayCart();
    }
  }

  Future<void> _loadOrderItemsIntoCart() async {
    try {
      if (_cartLoaded) {
        debugPrint(
          '[OrderDetailView] Cart already loaded, skipping duplicate load',
        );
        return;
      }

      final cartProvider = context.read<AnimatedCartProvider>();

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

      cartProvider.clearAllSessionData();

      cartProvider.switchToOrder(
        widget.order.orderId.toString(),
        tableId: tableId,
        tableName: tableName,
      );

      List<Map<String, dynamic>> cartItems = [];

      if (_detailModel?.data != null &&
          _detailModel!.data!.isNotEmpty &&
          _detailModel!.data!.first.orderDetailList != null) {
        for (final orderDetail in _detailModel!.data!.first.orderDetailList!) {
          final productName = orderDetail.productName ?? 'Unknown Item';
          final price = (orderDetail.itemPrice ?? 0).toDouble();
          final qtyStr = orderDetail.productQty?.toString() ?? '1';
          final quantity = double.tryParse(qtyStr)?.toInt() ?? 1;
          final productId =
              orderDetail.productId ?? orderDetail.orderDetailId ?? '';
          final instruction = orderDetail.instruction;
          final kotNo = orderDetail.kotNo;

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
        for (final item in widget.order.items) {
          final cartItem = {
            'productId': item.productName,
            'productName': item.productName,
            'price': item.price,
            'quantity': item.quantity,
            'isKotGenerated': false,
          };
          cartItems.add(cartItem);
        }
      }

      cartProvider.importFromOrderCart(
        cartItems,
        orderId: widget.order.orderId.toString(),
        tableId: tableId,
        tableName: tableName,
        clearExisting: true,
      );

      _cartLoaded = true;

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
