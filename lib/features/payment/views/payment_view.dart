import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/guid_helper.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/billing/providers/billing_provider.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/models/bill_generation_models.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';
import '../models/tender_line.dart';
import '../widgets/amount_card.dart';
import '../widgets/payment_status_illustration.dart';
import '../widgets/payment_breakdown_card.dart';
import '../widgets/add_tender_sheet.dart';
import '../widgets/tender_list_card.dart';
import '../widgets/payment_page_skeleton.dart';

typedef PaymentView = PaymentPage;

class PaymentPage extends StatefulWidget {
  final String? orderId;
  final String? orderNumber;
  final double? totalAmount;
  final VoidCallback? onPaymentCompleted;
  final String? tableId;
  final String? billId;

  /// Whether this payment closes out the whole order. Defaults to true.
  final bool isFinalSettlement;

  const PaymentPage({
    super.key,
    this.orderId,
    this.orderNumber,
    this.totalAmount,
    this.onPaymentCompleted,
    this.tableId,
    this.billId,
    this.isFinalSettlement = true,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  /// Tenders staged for this bill in this session.
  final List<TenderLine> _tenders = [];

  bool _processing = false;
  String? _fetchedOrderNumber;
  String? _fetchedBillId;
  double? _actualBillAmount;

  /// Sum of payments already recorded against this bill from earlier calls.
  double _alreadyPaidAmount = 0;
  bool _loadingDetails = false;
  bool _savedSettled = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[PaymentPage] Initialized - orderId: ${widget.orderId}, amount: ${widget.totalAmount}, order: ${widget.orderNumber}, tableId: ${widget.tableId}, billId: ${widget.billId}',
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    setState(() => _loadingDetails = true);

    try {
      String? effectiveBillId = widget.billId;

      // 1. Fetch order details if orderId is provided
      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        final orderDetails = await ApiService.getOrderDetailById(
          orderId: widget.orderId!,
        );

        if (orderDetails != null &&
            orderDetails.isSuccess == true &&
            orderDetails.data != null &&
            orderDetails.data!.isNotEmpty) {
          final data = orderDetails.data!.first;
          _fetchedOrderNumber = data.orderNo;
          if (GuidHelper.isValid(data.billId)) {
            _fetchedBillId = data.billId;
            effectiveBillId ??= data.billId;
          }

          if (data.orderDetailList != null &&
              data.orderDetailList!.isNotEmpty) {
            double itemsSum = 0.0;
            for (var item in data.orderDetailList!) {
              final price =
                  item.totPrice?.toDouble() ??
                  ((item.itemPrice?.toDouble() ?? 0.0) *
                      (item.productQty ?? 1));
              itemsSum += price;
            }
            if (itemsSum > 0) {
              _actualBillAmount = itemsSum;
            }
          }
        }
      }

      // 2. Fetch bill details if billId is available
      if (effectiveBillId != null && effectiveBillId.isNotEmpty) {
        final billDetails = await ApiService.getBillDetailByBillId(
          billId: effectiveBillId,
        );

        if (billDetails != null &&
            billDetails.isSuccess &&
            billDetails.data != null) {
          final billAmt = billDetails.data!.billHeadDt.billAmountInclTax;
          if (billAmt > 0) {
            _actualBillAmount = billAmt;
          }
        }

        final paid = await ApiService.getPaidAmountForBill(
          billId: effectiveBillId,
        );
        if (paid != null && paid > 0) {
          _alreadyPaidAmount = paid;
        }
      }
    } catch (e) {
      debugPrint('[PaymentPage] Error loading payment details: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingDetails = false);
      }
    }
  }

  String get currentOrderNumber {
    if (_fetchedOrderNumber != null && _fetchedOrderNumber!.isNotEmpty) {
      return _fetchedOrderNumber!;
    }
    return widget.orderNumber ?? '';
  }

  /// Full value of the bill before subtracting paid amounts.
  double get billTotalAmount {
    if (_actualBillAmount != null && _actualBillAmount! > 0) {
      return _actualBillAmount!;
    }
    return widget.totalAmount ?? 0.0;
  }

