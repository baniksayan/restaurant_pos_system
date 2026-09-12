import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import '../models/tender_line.dart';

/// The tenders taken so far against a bill, with the running balance.
///
/// A bill can be settled across several payment modes — cash plus UPI, say —
/// and the running totals are what let a cashier see, while they work, whether
/// the customer still owes anything or is due change.
class TenderListCard extends StatelessWidget {
  final List<TenderLine> tenders;
  final double billTotal;

  /// Already recorded against this bill on an earlier visit. Counts towards
  /// settling it, but cannot be removed here.
  final double previouslyPaid;

  final ValueChanged<int> onRemove;

  const TenderListCard({
    super.key,
    required this.tenders,
    required this.billTotal,
    required this.previouslyPaid,
    required this.onRemove,
  });

  double get _tenderedNow =>
      tenders.fold(0.0, (sum, t) => sum + t.amount);

  double get _totalPaid => previouslyPaid + _tenderedNow;

  double get _remaining {
    final left = billTotal - _totalPaid;
    return left > 0 ? left : 0;
  }

  double get _change => tenders.fold(0.0, (sum, t) => sum + t.returnAmount);

  @override
  Widget build(BuildContext context) {
    final settled = _remaining <= 0.004; // tolerate float dust on 2dp money

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              const Text(
                'Payments',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${CurrencyConstants.symbol}${billTotal.toStringAsFixed(2)} total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (previouslyPaid > 0) ...[
            const SizedBox(height: 10),
            _row(
              icon: Icons.history_rounded,
              label: 'Paid earlier',
              amount: previouslyPaid,
              muted: true,
            ),
          ],

          if (tenders.isEmpty && previouslyPaid <= 0) ...[
            const SizedBox(height: 12),
            const Text(
              'No payment added yet',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          for (var i = 0; i < tenders.length; i++) ...[
            const SizedBox(height: 8),
            _row(
              icon: _iconFor(tenders[i].method),
              label: tenders[i].label,
              amount: tenders[i].amount,
              sub:
                  tenders[i].returnAmount > 0
                      ? 'tendered ${CurrencyConstants.symbol}'
                          '${tenders[i].cashTendered.toStringAsFixed(2)}'
                      : (tenders[i].refId.isNotEmpty
                          ? 'ref ${tenders[i].refId}'
                          : null),
              onRemove: () => onRemove(i),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          _summary('Paid', _totalPaid, bold: true),
          const SizedBox(height: 4),
          if (settled && _change > 0)
            _summary('Change to return', _change, tone: AppColors.success)
          else
            _summary(
              settled ? 'Fully settled' : 'Remaining',
              settled ? 0 : _remaining,
              tone: settled ? AppColors.success : AppColors.warning,
              hideAmount: settled,
              bold: true,
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String method) => switch (method) {
    'cash' => Icons.payments_rounded,
    'card' => Icons.credit_card_rounded,
    'upi' => Icons.qr_code_rounded,
    _ => Icons.payment_rounded,
  };

  Widget _row({
    required IconData icon,
    required String label,
    required double amount,
    String? sub,
    bool muted = false,
    VoidCallback? onRemove,
  }) {
    final tone = muted ? AppColors.textHint : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 15, color: muted ? AppColors.textHint : AppColors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tone,
                ),
              ),
              if (sub != null)
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        Text(
          '${CurrencyConstants.symbol}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: tone,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (onRemove != null)
          IconButton(
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.only(left: 6),
            constraints: const BoxConstraints(),
            tooltip: 'Remove $label payment',
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
          ),
      ],
    );
  }

  Widget _summary(
    String label,
    double amount, {
    Color? tone,
    bool bold = false,
    bool hideAmount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: tone ?? AppColors.textSecondary,
          ),
        ),
        if (!hideAmount)
          Text(
            '${CurrencyConstants.symbol}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: tone ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}
