import 'package:flutter/material.dart';

class PaymentMethods extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const PaymentMethods({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget item({
      required String value,
      required String title,
      required String subtitle,
      required IconData icon,
    }) {
      final isSelected = selected == value;
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary.withValues(alpha: 0.06) : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? cs.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? cs.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        item(
          value: 'cash',
          title: 'Cash',
          subtitle: 'Pay with physical cash to waiter',
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 10),
        item(
          value: 'card',
          title: 'Card',
          subtitle: 'Debit/Credit card or contactless payment',
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 10),
        item(
          value: 'upi',
          title: 'UPI',
          subtitle: 'Scan QR with any UPI app',
          icon: Icons.qr_code_2,
        ),
      ],
    );
  }
}
