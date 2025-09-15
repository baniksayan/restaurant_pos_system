import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/currency_constants.dart';
import '../../view_models/providers/table_provider.dart';
import '../../view_models/providers/billing_provider.dart';
import '../../../services/api_service.dart';
import '../../../data/models/bill_generation_models.dart';

class PaymentPage extends StatefulWidget {
  final String orderNumber;
  final double totalAmount;
  final VoidCallback onPaymentCompleted;
  final String? tableId;
  final String? billId; // Add billId parameter

  const PaymentPage({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.onPaymentCompleted,
    this.tableId,
    this.billId, // Add billId parameter
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  String _selectedPaymentMethod = 'cash';
  bool _processing = false;
  bool _showQR = false;
  double? _actualBillAmount;
  bool _loadingBillDetails = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[PaymentPage] Initialized with amount: ${widget.totalAmount}, order: ${widget.orderNumber}, tableId: ${widget.tableId}, billId: ${widget.billId}',
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Fetch bill details if billId is provided
    if (widget.billId != null && widget.billId!.isNotEmpty) {
      _fetchBillDetails();
    }
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  // Fetch bill details using the new API
  Future<void> _fetchBillDetails() async {
    if (widget.billId == null || widget.billId!.isEmpty) return;

    setState(() {
      _loadingBillDetails = true;
    });

    try {
      debugPrint(
        '[PaymentPage] Fetching bill details for billId: ${widget.billId}',
      );
      final billDetails = await ApiService.getBillDetailByBillId(
        billId: widget.billId!,
      );

      if (billDetails != null &&
          billDetails.isSuccess &&
          billDetails.data != null) {
        final actualAmount = billDetails.data!.billHeadDt.billAmountInclTax;
        final isPhoneOrTakeawayOrder =
            widget.tableId == 'PhoneOrder' || widget.tableId == 'Takeaway';

        setState(() {
          _actualBillAmount = actualAmount;
          _loadingBillDetails = false;
        });

        debugPrint('[PaymentPage] Fetched actual bill amount: ₹$actualAmount');
        if (isPhoneOrTakeawayOrder && actualAmount == 0) {
          debugPrint(
            '[PaymentPage] API returned 0 for ${widget.tableId} order, will use local amount: ₹${widget.totalAmount}',
          );
        }
      } else {
        debugPrint(
          '[PaymentPage] Failed to fetch bill details: ${billDetails?.message}',
        );
        setState(() {
          _loadingBillDetails = false;
        });
      }
    } catch (e) {
      debugPrint('[PaymentPage] Error fetching bill details: $e');
      setState(() {
        _loadingBillDetails = false;
      });
    }
  }

  // Get the current amount to display (either from API or fallback to widget amount)
  double get currentAmount {
    // For takeaway/phone orders, if API returns 0 or null, use local calculation
    final isPhoneOrTakeawayOrder =
        widget.tableId == 'PhoneOrder' || widget.tableId == 'Takeaway';

    if (isPhoneOrTakeawayOrder &&
        (_actualBillAmount == null || _actualBillAmount == 0)) {
      debugPrint(
        '[PaymentPage] Using local amount for ${widget.tableId} order: ₹${widget.totalAmount}',
      );
      return widget.totalAmount;
    }

    // For table orders or when API returns valid amount, use API amount with fallback
    return _actualBillAmount ?? widget.totalAmount;
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
        title: const Text('Payment'),
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
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Order #${widget.orderNumber}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // child: Text(
                  //   'LIVE',
                  //   style: theme.textTheme.labelMedium?.copyWith(
                  //     color: Colors.green.shade700,
                  //     fontWeight: FontWeight.w700,
                  //   ),
                  // ),
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
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 24),
              _loadingBillDetails
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : _AmountCard(amount: currentAmount),
              const SizedBox(height: 16),
              _PaymentMethods(
                selected: _selectedPaymentMethod,
                onChanged: (value) {
                  _triggerHapticLight();
                  setState(() {
                    _selectedPaymentMethod = value;
                    _showQR = (value == 'upi' || value == 'card');
                  });
                },
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child:
                    _showQR
                        ? _QRSection(
                          key: const ValueKey('qr-section'),
                          amount: currentAmount,
                          orderNumber: widget.orderNumber,
                        )
                        : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              const SizedBox(height: 24),
              _ConfirmButton(
                processing: _processing,
                onPressed: _processing ? null : _processPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    await _triggerHapticHeavy();
    setState(() => _processing = true);

    try {
      debugPrint('=== PAYMENT PROCESSING DEBUG START ===');
      debugPrint(
        'Payment Page - Total Amount: ${CurrencyConstants.symbol}$currentAmount',
      );
      debugPrint('Payment Page - Order Number: ${widget.orderNumber}');
      debugPrint('Payment Page - Table ID: ${widget.tableId}');
      debugPrint(
        'Payment Page - Selected Payment Method: $_selectedPaymentMethod',
      );
      debugPrint('Payment Page - BillId passed as parameter: ${widget.billId}');

      // Use billId from widget parameter (passed from BillSuccessDialog) or fallback to provider
      String? billId = widget.billId;

      if (billId == null || billId.isEmpty) {
        debugPrint('Payment Page - ERROR: No billId provided as parameter');

        // Try to get billId from BillingProvider as fallback
        try {
          final billingProvider = Provider.of<BillingProvider>(
            context,
            listen: false,
          );
          billId = billingProvider.billId;
          debugPrint(
            'Payment Page - Fallback BillId from BillingProvider: $billId',
          );
        } catch (e) {
          debugPrint('Payment Page - Error accessing BillingProvider: $e');
        }

        if (billId == null || billId.isEmpty) {
          throw Exception('No bill ID found. Please generate bill first.');
        }
      }

      debugPrint('Payment Page - Final BillId to use: $billId');

      // Get payment mode ID (1 for cash, can be extended for other modes)
      int paymentModeId = 1; // Default to cash
      if (_selectedPaymentMethod == 'card') {
        paymentModeId = 2; // Assuming 2 for card
      } else if (_selectedPaymentMethod == 'upi') {
        paymentModeId = 3; // Assuming 3 for UPI
      }

      debugPrint('Payment Page - Payment Mode ID: $paymentModeId');

      // Create SavePayment request
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

      debugPrint('Payment Page - SavePayment Request Body:');
      debugPrint(savePaymentRequest.toJson().toString());

      // Call SavePayment API
      final response = await ApiService.savePayment(
        request: savePaymentRequest,
      );

      debugPrint('Payment Page - SavePayment Response:');
      debugPrint('Success: ${response?.isSuccess}');
      debugPrint('Message: ${response?.message}');
      debugPrint('Status Code: ${response?.statusCode}');
      debugPrint('Data: ${response?.data}');

      if (response?.isSuccess == true) {
        debugPrint('Payment Page - SavePayment API successful');
        await _triggerHapticLight();
      } else {
        throw Exception('Failed to save payment: ${response?.message}');
      }

      debugPrint('=== PAYMENT PROCESSING DEBUG END ===');
    } catch (e) {
      debugPrint('=== PAYMENT ERROR DEBUG ===');
      debugPrint('Error in payment processing: $e');
      debugPrint('Error Type: ${e.runtimeType}');
      setState(() => _processing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _processing = false);
    await _showSuccessDialog();
  }

  Future<void> _showSuccessDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                  backgroundColor: Colors.green.withOpacity(0.12),
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
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _kv('Order', '#${widget.orderNumber}', context),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () async {
                      _triggerHapticLight();

                      // Update table status to Bill Settled
                      if (widget.tableId != null) {
                        try {
                          final tableProvider = Provider.of<TableProvider>(
                            context,
                            listen: false,
                          );
                          tableProvider.updateTableStatus(
                            widget.tableId!,
                            'billSettled',
                          );
                          await tableProvider.refreshTables();

                          // Auto-clear table after 5 seconds (simulating table clearing)
                          Future.delayed(const Duration(seconds: 5), () async {
                            try {
                              tableProvider.updateTableStatus(
                                widget.tableId!,
                                'available',
                              );
                              await tableProvider.refreshTables();
                              debugPrint(
                                'Table ${widget.tableId} automatically cleared and made available',
                              );
                            } catch (e) {
                              debugPrint('Error auto-clearing table: $e');
                            }
                          });
                        } catch (e) {
                          debugPrint('Error updating table status: $e');
                        }
                      }

                      // Close payment success dialog
                      Navigator.pop(context);

                      // Navigate back to main page (dashboard) and refresh
                      Navigator.of(context).popUntil((route) => route.isFirst);

                      // Refresh table data on the dashboard
                      try {
                        final tableProvider = Provider.of<TableProvider>(
                          context,
                          listen: false,
                        );
                        await tableProvider.refreshTables();
                        debugPrint(
                          'Dashboard refreshed after payment completion',
                        );
                      } catch (e) {
                        debugPrint('Error refreshing dashboard: $e');
                      }

                      // Call the onPaymentCompleted callback
                      widget.onPaymentCompleted();
                    },
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
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
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 30, amplitude: 128);
      }
      await HapticFeedback.lightImpact();
    } catch (_) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> _triggerHapticHeavy() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 120, amplitude: 255);
      }
      await HapticFeedback.heavyImpact();
    } catch (_) {
      await HapticFeedback.heavyImpact();
    }
  }
}

