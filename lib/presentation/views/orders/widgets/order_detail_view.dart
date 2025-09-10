import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/presentation/views/billing/billing_page.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../data/models/order_management_model.dart';
import '../billing/billing_page.dart';

class OrderDetailView extends StatefulWidget {
  final OrderItem order;

  const OrderDetailView({super.key, required this.order});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _progressTimer;
  
  bool _isBilled = false;
  bool _isKOTGenerated = true;
  String _paymentMode = 'Cash';
  String _billNumber = 'BILL001234';

  @override
  void initState() {
    super.initState();
    _setupProgressAnimation();
    _startProgressSimulation();
    
    // Set billing status based on order status
    _isBilled = widget.order.status == OrderStatusType.completed ||
               widget.order.status == OrderStatusType.delivered;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _setupProgressAnimation() {
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _getProgressValue(),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward();
  }

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && widget.order.status == OrderStatusType.preparing) {
        setState(() {
          // Simulate progress updates
        });
      }
    });
  }

  double _getProgressValue() {
    switch (widget.order.status) {
      case OrderStatusType.pending:
        return 0.1;
      case OrderStatusType.accepted:
        return 0.3;
      case OrderStatusType.preparing:
        return 0.6;
      case OrderStatusType.ready:
        return 0.9;
      case OrderStatusType.delivered:
      case OrderStatusType.completed:
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order #${widget.order.orderId}',
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Status Sidebar
          _buildStatusSidebar(),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(),
                  const SizedBox(height: 20),
                  _buildAnimatedProgress(),
                  const SizedBox(height: 20),
                  _buildBillingSection(),
                  const SizedBox(height: 20),
                  _buildPriceBreakdown(),
                  const SizedBox(height: 20),
                  _buildOrderItems(),
                  const SizedBox(height: 20),
                  _buildCustomerInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSidebar() {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Status',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Order Status
            _buildStatusBadge(
              'Order',
              widget.order.statusDisplayText,
              _getStatusColor(),
            ),
            const SizedBox(height: 12),
            
            // KOT Status
            _buildStatusBadge(
              'KOT',
              _isKOTGenerated ? 'Generated' : 'Pending',
              _isKOTGenerated ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: 12),
            
            // Billing Status
            GestureDetector(
              onTap: _isBilled ? null : () => _navigateToBilling(context),
              child: _buildStatusBadge(
                'Billing',
                _isBilled ? 'Paid' : 'Unpaid',
                _isBilled ? AppColors.success : AppColors.error,
              ),
            ),
            
            if (_isBilled) ...[
              const SizedBox(height: 12),
              _buildStatusBadge(
                'Payment',
                _paymentMode,
                AppColors.info,
              ),
            ],
            
            const Spacer(),
            
            // Table Info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.table_restaurant,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.order.tableNumber != null 
                        ? 'Table ${widget.order.tableNumber}'
                        : 'No Table',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, String status, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.customerName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Order Number', '#${widget.order.orderId}'),
                      _buildInfoRow('Bill Number', _isBilled ? _billNumber : 'Not Generated'),
                      _buildInfoRow('Table', widget.order.tableNumber != null 
                          ? 'Table ${widget.order.tableNumber}' 
                          : 'No Table'),
                      _buildInfoRow('Waiter', widget.order.waiterName ?? 'System'),
                      _buildInfoRow('Order Time', _formatDateTime(widget.order.orderTime)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.order.statusDisplayText,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedProgress() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Progress',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Animated Progress Bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: AppColors.textHint.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progressAnimation.value * 100).toInt()}% Complete',
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Progress Steps
            _buildProgressStep('Order Received', true, AppColors.success),
            _buildProgressStep('Order Accepted', 
                widget.order.status.index >= OrderStatusType.accepted.index, 
                AppColors.info),
            _buildProgressStep('Food Preparing', 
                widget.order.status.index >= OrderStatusType.preparing.index, 
                AppColors.warning),
            _buildProgressStep('Ready to Serve', 
                widget.order.status.index >= OrderStatusType.ready.index, 
                AppColors.success),
            _buildProgressStep('Completed', 
                widget.order.status == OrderStatusType.completed, 
                AppColors.success, isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isCompleted, Color color, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 10)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isCompleted && !isLast) ...[
            const Spacer(),
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingSection() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Billing Information',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isBilled)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToBilling(context),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Generate Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInfoRow('Bill Status', _isBilled ? 'Generated' : 'Pending')),
                Expanded(child: _buildInfoRow('Payment Status', _isBilled ? 'Paid' : 'Unpaid')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildInfoRow('Payment Mode', _isBilled ? _paymentMode : 'Not Selected')),
                Expanded(child: _buildInfoRow('KOT Generated', _isKOTGenerated ? 'Yes' : 'No')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    // Calculate breakdown
    double itemTotal = widget.order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    double gstRate = 0.05; // 5% GST
    double gstAmount = itemTotal * gstRate;
    double discount = 25.0; // Static discount
    double finalTotal = itemTotal + gstAmount - discount;

    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Price Breakdown',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Item Total', itemTotal),
            _buildPriceRow('GST (5%)', gstAmount),
            _buildPriceRow('Service Charge', 20.0),
            _buildPriceRow('Discount', -discount, isDiscount: true),
            const Divider(),
            _buildPriceRow('Grand Total', finalTotal, isFinal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isFinal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isFinal ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: isFinal ? 16 : 14,
                fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isDiscount 
                  ? AppColors.success 
                  : isFinal 
                      ? AppColors.primary 
                      : AppColors.textPrimary,
              fontSize: isFinal ? 16 : 14,
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
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Items',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.quantity} × ₹${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(item.quantity * item.price).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+ 5% GST',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Customer Name', widget.order.customerName),
            if (widget.order.phoneNumber != null)
              _buildInfoRow('Phone Number', widget.order.phoneNumber!),
            _buildInfoRow('Order Type', widget.order.orderType),
            if (widget.order.platformName != null)
              _buildInfoRow('Platform', widget.order.platformName!),
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
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(color: AppColors.textSecondary)),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToBilling(BuildContext context) {
    Navigator.push(
      context,
      // MaterialPageRoute(
      //   builder: (context) => BillingPage(order: widget.order),
      // ),
    ).then((result) {
      if (result == true) {
        setState(() {
          _isBilled = true;
          _paymentMode = 'Cash'; // Or get from billing page
        });
      }
    });
  }
}
