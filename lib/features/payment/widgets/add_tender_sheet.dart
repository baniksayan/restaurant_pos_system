import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';
import '../models/tender_line.dart';
import '../services/upi_storage_service.dart';

/// Captures one tender — mode, amount, and reference details.
/// Matches Scenario 3 ("Add Payment" modal sheet).
class AddTenderSheet extends StatefulWidget {
  final double remaining;
  final String orderNumber;

  const AddTenderSheet({
    super.key,
    required this.remaining,
    this.orderNumber = '',
  });

  static Future<TenderLine?> show(
    BuildContext context,
    double remaining, {
    String orderNumber = '',
  }) {
    return showModalBottomSheet<TenderLine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTenderSheet(
        remaining: remaining,
        orderNumber: orderNumber,
      ),
    );
  }

  @override
  State<AddTenderSheet> createState() => _AddTenderSheetState();
}

class _AddTenderSheetState extends State<AddTenderSheet> {
  String _method = 'upi'; // Defaults to UPI or cash
  late final TextEditingController _amountController;
  final TextEditingController _refController = TextEditingController();
  String? _error;
  String _upiId = UpiStorageService.defaultUpiId;
  String _merchantName = UpiStorageService.defaultMerchantName;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.remaining > 0 ? widget.remaining.toStringAsFixed(2) : '',
    );
    _loadStoredUpi();
  }

  Future<void> _loadStoredUpi() async {
    final upi = await UpiStorageService.getUpiId();
    final merchant = await UpiStorageService.getMerchantName();
    if (mounted) {
      setState(() {
        _upiId = upi;
        _merchantName = merchant;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  int get _modeId => switch (_method) {
        'cash' => 1,
        'card' => 2,
        'upi' => 3,
        _ => 1,
      };

  double get _appliedAmount {
    if (_method != 'cash') return _amount;
    return _amount > widget.remaining ? widget.remaining : _amount;
  }

  double get _change =>
      _method == 'cash' && _amount > widget.remaining
          ? _amount - widget.remaining
          : 0;

  String _generateUpiUri() {
    final effectiveAmount = _amount > 0 ? _amount : widget.remaining;
    final encodedMerchant = Uri.encodeComponent(_merchantName);
    final encodedNote = Uri.encodeComponent(
      widget.orderNumber.isNotEmpty
          ? 'Order ${widget.orderNumber}'
          : 'Restaurant Order',
    );
    return 'upi://pay?pa=$_upiId&pn=$encodedMerchant&am=${effectiveAmount.toStringAsFixed(2)}&cu=INR&tn=$encodedNote';
  }

  void _submit() async {
    final amount = _amount;
    if (amount <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    if (_method != 'cash' && amount > widget.remaining + 0.004) {
      setState(
        () => _error =
            'Cannot exceed ${widget.remaining.toCurrency()} on ${_method.toUpperCase()}',
      );
      return;
    }

    await HapticHelper.triggerFeedback();
    if (!mounted) return;

    Navigator.of(context).pop(
      TenderLine(
        modeId: _modeId,
        method: _method,
        amount: _appliedAmount,
        refId: _refController.text.trim(),
        cashTendered: _method == 'cash' ? amount : 0,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row
              Row(
                children: [
                  const Text(
                    'Add Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Remaining Due Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECDD3), width: 1),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Remaining Due',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.remaining.toCurrency(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Selectors (Cash, Card, UPI)
              Row(
                children: [
                  _methodTile('cash', 'Cash', Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 10),
                  _methodTile('card', 'Card', Icons.credit_card_rounded),
                  const SizedBox(width: 10),
                  _methodTile('upi', 'UPI', Icons.qr_code_2_rounded),
                ],
              ),
              const SizedBox(height: 16),

              // UPI Section
              if (_method == 'upi') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '✦ Scan & Pay using UPI ✦',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4338CA),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // QR Code Container
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _generateUpiUri(),
                          version: QrVersions.auto,
                          size: 160,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF4338CA),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // UPI ID pill with copy
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _upiId));
                          HapticHelper.triggerFeedback();
                          AppSnackBar.showSuccess(context, 'UPI ID copied: $_upiId');
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'UPI ID: $_upiId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Amount Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() => _error = null),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      prefixText: '${CurrencyConstants.symbol} ',
                      prefixStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      errorText: _error,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4F46E5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reference / txn no. field
              TextField(
                controller: _refController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                  hintText: 'Reference / txn no. (optional)',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4F46E5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Change to return (for Cash)
              if (_change > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.currency_exchange_rounded,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Change to return: ${_change.toCurrency()}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Full Width Add Payment Button
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text(
                    'Add Payment',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodTile(String value, String label, IconData icon) {
    final selected = _method == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _method = value;
            _error = null;
          });
          HapticHelper.triggerFeedback();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
              width: selected ? 1.6 : 1.2,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),

              // Selected Checkmark Badge (top-right)
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
