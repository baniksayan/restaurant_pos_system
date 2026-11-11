import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import 'payment_status_illustration.dart';

class AmountCard extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final PaymentStatusState status;
  final bool isLoading;

  const AmountCard({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLoader.rectangular(
                  height: 18,
                  width: 120,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 10),
                SkeletonLoader.rectangular(
                  height: 32,
                  width: 140,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 10),
                SkeletonLoader.rectangular(
                  height: 18,
                  width: 90,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
            SkeletonLoader.rectangular(
              height: 90,
              width: 90,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
      );
    }

    final gradientColors = switch (status) {
      PaymentStatusState.pending => const [
          Color(0xFFFFF1F2),
          Color(0xFFFFE4E6),
        ],
      PaymentStatusState.partiallyPaid => const [
          Color(0xFFFFFBEB),
          Color(0xFFFEF3C7),
        ],
      PaymentStatusState.paidInFull => const [
          Color(0xFFF0FDF4),
          Color(0xFFDCFCE7),
        ],
    };

    final borderColor = switch (status) {
      PaymentStatusState.pending => const Color(0xFFFECDD3),
      PaymentStatusState.partiallyPaid => const Color(0xFFFDE68A),
      PaymentStatusState.paidInFull => const Color(0xFFBBF7D0),
    };

    final shadowColor = switch (status) {
      PaymentStatusState.pending =>
        const Color(0xFFF43F5E).withValues(alpha: 0.10),
      PaymentStatusState.partiallyPaid =>
        const Color(0xFFF59E0B).withValues(alpha: 0.10),
      PaymentStatusState.paidInFull =>
        const Color(0xFF16A34A).withValues(alpha: 0.10),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Info Column
          Expanded(
            child: switch (status) {
              PaymentStatusState.pending => _buildPendingLeft(),
              PaymentStatusState.partiallyPaid => _buildPartiallyPaidLeft(),
              PaymentStatusState.paidInFull => _buildPaidInFullLeft(),
            },
          ),

          const SizedBox(width: 12),

          // Right Illustration
          PaymentStatusIllustration(
            status: status,
            size: 104,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pill: Hourglass + Payment Pending
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 16,
              color: Color(0xFFBE123C),
            ),
            SizedBox(width: 5),
            Text(
              'Payment Pending',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9F1239),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        // Big Amount
        Text(
          totalAmount.toCurrency(),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),

        // Pill: Amount Due
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE4E6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECDD3), width: 1),
          ),
          child: const Text(
            'Amount Due',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFBE123C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartiallyPaidLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pill: Coins + Partially Paid
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on_outlined,
              size: 17,
              color: Color(0xFFB45309),
            ),
            SizedBox(width: 5),
            Text(
              'Partially Paid',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF92400E),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        // Big Amount (Remaining Due)
        Text(
          remainingAmount.toCurrency(),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),

        // Pill: Remaining Due
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1),
          ),
          child: const Text(
            'Remaining Due',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaidInFullLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large Circular Checkmark Icon
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),

        // Title
        const Text(
          'Paid in Full',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),

        // Subtitle
        const Text(
          'Order amount settled',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF15803D),
          ),
        ),
      ],
    );
  }
}