class _AmountCard extends StatelessWidget {
  final double amount;
  const _AmountCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Amount',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${CurrencyConstants.symbol}${amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inclusive of all taxes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PaymentMethods({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget item({
      required String value,
      required String title,
      required String subtitle,
      required IconData icon,
    }) {
      final isSelected = selected == value;
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary.withOpacity(0.06) : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant,
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        item(
          value: 'cash',
          title: 'Cash',
          subtitle: 'Pay with physical cash to waiter',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 10),
        item(
          value: 'card',
          title: 'Card',
          subtitle: 'Debit/Credit card or contactless payment',
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 10),
        item(
          value: 'upi',
          title: 'UPI',
          subtitle: 'Scan QR with any UPI app',
          icon: Icons.qr_code_2,
        ),
      ],
    );
  }
}

class _QRSection extends StatelessWidget {
  final double amount;
  final String orderNumber;

  const _QRSection({
    super.key,
    required this.amount,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final data =
        'upi://pay?pa=8768412832@ptsbi&pn=WiZARD Restaurant&am=$amount&cu=INR&tn=Order $orderNumber';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Scan to Pay',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: Colors.green.shade700,
                ),
                Text(
                  '${CurrencyConstants.symbol}${amount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool processing;
  final VoidCallback? onPressed;
  const _ConfirmButton({required this.processing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon:
            processing
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.verified),
        label: Text(processing ? 'Processing...' : 'Confirm Payment Received'),
      ),
    );
  }
}
