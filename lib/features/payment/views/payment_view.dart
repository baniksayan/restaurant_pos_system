import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/billing/providers/billing_provider.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/models/bill_generation_models.dart';
import '../widgets/amount_card.dart';
import '../widgets/payment_methods.dart';
import '../widgets/qr_section.dart';
import '../widgets/confirm_button.dart';
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

  const PaymentPage({
    super.key,
    this.orderId,
    this.orderNumber,
    this.totalAmount,
    this.onPaymentCompleted,
    this.tableId,
    this.billId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  String _selectedPaymentMethod = 'cash';
  bool _processing = false;
  bool _showQR = false;

  String? _fetchedOrderNumber;
  String? _fetchedBillId;
  double? _actualBillAmount;
  bool _loadingDetails = false;

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
          if (data.billId != null && data.billId!.isNotEmpty) {
            _fetchedBillId = data.billId;
            effectiveBillId = data.billId;
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

  double get currentAmount {
    if (_actualBillAmount != null && _actualBillAmount! > 0) {
      return _actualBillAmount!;
    }
    return widget.totalAmount ?? 0.0;
  }

  String? get effectiveBillId {
    if (_fetchedBillId != null && _fetchedBillId!.isNotEmpty) {
      return _fetchedBillId;
    }
    return widget.billId;
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
              AmountCard(amount: currentAmount, isLoading: _loadingDetails),
              const SizedBox(height: 16),
              PaymentMethods(
                selected: _selectedPaymentMethod,
                isLoading: _loadingDetails,
                onChanged: (value) {
                  _triggerHapticLight();
                  setState(() {
                    _selectedPaymentMethod = value;
                    _showQR = (value == 'upi');
                  });
                },
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child:
                    _showQR
                        ? QRSection(
                          key: const ValueKey('qr-section'),
                          amount: currentAmount,
                          orderNumber: currentOrderNumber,
                        )
                        : const SizedBox.shrink(key: ValueKey('empty')),
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
            onPressed: _processing ? null : _processPayment,
          ),
        ),
      ),
    );
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
      debugPrint(
        'Payment Page - Selected Payment Method: $_selectedPaymentMethod',
      );

      String? billId = effectiveBillId;

      if (billId == null || billId.isEmpty) {
        try {
          final billingProvider = Provider.of<BillingProvider>(
            context,
            listen: false,
          );
          billId = billingProvider.billId;
        } catch (e) {
          debugPrint('Payment Page - Error accessing BillingProvider: $e');
        }

        if (billId == null || billId.isEmpty) {
          throw Exception('No bill ID found. Please generate bill first.');
        }
      }

      int paymentModeId = 1;
      if (_selectedPaymentMethod == 'card') {
        paymentModeId = 2;
      } else if (_selectedPaymentMethod == 'upi') {
        paymentModeId = 3;
      }

      final savePaymentRequest = SavePaymentRequest(
        billId: billId,
        paymentDetails: [
          PaymentDetail(
            paymentAmount: currentAmount,
            modeId: paymentModeId,
            refId: "",
            cardNo: "",
            returnAmt: 0,
          ),
        ],
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

      // 1. Update table status if tableId is present
      if (widget.tableId != null && tableProvider != null) {
        try {
          tableProvider.updateTableStatus(widget.tableId!, 'billSettled');
          await tableProvider.refreshTables();

          if (animatedCartProvider != null) {
            animatedCartProvider.clearTableData(widget.tableId!);
          }

          // Auto-clear table after 5 seconds
          Future.delayed(const Duration(seconds: 5), () async {
            try {
              tableProvider?.updateTableStatus(widget.tableId!, 'available');
              await tableProvider?.refreshTables();
            } catch (e) {
              debugPrint('Error auto-clearing table: $e');
            }
          });
        } catch (e) {
          debugPrint('Error updating table status: $e');
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

      // 5. Navigate back to first route (Dashboard)
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
                      '${CurrencyConstants.symbol}${currentAmount.toStringAsFixed(2)} • ${_selectedPaymentMethod.toUpperCase()}',
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
                            '${CurrencyConstants.symbol}${currentAmount.toStringAsFixed(2)}',
                            context,
                          ),
                          const SizedBox(height: 6),
                          _kv(
                            'Method',
                            _selectedPaymentMethod.toUpperCase(),
                            context,
                          ),
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

  Widget _kv(String k, String v, BuildContext context) {
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
