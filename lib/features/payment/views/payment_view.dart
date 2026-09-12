import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/guid_helper.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/billing/providers/billing_provider.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/models/bill_generation_models.dart';
import '../widgets/amount_card.dart';
import '../widgets/confirm_button.dart';
import '../models/tender_line.dart';
import '../widgets/add_tender_sheet.dart';
import '../widgets/tender_list_card.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

typedef PaymentView = PaymentPage;

class PaymentPage extends StatefulWidget {
  final String? orderId;
  final String? orderNumber;
  final double? totalAmount;
  final VoidCallback? onPaymentCompleted;
  final String? tableId;
  final String? billId;

  /// Whether this payment closes out the whole order. Defaults to true —
  /// every existing caller keeps releasing the table and returning to the
  /// dashboard exactly as before. A split bill that still leaves other
  /// items unbilled passes `false` so the table stays occupied and the
  /// local cart isn't wiped out from under the other guests' items — see
  /// [GenerateBillSummaryDialog]'s split-bill flow.
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
  /// Tenders staged for this bill. A bill can be settled across several
  /// modes — cash plus UPI, say — and SavePayment takes them all in one call,
  /// writing a Payment row per entry. Collecting them here rather than paying
  /// one mode at a time keeps it to a single transaction and a single receipt.
  final List<TenderLine> _tenders = [];

  bool _processing = false;

  String? _fetchedOrderNumber;
  String? _fetchedBillId;
  double? _actualBillAmount;

  /// Sum of payments already recorded against this bill, from
  /// Order/GetPaymentDtByBillId. Subtracted from the bill total so the screen
  /// asks for the outstanding balance rather than the whole bill again.
  double _alreadyPaidAmount = 0;

  bool _loadingDetails = false;

  /// Cash tendered by the customer — drives the live change display and the
  /// `returnAmt` sent with the payment. See [CashTenderCard].
  final TextEditingController _cashReceivedController = TextEditingController();

  /// Change actually handed back on the payment that just succeeded, shown
  /// in the success dialog.
  double _lastReturnAmt = 0;

  /// What was taken on the payment that just succeeded. Captured before the
  /// staged tenders are cleared, so the receipt can still describe a bill
  /// settled across several modes — "Cash + UPI" rather than one of them.
  double _paidNowTotal = 0;
  String _tenderSummary = '';

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[PaymentPage] Initialized - orderId: ${widget.orderId}, amount: ${widget.totalAmount}, order: ${widget.orderNumber}, tableId: ${widget.tableId}, billId: ${widget.billId}',
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    setState(() {
      _loadingDetails = true;
    });

    try {
      String? effectiveBillId = widget.billId;

      // 1. Fetch order details using Order/getOrderDetailById API if orderId is provided
      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        debugPrint(
          '[PaymentPage] Fetching order details for orderId: ${widget.orderId}',
        );
        final orderDetails = await ApiService.getOrderDetailById(
          orderId: widget.orderId!,
        );

        if (orderDetails != null &&
            orderDetails.isSuccess == true &&
            orderDetails.data != null &&
            orderDetails.data!.isNotEmpty) {
          final data = orderDetails.data!.first;
          _fetchedOrderNumber = data.orderNo;
          // The order's BillId is per order-DETAIL: unbilled lines carry the
          // all-zero placeholder, and the header value is whichever line the
          // API picked. Treat it as a hint only — never as an override.
          if (GuidHelper.isValid(data.billId)) {
            _fetchedBillId = data.billId;
            // Only adopt it when the caller did not name a bill — see
            // effectiveBillId for why the order's own answer is unreliable
            // once an order has been split across several bills.
            effectiveBillId ??= data.billId;
          } else if (data.billId != null) {
            debugPrint(
              '[PaymentPage] Ignoring placeholder billId from order details: '
              '${data.billId}',
            );
          }

          // Calculate total from item list as fallback
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
          debugPrint(
            '[PaymentPage] Order details fetched. OrderNo: $_fetchedOrderNumber, BillId: $_fetchedBillId',
          );
        }
      }

      // 2. Fetch bill details using getBillDetailByBillId API if billId is available
      if (effectiveBillId != null && effectiveBillId.isNotEmpty) {
        debugPrint(
          '[PaymentPage] Fetching bill details for billId: $effectiveBillId',
        );
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
          debugPrint('[PaymentPage] Bill details fetched. Amount: ₹$billAmt');
        }

