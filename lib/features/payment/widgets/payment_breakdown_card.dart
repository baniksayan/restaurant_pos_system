// lib/features/payment/widgets/payment_breakdown_card.dart

import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/shared/widgets/cards/app_breakdown_card.dart';
import 'payment_status_illustration.dart';

/// Card displaying the 3-metric payment breakdown:
/// - Total Amount
/// - Amount Paid
/// - Amount Due / Remaining
/// - Optional Return to Customer (for cash tenders)
/// Standardized using [AppBreakdownCard].
class PaymentBreakdownCard extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final PaymentStatusState status;
  final double returnAmount;

  const PaymentBreakdownCard({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    this.returnAmount = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      PaymentStatusState.pending => AppColors.error,
      PaymentStatusState.partiallyPaid => AppColors.warning,
      PaymentStatusState.paidInFull => AppColors.success,
    };

    final dueIcon = switch (status) {
      PaymentStatusState.pending => Icons.assignment_late_outlined,
      PaymentStatusState.partiallyPaid => Icons.assignment_late_outlined,
      PaymentStatusState.paidInFull => Icons.check_circle_outline_rounded,
    };

    return AppBreakdownCard(
      items: [
        AppBreakdownItem(
          icon: Icons.receipt_long_outlined,
          label: 'Total Amount',
          value: totalAmount.toCurrency(),
        ),
        const AppBreakdownItem.divider(),
        AppBreakdownItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Amount Paid',
          value: paidAmount.toCurrency(),
        ),
        const AppBreakdownItem.divider(),
        AppBreakdownItem(
          icon: dueIcon,
          color: statusColor,
          label: 'Amount Due',
          value: remainingAmount.toCurrency(),
          isHighlighted: true,
        ),
        if (returnAmount > 0.004) ...[
          const AppBreakdownItem.divider(),
          AppBreakdownItem(
            icon: Icons.currency_exchange_rounded,
            color: AppColors.success,
            label: 'Return to Customer',
            value: returnAmount.toCurrency(),
            isHighlighted: true,
          ),
        ],
      ],
    );
  }
}
