import 'package:flutter/material.dart';
import '../../../../core/constants/currency_constants.dart';

class AmountCard extends StatelessWidget {
  final double amount;
  const AmountCard({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
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
