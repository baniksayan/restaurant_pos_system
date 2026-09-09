import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/cards/app_card.dart';

class BillDetailsCard extends StatelessWidget {
  final double subtotal;
  final double gstAmount;
  final double total;

  const BillDetailsCard({
    super.key,
    required this.subtotal,
    required this.gstAmount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Amount',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAmountRow(
            'Subtotal:',
            '${CurrencyConstants.symbol}${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildAmountRow(
            'GST (10%):',
            '${CurrencyConstants.symbol}${gstAmount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const SizedBox(height: 8),
          _buildAmountRow(
            'Total Amount:',
            '${CurrencyConstants.symbol}${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : Colors.black,
          ),
        ),
      ],
    );
  }
}
