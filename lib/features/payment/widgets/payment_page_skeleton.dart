import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';

/// Full-page shimmer skeleton matching the exact layout and hierarchy of [PaymentPage].
class PaymentPageSkeleton extends StatelessWidget {
  const PaymentPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 1. Top Hero Card Skeleton
          Container(
            height: 140,
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBone(
                      width: 125,
                      height: 18,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 10),
                    ShimmerBone(
                      width: 150,
                      height: 32,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 10),
                    ShimmerBone(
                      width: 85,
                      height: 18,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
                ShimmerBone(
                  width: 96,
                  height: 96,
                  borderRadius: BorderRadius.circular(18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Breakdown Card Skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBone(
                      width: 100,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    ShimmerBone(
                      width: 65,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBone(
                      width: 95,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    ShimmerBone(
                      width: 55,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBone(
                      width: 90,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    ShimmerBone(
                      width: 65,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Payments Section Skeleton
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBone(
                width: 110,
                height: 18,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerBone(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 10),
                      ShimmerBone(
                        width: 140,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