  /// What is still owed before considering staged tenders.
  double get currentAmount {
    final due = billTotalAmount - _alreadyPaidAmount;
    return due > 0 ? due : 0.0;
  }

  /// Sum of tenders staged in this session.
  double get _stagedTotal =>
      _tenders.fold(0.0, (sum, t) => sum + t.amount);

  /// Total amount paid (previously recorded + staged).
  double get _totalPaid => _alreadyPaidAmount + _stagedTotal;

  /// Remaining balance after considering staged tenders.
  double get _remainingAfterStaged {
    final left = billTotalAmount - _totalPaid;
    return left > 0 ? left : 0.0;
  }

  /// Whether all dues are covered.
  bool get _fullySettled => _remainingAfterStaged <= 0.004;

  bool get _isAlreadySettled =>
      _savedSettled || (_alreadyPaidAmount >= billTotalAmount - 0.004 && billTotalAmount > 0);

  PaymentStatusState get _currentStatus {
    if (_isAlreadySettled || _fullySettled || (billTotalAmount > 0 && _totalPaid >= billTotalAmount - 0.004)) {
      return PaymentStatusState.paidInFull;
    }
    if (_totalPaid > 0.004) {
      return PaymentStatusState.partiallyPaid;
    }
    return PaymentStatusState.pending;
  }

