import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'payment_status_illustration.dart';

class PaymentBreakdownCard extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final PaymentStatusState status;

  const PaymentBreakdownCard({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      PaymentStatusState.pending => const Color(0xFFE11D48),
      PaymentStatusState.partiallyPaid => const Color(0xFFD97706),
      PaymentStatusState.paidInFull => const Color(0xFF16A34A),
    };

    final dueIcon = switch (status) {
      PaymentStatusState.pending => Icons.assignment_late_outlined,
      PaymentStatusState.partiallyPaid => Icons.assignment_late_outlined,
      PaymentStatusState.paidInFull => Icons.check_circle_outline_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // Row 1: Total Amount
          _buildRow(
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF64748B),
            label: 'Total Amount',
            labelColor: const Color(0xFF475569),
            value: totalAmount.toCurrency(),
            valueColor: const Color(0xFF0F172A),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Row 2: Amount Paid
          _buildRow(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF64748B),
            label: 'Amount Paid',
            labelColor: const Color(0xFF475569),
            value: paidAmount.toCurrency(),
            valueColor: const Color(0xFF0F172A),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Row 3: Amount Due
          _buildRow(
            icon: dueIcon,
            iconColor: statusColor,
            label: 'Amount Due',
            labelColor: statusColor,
            labelFontWeight: FontWeight.w700,
            value: remainingAmount.toCurrency(),
            valueColor: statusColor,
            valueFontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    FontWeight labelFontWeight = FontWeight.w500,
    required String value,
    required Color valueColor,
    FontWeight valueFontWeight = FontWeight.w700,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: labelFontWeight,
            color: labelColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueFontWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
