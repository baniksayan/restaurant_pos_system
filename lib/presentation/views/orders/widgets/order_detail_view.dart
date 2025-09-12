import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/presentation/views/payment/payment_page.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../data/models/order_management_model.dart';
import '../../../../services/pdf_service.dart';
import '../../../../services/api_service.dart';
import '../../../../data/local/hive_service.dart';
import '../../../../data/models/order_detail_api_response_model.dart';

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
  String _paymentMode = 'Cash';

  // Derived values computed from API response (fallback to widget.order where appropriate)
  double get _subtotal {
    if (_detailModel?.data != null && _detailModel!.data!.isNotEmpty) {
      final list = _detailModel!.data!.first.orderDetailList ?? [];
      double s = 0.0;
      for (final d in list) {
        s += (d.totPrice ?? 0).toDouble();
      }
      return s;
    }
    return widget.order.totalAmount;
  }

  double get _gstAmount =>
      0.0; // backend not providing GST field in this endpoint
  double get _serviceCharge => 0.0; // backend not providing
  double get _discount => 0.0;
  double get _grandTotal => _subtotal + _gstAmount + _serviceCharge - _discount;

  String get _createdOnString {
    final d = _detailModel?.data?.first.orderDetailList?.first.createdOn;
    if (d != null && d.isNotEmpty) return d;
    return widget.order.orderTime.toString();
  }

  String? get _kotNo => _detailModel?.data?.first.orderDetailList?.first.kotNo;
  String? get _orderNo => _detailModel?.data?.first.orderNo;
  String? get _channelName => _detailModel?.data?.first.channelName;
  String? get _waiterName => _detailModel?.data?.first.waiterName;
  String? get _fullOrderStatus => _detailModel?.data?.first.fullOrderStatus;
  String? get _instructions {
    final list = _detailModel?.data?.first.orderDetailList;
    if (list != null && list.isNotEmpty) return list.first.instruction ?? '';
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
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.4),
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
                color: AppColors.primary.withOpacity(0.1),
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
                          (_detailModel?.data?.first.isBilled == true ||
                                  _isBilled)
                              ? 'Paid'
                              : 'Unpaid',
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
                    color: AppColors.primary.withOpacity(0.1),
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

                // Conditional buttons based on status
                if (!_isKOTGenerated)
                  const Text(
                    'KOT Required First',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (_isKOTGenerated && !_isBilled)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToPayment(context),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Go to Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else if (_isBilled)
                  ElevatedButton.icon(
                    onPressed: () => _regenerateBill(context),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Regenerate Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                  _isBilled ? 'BILL001234' : 'Not Generated',
                ),
                _buildInfoRow('Payment Status', _isBilled ? 'Paid' : 'Unpaid'),
                if (_isBilled) _buildInfoRow('Payment Mode', _paymentMode),
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
                    color: AppColors.primary.withOpacity(0.1),
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
          _buildPriceRow('GST (8%)', _gstAmount),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                final qtyStr = d.productQty?.toString() ?? '0';
                final qty = int.tryParse(qtyStr) ?? 0;
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
        border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
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
                    color: AppColors.primary.withOpacity(0.1),
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
                if ((_detailModel?.data?.first.orderDetailList != null &&
                    _detailModel!.data!.first.orderDetailList!.isNotEmpty))
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

  void _navigateToPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PaymentPage(
              orderNumber: widget.order.orderId.toString(),
              totalAmount: widget.order.totalAmount,
              onPaymentCompleted: () {
                setState(() {
                  _isBilled = true;
                  _paymentMode = 'Cash'; // This should come from payment page
                });
              },
            ),
      ),
    );
  }

  void _regenerateBill(BuildContext context) async {
    try {
      // Generate bill using PDFService
      await PDFService.generateCustomerBill(
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
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill regenerated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error regenerating bill: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
