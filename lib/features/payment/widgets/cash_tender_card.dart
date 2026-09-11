import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/shared/widgets/forms/custom_text_field.dart';

/// Cash-tender entry shown when the "Cash" payment method is selected.
///
/// Lets the cashier record what the customer actually handed over and shows
/// the change owed back live, computed from [dueAmount]. The confirmed
/// [PaymentDetail.returnAmt] sent to `SavePayment`/`createBill` is derived
/// from this — see [PaymentPage._processPayment].
class CashTenderCard extends StatelessWidget {
  final double dueAmount;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const CashTenderCard({
    super.key,
    required this.dueAmount,
    required this.controller,
    required this.onChanged,
  });

  double? get _received {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get _isShort {
    final received = _received;
    if (received == null) return false;
    return received < dueAmount;
  }

  double get _change {
    final received = _received;
    if (received == null) return 0;
    final diff = received - dueAmount;
    return diff > 0 ? diff : 0;
  }

  List<double> _quickAmounts() {
    final amounts = <double>{dueAmount};
    for (final note in const [50.0, 100.0, 200.0, 500.0, 1000.0]) {
      if (note >= dueAmount) {
        amounts.add(note);
      }
      if (amounts.length >= 4) break;
    }
    return amounts.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 20,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.payment.cashReceived,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: controller,
            hintText: AppStrings.payment.cashReceivedHint,
            prefixText: '${CurrencyConstants.symbol} ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _quickAmounts().map((amount) {
                  final isExact = amount == dueAmount;
                  return _QuickAmountChip(
                    label:
                        isExact
                            ? AppStrings.payment.exactAmount
                            : CurrencyConstants.format(amount),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.text = amount.toStringAsFixed(2);
                      onChanged();
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  _isShort
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isShort
                      ? AppStrings.payment.cashShortBy
                      : AppStrings.payment.changeToReturn,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _isShort ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
                Text(
                  CurrencyConstants.format(
                    _isShort ? (dueAmount - (_received ?? 0)) : _change,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _isShort ? AppColors.error : AppColors.success,
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

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAmountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