  String? get effectiveBillId {
    final explicit = GuidHelper.orNull(widget.billId);
    if (explicit != null) return explicit;
    return GuidHelper.orNull(_fetchedBillId);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _currentStatus;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () async {
            await HapticHelper.triggerFeedback();
            if (context.mounted) Navigator.pop(context);
          },
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        // (Top header print icon removed per user request)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
            child: Row(
              children: [
                if (_loadingDetails)
                  const ShimmerEffect(
                    child: ShimmerBone(
                      width: 140,
                      height: 22,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: Text(
                      'Order #${currentOrderNumber.isNotEmpty ? currentOrderNumber : (widget.orderId ?? '')}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _loadingDetails
          ? const SafeArea(child: PaymentPageSkeleton())
          : FadeTransition(
              opacity: _fadeIn,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  children: [
                    // 1. Top Hero Card (Scenario 1, 2, or 4)
                    AmountCard(
                      totalAmount: billTotalAmount,
                      paidAmount: _totalPaid,
                      remainingAmount: _remainingAfterStaged,
                      status: currentStatus,
                    ),
                    const SizedBox(height: 14),

                    // 2. Breakdown Card (Total Amount, Amount Paid, Amount Due)
                    PaymentBreakdownCard(
                      totalAmount: billTotalAmount,
                      paidAmount: _totalPaid,
                      remainingAmount: _remainingAfterStaged,
                      status: currentStatus,
                    ),
                    const SizedBox(height: 18),

                    // 3. Payments Section (Empty card with + Add Payment, or list of payments + Add Another)
                    TenderListCard(
                      tenders: _tenders,
                      billTotal: billTotalAmount,
                      previouslyPaid: _alreadyPaidAmount,
                      onRemove: _removeTender,
                      onAddAnotherPayment: _addTender,
                      isFullySettled: _fullySettled,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isAlreadySettled
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: _buildSingleActionButton(),
              ),
            ),
    );
  }

  /// Builds the single bottom action button:
  /// - Disabled by default when no payment is added.
  /// - Enabled when tenders are staged.
  /// - Shows success popup redirecting to dashboard when clicked.
  Widget _buildSingleActionButton() {
    if (_loadingDetails) {
      return const ShimmerEffect(
        child: ShimmerBone(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      );
    }

    if (_processing) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF4F46E5),
          ),
        ),
      );
    }

    final bool isEnabled = _tenders.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: isEnabled ? 2 : 0,
          shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          isEnabled ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          size: 18,
        ),
        label: const Text(
          'Confirm Payment',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Future<void> _addTender() async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;

    final tender = await AddTenderSheet.show(
      context,
      _remainingAfterStaged,
      orderNumber: currentOrderNumber,
    );
    if (tender == null || !mounted) return;

    setState(() => _tenders.add(tender));
  }

  void _removeTender(int index) {
    setState(() => _tenders.removeAt(index));
  }

  Future<void> _processPayment() async {
    await HapticHelper.triggerFeedback();
    if (!mounted) return;
    setState(() => _processing = true);

    try {
      String? billId = effectiveBillId;

      if (GuidHelper.isNullOrEmpty(billId)) {
        try {
          final billingProvider = Provider.of<BillingProvider>(
            context,
            listen: false,
          );
          billId = GuidHelper.orNull(billingProvider.billId);
        } catch (e) {
          debugPrint('Payment Page - Error accessing BillingProvider: $e');
        }

        if (GuidHelper.isNullOrEmpty(billId)) {
          throw Exception('No bill ID found. Please generate bill first.');
        }
      }

      final savePaymentRequest = SavePaymentRequest(
        billId: billId!,
        paymentDetails: _tenders.map((t) => t.toPaymentDetail()).toList(),
      );

      final response = await ApiService.savePayment(
        request: savePaymentRequest,
      );

      if (response?.isSuccess == true) {
        final now = DateTime.now();
        if (widget.billId != null && widget.billId!.isNotEmpty) {
          await HiveService.saveBillTimestamp(widget.billId!, now);
        }
        if (widget.orderId != null && widget.orderId!.isNotEmpty) {
          await HiveService.saveBillTimestamp(widget.orderId!, now);
        }
        if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) {
          await HiveService.saveBillTimestamp(widget.orderNumber!, now);
        }

        // Clean up cart and table state if order is completed
        if (mounted && widget.tableId != null) {
          try {
            final tp = Provider.of<TableProvider>(context, listen: false);
            final acp =
                Provider.of<AnimatedCartProvider>(context, listen: false);
            final settledOrderId = widget.orderId;
            if (widget.isFinalSettlement) {
              if (settledOrderId != null && settledOrderId.isNotEmpty) {
                await tp.clearBillId(settledOrderId);
                acp.clearOrderData(settledOrderId);
              }
            }
            await tp.refreshTables();
          } catch (e) {
            debugPrint('[PaymentPage] Table cleanup error: $e');
          }
        }

        setState(() {
          _alreadyPaidAmount += _stagedTotal;
          _tenders.clear();
          _savedSettled = true;
          _processing = false;
        });

        widget.onPaymentCompleted?.call();

        // Show the success redirect popup
        if (mounted) {
          await _showSuccessRedirectDialog();
        }
      } else {
        throw Exception('Failed to save payment: ${response?.message}');
      }
    } catch (e) {
      debugPrint('Error in payment processing: $e');
      if (mounted) {
        setState(() => _processing = false);
        AppSnackBar.showError(context, 'Payment failed: $e');
      }
    }
  }

  /// Popup showing success and auto-redirecting to the dashboard.
  Future<void> _showSuccessRedirectDialog() async {
    bool isRedirecting = false;
    Timer? timer;
    int secondsRemaining = 4;

    void executeRedirect(BuildContext dialogContext) {
      if (isRedirecting) return;
      isRedirecting = true;
      timer?.cancel();

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsRemaining > 1) {
                if (builderContext.mounted) {
                  setDialogState(() => secondsRemaining--);
                }
              } else {
                t.cancel();
                executeRedirect(dialogContext);
              }
            });

            return Dialog(
              backgroundColor: Colors.white,
              elevation: 8,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Green circular checkmark with halo
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    const Text(
                      'Payment Successful',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Pill: Bill Paid & Settled
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFBBF7D0),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Color(0xFF15803D),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Bill Paid & Settled',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '#$currentOrderNumber',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Amount Paid',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                billTotalAmount.toCurrency(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Redirecting notice
                    Text(
                      'Redirecting to dashboard in ${secondsRemaining}s...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Done Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticHelper.triggerFeedback();
                          executeRedirect(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