        // A bill can be created unpaid and settled later, and can take more
        // than one payment. Without subtracting what has already been paid,
        // reopening a part-paid bill asks the customer for the full total a
        // second time.
        final paid = await ApiService.getPaidAmountForBill(
          billId: effectiveBillId,
        );
        if (paid != null && paid > 0) {
          _alreadyPaidAmount = paid;
          debugPrint('[PaymentPage] Already paid on this bill: ₹$paid');
        }
      }
    } catch (e) {
      debugPrint('[PaymentPage] Error loading payment details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingDetails = false;
        });
      }
    }
  }

  String get currentOrderNumber {
    if (_fetchedOrderNumber != null && _fetchedOrderNumber!.isNotEmpty) {
      return _fetchedOrderNumber!;
    }
    return widget.orderNumber ?? '';
  }

  /// Full value of the bill, before considering anything already paid.
  double get billTotalAmount {
    if (_actualBillAmount != null && _actualBillAmount! > 0) {
      return _actualBillAmount!;
    }
    return widget.totalAmount ?? 0.0;
  }

  /// What the customer still owes, before anything staged on this screen.
  /// Never negative — an overpaid bill owes nothing further.
  double get currentAmount {
    final due = billTotalAmount - _alreadyPaidAmount;
    return due > 0 ? due : 0.0;
  }

  /// Sum of the tenders staged but not yet saved.
  double get _stagedTotal =>
      _tenders.fold(0.0, (sum, t) => sum + t.amount);

  /// Still outstanding once the staged tenders are counted.
  double get _remainingAfterStaged {
    final left = currentAmount - _stagedTotal;
    return left > 0 ? left : 0.0;
  }

  /// Whether the staged tenders clear the bill. Tolerates float dust, since
  /// money here is 2dp and the server compares with >=.
  bool get _fullySettled => _remainingAfterStaged <= 0.004;

  /// Change owed across the staged cash tenders.
  double get _stagedChange =>
      _tenders.fold(0.0, (sum, t) => sum + t.returnAmount);

  /// The bill this payment settles. Only ever a real id — the all-zero
  /// placeholder is rejected at every source so it can never shadow the id the
  /// caller passed in.
  String? get effectiveBillId {
    // The caller's bill id wins. An order can carry several bills — that is
    // what splitting one produces — and getOrderDetailById reports only a
    // single header-level BillId, taken from the first line that happens to
    // carry one. On a split order that is the EARLIEST bill, which is usually
    // already paid, so preferring it meant opening a settled bill and showing
    // nothing left to pay while the bill actually being settled was ignored.
    final explicit = GuidHelper.orNull(widget.billId);
    if (explicit != null) return explicit;

    // Only when no bill was named: fall back to whatever the order reports.
    return GuidHelper.orNull(_fetchedBillId);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cashReceivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        title: Text(AppStrings.payment.paymentTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            _triggerHapticLight();
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Order #${currentOrderNumber.isNotEmpty ? currentOrderNumber : (widget.orderId ?? '')}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // The bill's own total, not the balance. It is labelled "Total
              // Amount", and the Payments card below already reports paid and
              // remaining — showing the balance here too gave two figures for
              // the same thing, one of them under the wrong label.
              AmountCard(
                amount: billTotalAmount,
                isLoading: _loadingDetails,
              ),
              const SizedBox(height: 16),

              TenderListCard(
                tenders: _tenders,
                billTotal: billTotalAmount,
                previouslyPaid: _alreadyPaidAmount,
                onRemove: _removeTender,
              ),
              const SizedBox(height: 12),

              // Nothing left to collect once the tenders cover the bill, so
              // the action disappears rather than inviting an overpayment.
              if (!_fullySettled)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loadingDetails ? null : _addTender,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      _tenders.isEmpty ? 'Add payment' : 'Add another payment',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ConfirmButton(
            processing: _processing,
            isLoading: _loadingDetails,
            // Nothing staged means nothing to save. A part-payment is allowed
            // — the bill simply stays open and the balance is collected later,
            // which the server already supports via BillHead.IsPaid = 1.
            onPressed:
                (_processing || _tenders.isEmpty) ? null : _processPayment,
          ),
        ),
      ),
    );
  }

  Future<void> _addTender() async {
    await _triggerHapticLight();
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
    await _triggerHapticHeavy();
    if (!mounted) return;
    setState(() => _processing = true);

    try {
      debugPrint('=== PAYMENT PROCESSING DEBUG START ===');
      debugPrint('Payment Page - Order ID: ${widget.orderId}');
      debugPrint('Payment Page - Order Number: $currentOrderNumber');
      debugPrint(
        'Payment Page - Total Amount: ${CurrencyConstants.symbol}$currentAmount',
      );
      debugPrint('Payment Page - Table ID: ${widget.tableId}');

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

      // Change comes only from cash overpayment, and each tender carries its
      // own so the Payment rows stay individually correct.
      _lastReturnAmt = _stagedChange;
      _paidNowTotal = _stagedTotal;
      _tenderSummary = _tenders
          .map((t) => t.label)
          .toSet()
          .join(' + ')
          .toUpperCase();

      debugPrint(
        'Payment Page - ${_tenders.length} tender(s), '
        'staged ${_stagedTotal.toStringAsFixed(2)}, '
        'change ${_stagedChange.toStringAsFixed(2)}',
      );

      final savePaymentRequest = SavePaymentRequest(
        // Non-null by this point: the guard above throws when no real bill id
        // could be resolved.
        billId: billId!,
        // One Payment row per tender. SP_SavePayment walks the list and
        // SP_UpdPaymentStatusBill sums them, so a bill split across cash and
        // UPI settles in a single call.
        paymentDetails: _tenders.map((t) => t.toPaymentDetail()).toList(),
      );

      final response = await ApiService.savePayment(
        request: savePaymentRequest,
      );

      if (response?.isSuccess == true) {
        await _triggerHapticLight();
      } else {
        throw Exception('Failed to save payment: ${response?.message}');
      }
    } catch (e) {
      debugPrint('Error in payment processing: $e');
      setState(() => _processing = false);

      if (mounted) {
        AppSnackBar.showError(context, 'Payment failed: $e');
      }
      return;
    }

    setState(() => _processing = false);
    await _showSuccessDialog();
  }

  Future<void> _showSuccessDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Pre-capture providers and callbacks
    final onCompleted = widget.onPaymentCompleted;
    TableProvider? tableProvider;
    AnimatedCartProvider? animatedCartProvider;
    try {
      tableProvider = Provider.of<TableProvider>(context, listen: false);
      animatedCartProvider = Provider.of<AnimatedCartProvider>(
        context,
        listen: false,
      );
    } catch (e) {
      debugPrint('[PaymentPage] Provider access error: $e');
    }

    bool isRedirecting = false;
    Timer? timer;
    int secondsRemaining = 5;

    Future<void> executeRedirect(BuildContext dialogContext) async {
      if (isRedirecting) return;
      isRedirecting = true;
      timer?.cancel();

      // 1. Update table status if tableId is present — only when this
      // payment actually finishes the order. A split bill with other
      // guests' items still unbilled must NOT release the table or wipe
      // the shared cart data; just refresh so it reflects the latest paid
      // amount from the server.
      if (widget.tableId != null && tableProvider != null) {
        if (widget.isFinalSettlement) {
          try {
            // Forget the settled order's bill and cart before refreshing. The
            // server frees the table on its own once the order is fully paid
            // (see SP_UpdPaymentStatusOrder — it sets OrderHead.IsPaid, and the
            // channel list only reports orders that are still unpaid), so the
            // refresh below already returns it as available. What the server
            // cannot do is clear this device's cached bill id, and leaving it
            // behind hands the next customer the previous bill. Scoped to the
            // order so settling one group on a shared table does not wipe
            // another group's still-unpaid bill.
            final settledOrderId = widget.orderId;
            if (settledOrderId != null && settledOrderId.isNotEmpty) {
              await tableProvider.clearBillId(settledOrderId);
            }

            if (animatedCartProvider != null &&
                settledOrderId != null &&
                settledOrderId.isNotEmpty) {
              animatedCartProvider.clearOrderData(settledOrderId);
            }

            await tableProvider.refreshTables();
          } catch (e) {
            debugPrint('Error releasing table after settlement: $e');
          }
        } else {
          try {
            await tableProvider.refreshTables();
          } catch (e) {
            debugPrint('Error refreshing table after split payment: $e');
          }
        }
      }

      // 2. Close dialog if open
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      // 3. Refresh dashboard tables
      if (tableProvider != null) {
        try {
          await tableProvider.refreshTables();
        } catch (e) {
          debugPrint('Error refreshing dashboard: $e');
        }
      }

      // 4. Trigger payment completed callback
      onCompleted?.call();

      // 5. Navigate back to first route (Dashboard) — a split bill with
      // items still unbilled leaves navigation to onCompleted instead, so
      // it can return to the order screen rather than the whole dashboard.
      if (mounted && widget.isFinalSettlement) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            // Initialize 5-second countdown timer once
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsRemaining > 1) {
                if (builderContext.mounted) {
                  setDialogState(() {
                    secondsRemaining--;
                  });
                }
              } else {
                t.cancel();
                executeRedirect(dialogContext);
              }
            });

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Payment Successful',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${CurrencyConstants.symbol}${_paidNowTotal.toStringAsFixed(2)}'
                      ' • $_tenderSummary',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _kv('Order', '#$currentOrderNumber', context),
                          const SizedBox(height: 6),
                          _kv(
                            'Amount',
                            '${CurrencyConstants.symbol}${_paidNowTotal.toStringAsFixed(2)}',
                            context,
                          ),
                          const SizedBox(height: 6),
                          _kv('Method', _tenderSummary, context),
                          if (_lastReturnAmt > 0) ...[
                            const SizedBox(height: 6),
                            _kv(
                              'Change Given',
                              CurrencyConstants.format(_lastReturnAmt),
                              context,
                              valueColor: Colors.green[700],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Auto-redirecting in ${secondsRemaining}s...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton(
                        onPressed: () {
                          _triggerHapticLight();
                          executeRedirect(dialogContext);
                        },
                        child: Text('Continue (${secondsRemaining}s)'),
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

  Widget _kv(String k, String v, BuildContext context, {Color? valueColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          v,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _triggerHapticLight() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 30, amplitude: 128);
      }
      await HapticFeedback.lightImpact();
    } catch (_) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> _triggerHapticHeavy() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 120, amplitude: 255);
      }
      await HapticFeedback.heavyImpact();
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }
  }
}
