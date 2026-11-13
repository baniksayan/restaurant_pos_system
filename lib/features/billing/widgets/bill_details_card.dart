import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/cards/app_breakdown_card.dart';

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
    return AppBreakdownCard(
      title: 'Bill Amount',
      items: [
        AppBreakdownItem(
          label: 'Subtotal:',
          value: subtotal.toCurrency(),
        ),
        AppBreakdownItem(
          label: 'GST (10%):',
          value: gstAmount.toCurrency(),
        ),
        const AppBreakdownItem.divider(),
        AppBreakdownItem(
          label: 'Total Amount:',
          value: total.toCurrency(),
          color: AppColors.primary,
          isHighlighted: true,
        ),
      ],
    );
  }
}
