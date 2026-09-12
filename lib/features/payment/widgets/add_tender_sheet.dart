import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import '../models/tender_line.dart';
import 'qr_section.dart';

/// Captures one tender — mode, amount, and for cash the notes handed over.
///
/// Opened per payment rather than per bill, so a bill can be split across
/// cash and UPI without leaving the payment screen.
class AddTenderSheet extends StatefulWidget {
  /// What is still owed. Card and UPI are capped at this: overcharging a card
  /// and handing back cash is not something a counter should be able to do by
  /// accident. Cash may exceed it, which is how change arises.
  final double remaining;

  /// Shown on the UPI QR so the customer can match it to their order.
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
      builder:
          (_) => AddTenderSheet(
            remaining: remaining,
            orderNumber: orderNumber,
          ),
    );
  }

  @override
  State<AddTenderSheet> createState() => _AddTenderSheetState();
}

class _AddTenderSheetState extends State<AddTenderSheet> {
  String _method = 'cash';
  late final TextEditingController _amountController;
  final TextEditingController _refController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default to clearing the balance — the common case is one tender for the
    // whole bill, and the cashier edits it down only when splitting.
    _amountController = TextEditingController(
      text: widget.remaining > 0 ? widget.remaining.toStringAsFixed(2) : '',
    );
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

  /// For cash, the amount field is what the customer handed over; anything
  /// above the balance comes back as change rather than overpaying the bill.
  double get _appliedAmount {
    if (_method != 'cash') return _amount;
    return _amount > widget.remaining ? widget.remaining : _amount;
  }

  double get _change =>
      _method == 'cash' && _amount > widget.remaining
          ? _amount - widget.remaining
          : 0;

  void _submit() async {
    final amount = _amount;
    if (amount <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    if (_method != 'cash' && amount > widget.remaining + 0.004) {
      setState(
        () =>
            _error =
                'Cannot exceed ${CurrencyConstants.symbol}'
                '${widget.remaining.toStringAsFixed(2)} on ${_method.toUpperCase()}',
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        // The UPI QR makes this sheet tall; with a keyboard up on a short
        // screen it must scroll rather than overflow.
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Add payment',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${CurrencyConstants.symbol}${widget.remaining.toStringAsFixed(2)} due',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _methodTile('cash', 'Cash', Icons.payments_rounded),
                const SizedBox(width: 8),
                _methodTile('card', 'Card', Icons.credit_card_rounded),
                const SizedBox(width: 8),
                _methodTile('upi', 'UPI', Icons.qr_code_rounded),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText:
                    _method == 'cash' ? 'Cash handed over' : 'Amount',
                prefixText: '${CurrencyConstants.symbol} ',
                errorText: _error,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // The customer scans while the cashier keys in the amount, so the
            // code belongs here rather than back on the payment screen.
            if (_method == 'upi') ...[
              const SizedBox(height: 12),
              QRSection(
                amount: _amount > 0 ? _amount : widget.remaining,
                orderNumber: widget.orderNumber,
              ),
            ],

            if (_method != 'cash') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _refController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Reference / txn no. (optional)',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            if (_change > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.currency_exchange_rounded,
                    size: 15,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Change to return '
                    '${CurrencyConstants.symbol}${_change.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Add'),
                  ),
                ),
              ],
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
            // Card and UPI cannot exceed the balance, so trim an amount that
            // was valid for cash when switching away from it.
            if (value != 'cash' && _amount > widget.remaining) {
              _amountController.text = widget.remaining.toStringAsFixed(2);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
