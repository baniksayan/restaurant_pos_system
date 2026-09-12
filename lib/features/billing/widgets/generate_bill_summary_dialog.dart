import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import '../providers/billing_provider.dart';
import '../providers/tax_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'bill_pdf_viewer_dialog.dart';
import 'bill_success_dialog.dart';
import 'split_bill_picker.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/shared/widgets/forms/custom_text_field.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/models/order_detail_api_response_model.dart';

class GenerateBillSummaryDialog extends StatefulWidget {
  final String orderNumber;
  final List<CartItem> cartItems;
  final VoidCallback onBillGenerated;
  final String? tableId;
  final String? orderId;

  const GenerateBillSummaryDialog({
    super.key,
    required this.orderNumber,
    required this.cartItems,
    required this.onBillGenerated,
    this.tableId,
    this.orderId,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderNumber,
    required List<CartItem> cartItems,
    required VoidCallback onBillGenerated,
    String? tableId,
    String? orderId,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Generate Bill Summary',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return GenerateBillSummaryDialog(
          orderNumber: orderNumber,
          cartItems: cartItems,
          onBillGenerated: onBillGenerated,
          tableId: tableId,
          orderId: orderId,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GenerateBillSummaryDialog> createState() =>
      _GenerateBillSummaryDialogState();
}

class _GenerateBillSummaryDialogState extends State<GenerateBillSummaryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  // Split-bill state. Only usable when widget.orderId is a real, saved
  // order — the item-level ids it needs only exist on the server.
  bool _splitMode = false;
  bool _loadingSplitItems = false;
  List<OrderDetailList> _unbilledItems = [];
  Set<String> _selectedIds = {};

  /// Whether the unbilled-item list has actually come back from the server.
  /// Distinguishes "nothing left to bill" from "not asked yet" — without it
  /// an empty list looks the same as a pending load.
  bool _unbilledLoaded = false;

  /// Every item on this order is already billed, so there is nothing to bill
  /// again. Reached by reopening the bill screen after a split has covered
  /// everything.
  bool get _nothingLeftToBill =>
      _canSplit && _unbilledLoaded && _unbilledItems.isEmpty;

  bool get _canSplit => widget.orderId != null && widget.orderId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final billingProvider = context.read<BillingProvider>();
      billingProvider.loadPaymentModes();

      // Tax rates are normally fetched at login, but that can fail or expire.
      // Without them TaxProvider reports 0%, and the bill would preview an
      // untaxed total while the server charges a taxed one — the customer
      // sees one figure and is asked for another at payment.
      final taxProvider = context.read<TaxProvider>();
      if (!taxProvider.hasTaxData) {
        taxProvider.initializeTaxData();
      }

      // Load what is actually still unbilled straight away, not only when the
      // split toggle is flipped. The local cart still holds items from earlier
      // bills on this order, so basing the total on it would show — and print —
      // an amount that does not match what createBill will charge.
      if (_canSplit) {
        _loadUnbilledItems();
      }

      final navProvider = context.read<NavigationProvider>();
      if (navProvider.customerPhone?.isNotEmpty == true) {
        _phoneController.text = navProvider.customerPhone!;
        billingProvider.setCustomerPhone(navProvider.customerPhone!);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _toggleSplitMode(bool value) async {
    setState(() => _splitMode = value);
    if (value && !_unbilledLoaded && !_loadingSplitItems) {
      await _loadUnbilledItems();
    }
  }

  Future<void> _loadUnbilledItems() async {
    if (!_canSplit) return;
    setState(() => _loadingSplitItems = true);
    try {
      final response = await ApiService.getOrderDetailById(
        orderId: widget.orderId!,
      );
      final order =
          (response?.isSuccess == true && (response?.data?.isNotEmpty ?? false))
              ? response!.data!.first
              : null;
      final unbilled =
          (order?.orderDetailList ?? [])
              .where((i) => (i.generatedBillNo ?? '').isEmpty)
              .toList();
      if (mounted) {
        setState(() {
          _unbilledLoaded = true;
          _unbilledItems = unbilled;
          // Default to everything selected — a cashier who never touches
          // the picker gets the same result as billing the whole order.
          _selectedIds = unbilled.map((i) => i.orderDetailId ?? '').toSet();
        });
      }
    } catch (e) {
      debugPrint('GenerateBillSummaryDialog - Error loading split items: $e');
    } finally {
      if (mounted) setState(() => _loadingSplitItems = false);
    }
  }

  void _toggleItem(String orderDetailId) {
    setState(() {
      if (_selectedIds.contains(orderDetailId)) {
        _selectedIds.remove(orderDetailId);
      } else {
        _selectedIds.add(orderDetailId);
      }
    });
  }

  /// The items this specific bill actually covers.
  ///
  /// Always the order's *unbilled* items once the server has told us what
  /// those are — narrowed to the cashier's selection when `_splitMode` is on.
  /// It deliberately does not use the local cart when a saved order exists:
  /// the cart still contains items covered by earlier bills on the same
  /// order, and createBill only ever bills what is still unbilled, so showing
  /// the cart would price the bill differently from what is charged.
  ///
  /// Everything downstream — totals, the printed preview, the PDF and the
  /// createBill call — is driven from this one list so they cannot disagree.
  List<CartItem> _effectiveCartItems(BuildContext context) {
    // No saved order (or the list has not arrived yet): the local cart is all
    // we have, and for a brand-new order it is also correct.
    if (!_canSplit || !_unbilledLoaded) {
      return widget.cartItems;
    }

    final navProvider = context.read<NavigationProvider>();
    final tableName =
        widget.tableId != null
            ? (navProvider.selectedTableName ?? 'Table ${widget.tableId}')
            : (navProvider.selectedOrderType ?? 'Takeaway / Phone');

    // Split mode bills the ticked subset; otherwise everything unbilled.
    final source =
        _splitMode
            ? _unbilledItems.where(
              (i) => _selectedIds.contains(i.orderDetailId),
            )
            : _unbilledItems;

    return source
        .map(
          (i) => CartItem(
            id: i.productId ?? i.orderDetailId ?? '',
            name: i.productName ?? 'Item',
            price: (i.itemPrice ?? 0).toDouble(),
            quantity: i.productQty ?? 1,
            tableId: widget.tableId ?? '',
            tableName: tableName,
            specialNotes: i.instruction,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Consumer2<BillingProvider, TaxProvider>(
      builder: (context, billingProvider, taxProvider, child) {
        final effectiveCartItems = _effectiveCartItems(context);
        final subtotal = billingProvider.calculateSubtotal(
          effectiveCartItems,
        );
        // Live rate, same source the cart footer uses. Must not be hardcoded
        // — see BillingProvider.calculateGST.
        final gstPercentage = taxProvider.totalGstPercentage;

        // No rates loaded means we cannot price this bill. Showing the
        // subtotal as the total would quote the customer an untaxed figure
        // and then charge them the taxed one — the server applies the rate
        // regardless of what this screen managed to fetch.
        final taxUnavailable = !taxProvider.hasTaxData;
        final gstAmount = billingProvider.calculateGST(subtotal, gstPercentage);
        final total = billingProvider.calculateTotal(subtotal, gstAmount);

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Fullscreen Minimal Backdrop Blur matching app style
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                  child: Container(color: Colors.black.withValues(alpha: 0.12)),
                ),
              ),

              // Main Frosted Glassmorphic Modal Card
              SafeArea(
                child: Center(
                  child: Container(
                    width: isTablet ? size.width * 0.72 : size.width * 0.90,
                    height: isTablet ? size.height * 0.82 : size.height * 0.86,
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 640 : 460,
                      maxHeight: isTablet ? 760 : 660,
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 12,
                      vertical: isTablet ? 20 : 12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Glass Header Bar with Order Badge
                                _buildHeader(context),

                                // Scrollable Preview Content
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      12,
                                      14,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Short Order Summary (No repeated Order Number!)
                                        _buildShortOrderSummary(
                                          context,
                                          effectiveCartItems,
                                        ),
                                        const SizedBox(height: 12),

                                        // Split Bill toggle — only offered
                                        // once the order is actually saved
                                        // server-side (real OrderDetailIds
                                        // to split are needed).
                                        if (_canSplit) ...[
                                          _buildSplitToggle(),
                                          const SizedBox(height: 12),
                                        ],
                                        if (_splitMode) ...[
                                          SplitBillPicker(
                                            loading: _loadingSplitItems,
                                            items: _unbilledItems,
                                            selectedIds: _selectedIds,
                                            onToggle: _toggleItem,
                                            onSelectAll:
                                                () => setState(() {
                                                  _selectedIds =
                                                      _unbilledItems
                                                          .map(
                                                            (i) =>
                                                                i.orderDetailId ??
                                                                '',
                                                          )
                                                          .toSet();
                                                }),
                                            onSelectNone:
                                                () => setState(() {
                                                  _selectedIds = {};
                                                }),
                                          ),
                                          const SizedBox(height: 12),
                                        ],

                                        // Order Items List
                                        _buildOrderItemsSection(
                                          effectiveCartItems,
                                        ),
                                        const SizedBox(height: 12),

                                        // Bill Amount & Breakdown
                                        _buildBillBreakdownSection(
                                          subtotal: subtotal,
                                          gstAmount: gstAmount,
                                          gstPercentage: gstPercentage,
                                          total: total,
                                          taxUnavailable: taxUnavailable,
                                          onRetryTax:
                                              () =>
                                                  taxProvider.refreshTaxData(),
                                        ),
                                        const SizedBox(height: 12),

                                        // Payment Method Selector (Full Width Container!)
                                        _buildPaymentMethodSection(
                                          billingProvider,
                                        ),
                                        const SizedBox(height: 12),

                                        // Customer Details & 10-Digit Phone Number Field with Visible Border
                                        _buildCustomerDetailsSection(
                                          billingProvider,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Confirm & Print Bill Action Button Bar
                                _buildActionBar(
                                  context,
                                  billingProvider,
                                  subtotal,
                                  gstAmount,
                                  total,
                                  taxUnavailable: taxUnavailable,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Header Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.request_quote_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle Badge Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Order #${widget.orderNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close IconButton
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () async {
              await HapticHelper.triggerFeedback();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortOrderSummary(
    BuildContext context,
    List<CartItem> cartItems,
  ) {
    final navProvider = context.read<NavigationProvider>();
    final tableName =
        widget.tableId != null
            ? (navProvider.selectedTableName ?? 'Table ${widget.tableId}')
            : (navProvider.selectedOrderType ?? 'Takeaway / Phone');

    final itemCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                widget.tableId != null
                    ? Icons.table_restaurant_rounded
                    : Icons.shopping_bag_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                tableName,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$itemCount ${itemCount == 1 ? 'Item' : 'Items'}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.call_split_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Split Bill',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: _splitMode,
            activeColor: AppColors.primary,
            onChanged: (value) async {
              await HapticHelper.triggerFeedback();
              await _toggleSplitMode(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(List<CartItem> cartItems) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Structured Column Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'ITEM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Center(
                    child: Text(
                      'QTY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 95,
                  child: Text(
                    'AMOUNT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Order Items Table List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cartItems.length,
            separatorBuilder:
                (context, index) => const Divider(
                  height: 10,
                  thickness: 0.5,
                  color: Color(0xFFE2E8F0),
                ),
            itemBuilder: (context, index) {
              return _OrderItemRowTile(item: cartItems[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillBreakdownSection({
    required double subtotal,
    required double gstAmount,
    required double gstPercentage,
    required double total,
    bool taxUnavailable = false,
    VoidCallback? onRetryTax,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildBreakdownRow(label: AppStrings.subtotal, amount: subtotal),
          const SizedBox(height: 4),
          if (taxUnavailable)
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Tax rates unavailable — total cannot be calculated',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
                if (onRetryTax != null)
                  TextButton(
                    onPressed: onRetryTax,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
              ],
            )
          else
            _buildBreakdownRow(
              label: AppStrings.billing.gstWithRate(gstPercentage),
              amount: gstAmount,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, thickness: 0.8, color: Color(0xFFCBD5E1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${CurrencyConstants.symbol}${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({required String label, required double amount}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          '${CurrencyConstants.symbol}${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(BillingProvider billingProvider) {
    if (billingProvider.isLoadingPaymentModes) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.90),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    child: SkeletonLoader.rectangular(
                      height: 38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (billingProvider.paymentModes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children:
                  billingProvider.paymentModes.map((mode) {
                    final isSelected =
                        billingProvider.selectedPaymentMode?.paymentModeId ==
                        mode.paymentModeId;

                    return GestureDetector(
                      onTap: () {
                        billingProvider.setSelectedPaymentMode(mode);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPaymentMaterialIcon(mode.modeName),
                              size: 15,
                              color:
                                  isSelected ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              mode.modeName ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMaterialIcon(String? modeName) {
    switch (modeName?.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'upi':
      case 'qr':
      case 'online':
        return Icons.qr_code_scanner_rounded;
      case 'card':
      case 'credit':
      case 'debit':
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Widget _buildCustomerDetailsSection(BillingProvider billingProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Customer Phone Number (Optional)',
            controller: _phoneController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            maxLength: 10,
            counterText: '',
            onChanged: (val) => billingProvider.setCustomerPhone(val),
            hintText: AppStrings.dashboard.enterTenDigitMobile,
            prefixIcon: Icons.phone_rounded,
            fillColor: Colors.white.withValues(alpha: 0.85),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 10) {
                  return 'Please enter 10 digits';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    BillingProvider billingProvider,
    double subtotal,
    double gstAmount,
    double total, {
    /// Blocks billing when no tax rates could be loaded — see the breakdown
    /// section: quoting an untaxed total the server will not honour is worse
    /// than refusing to quote one.
    bool taxUnavailable = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.60),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              (billingProvider.isGenerating ||
                      _loadingSplitItems ||
                      _nothingLeftToBill ||
                      taxUnavailable ||
                      (_splitMode && _selectedIds.isEmpty))
                  ? null
                  : () async {
                    await _handleConfirmAndPrintBill(
                      context,
                      billingProvider,
                      subtotal,
                      gstAmount,
                      total,
                    );
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon:
              billingProvider.isGenerating
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                  : const Icon(Icons.print_rounded, size: 18),
          label: Text(
            billingProvider.isGenerating
                ? 'Generating Bill...'
                : (_splitMode
                    ? 'Confirm & Print Split Bill'
                    : 'Confirm & Print Bill'),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirmAndPrintBill(
    BuildContext context,
    BillingProvider billingProvider,
    double subtotal,
    double gstAmount,
    double total,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    if (_splitMode && _selectedIds.isEmpty) {
      AppSnackBar.showWarning(
        context,
        'Select at least one item to bill.',
      );
      return;
    }

    await HapticHelper.triggerFeedback();
    if (!mounted) return;

    // How many items this split leaves behind — 0 for a normal, full-order
    // bill. Computed up front since we already know exactly which items
    // this request covers; no need to re-query the server after payment.
    final remainingUnbilledCount =
        _splitMode ? (_unbilledItems.length - _selectedIds.length) : 0;

    try {
      final billBytes = await billingProvider.generateBill(
        cartItems: _effectiveCartItems(context),
        orderNumber: widget.orderNumber,
        subtotal: subtotal,
        gstAmount: gstAmount,
        total: total,
        orderId: widget.orderId,
        selectedOrderDetailIds: _splitMode ? _selectedIds.toList() : null,
      );

      if (context.mounted) {
        // 1. Show Bill PDF Viewer Dialog (print preview popup)
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => BillPDFViewerDialog(
                pdfBytes: billBytes,
                orderNumber: widget.orderNumber,
                fileName: 'Bill_${widget.orderNumber}.pdf',
              ),
        );

        // 2. Close the GenerateBillSummaryDialog modal
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // 3. Show BillSuccessDialog ("Bill Generated" popup with "Proceed to Pay" - barrierDismissible: false)
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => BillSuccessDialog(
                  orderNumber: widget.orderNumber,
                  total: total,
                  customerPhone: billingProvider.customerPhone,
                  billBytes: billBytes,
                  onBillGenerated: widget.onBillGenerated,
                  tableId: widget.tableId,
                  orderId: widget.orderId,
                  remainingUnbilledCount: remainingUnbilledCount,
                ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(
          context,
          billingProvider.errorMessage ?? 'Error generating bill: $e',
        );
      }
    }
  }
}

class _OrderItemRowTile extends StatefulWidget {
  final CartItem item;

  const _OrderItemRowTile({required this.item});

  @override
  State<_OrderItemRowTile> createState() => _OrderItemRowTileState();
}

class _OrderItemRowTileState extends State<_OrderItemRowTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final itemTotal = widget.item.price * widget.item.quantity;

    return InkWell(
      onTap: () {
        HapticHelper.triggerFeedback();
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Name Column (Flexible width, expandable on tap)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: _isExpanded ? null : 1,
                          overflow:
                              _isExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_isExpanded && widget.item.name.length > 18)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 1),
                          child: Icon(
                            Icons.unfold_more_rounded,
                            size: 14,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                  if (widget.item.specialNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.item.specialNotes!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: _isExpanded ? null : 1,
                      overflow:
                          _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Quantity Column (Fixed 52px width, centered)
            SizedBox(
              width: 52,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'x${widget.item.quantity}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Amount Column (Fixed 95px width, right aligned for max 5-digit values e.g. $12345.00)
            SizedBox(
              width: 95,
              child: Text(
                '${CurrencyConstants.symbol}${itemTotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
