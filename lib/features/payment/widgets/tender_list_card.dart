import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import '../models/tender_line.dart';

class TenderListCard extends StatelessWidget {
  final List<TenderLine> tenders;
  final double billTotal;
  final double previouslyPaid;
  final ValueChanged<int>? onRemove;
  final VoidCallback? onAddAnotherPayment;
  final bool isFullySettled;

  const TenderListCard({
    super.key,
    required this.tenders,
    required this.billTotal,
    required this.previouslyPaid,
    this.onRemove,
    this.onAddAnotherPayment,
    this.isFullySettled = false,
  });

  int get totalCount =>
      tenders.length + (previouslyPaid > 0.004 ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Payments ($totalCount)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),

        if (totalCount == 0)
          // Empty State Card with prominent Add Payment action
          _buildEmptyState()
        else
          // Payments List
          Column(
            children: [
              // Previously Paid Row (if any)
              if (previouslyPaid > 0.004)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPaymentTile(
                    method: 'Previous Payment',
                    timestamp: 'Settled Earlier',
                    amount: previouslyPaid,
                    icon: Icons.check_circle_outline_rounded,
                    iconBgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    canRemove: false,
                  ),
                ),

              // Staged Tenders
              for (int i = 0; i < tenders.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTenderTile(tenders[i], i),
                ),

              // Add Another Payment Button (Shown when not fully settled)
              if (!isFullySettled && onAddAnotherPayment != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: onAddAnotherPayment,
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Color(0xFF6366F1),
                      ),
                      label: const Text(
                        'Add Another Payment',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F3FF),
                        side: const BorderSide(
                          color: Color(0xFFDDD6FE),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: onAddAnotherPayment,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 22,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No payments added yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add a payment to settle this order.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAddAnotherPayment != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: onAddAnotherPayment,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text(
                    'Add Payment',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTenderTile(TenderLine tender, int index) {
    final (icon, iconBgColor, iconColor) = switch (tender.method) {
      'cash' => (
          Icons.payments_rounded,
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
        ),
      'card' => (
          Icons.credit_card_rounded,
          const Color(0xFFE0E7FF),
          const Color(0xFF4F46E5),
        ),
      'upi' => (
          Icons.qr_code_2_rounded,
          const Color(0xFFF3E8FF),
          const Color(0xFF9333EA),
        ),
      _ => (
          Icons.payment_rounded,
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        ),
    };

    return _buildPaymentTile(
      method: tender.label,
      timestamp: tender.formattedTime,
      amount: tender.amount,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      canRemove: onRemove != null,
      onDelete: onRemove != null ? () => onRemove!(index) : null,
    );
  }

  Widget _buildPaymentTile({
    required String method,
    required String timestamp,
    required double amount,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    bool canRemove = false,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Method & Timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  method,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            amount.toCurrency(),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),

          // If removable (staged tender), show a clean delete button.
          // Otherwise, if already settled, show a subtle checkmark (NO chevron '>').
          if (canRemove && onDelete != null)
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: Color(0xFFDC2626),
                ),
              ),
            )
          else
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Color(0xFF16A34A),
            ),
        ],
      ),
    );
  }
}
