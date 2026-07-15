import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/currency_constants.dart';

class QRSection extends StatelessWidget {
  final double amount;
  final String orderNumber;

  const QRSection({
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
