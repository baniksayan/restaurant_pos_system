import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';

/// A dynamic, responsive skeleton loader for WhizEats KDS screens across all tabs.
/// Adapts seamlessly between mobile (single column list) and tablet/POS (multi-column grid).
class ChefOrderSkeletonView extends StatelessWidget {
  final int itemCount;
  final ScrollPhysics physics;

  const ChefOrderSkeletonView({
    super.key,
    this.itemCount = 6,
    this.physics = const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          int crossAxisCount = 1;
          if (width >= 1300) {
            crossAxisCount = 4;
          } else if (width >= 900) {
            crossAxisCount = 3;
          } else if (width >= 600) {
            crossAxisCount = 2;
          }

          if (crossAxisCount == 1) {
            return ListView.separated(
              physics: physics,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return ChefOrderCardSkeleton(index: index);
              },
            );
          }

          return GridView.builder(
            physics: physics,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 330,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return ChefOrderCardSkeleton(index: index);
            },
          );
        },
      ),
    );
  }
}

/// A pixel-perfect skeleton placeholder precisely replicating the visual structure of [ChefOrderCard],
/// including 2-tier header, table badge, time indicator, status pill, item rows with note chips & thumbnails,
/// and bottom action button.
class ChefOrderCardSkeleton extends StatelessWidget {
  final int index;

  const ChefOrderCardSkeleton({
    super.key,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Vary geometry based on card index to create realistic, non-robotic skeleton patterns
    final pattern = index % 4;

    final tableWidth = switch (pattern) {
      0 => 46.0,
      1 => 54.0,
      2 => 40.0,
      _ => 50.0,
    };

    final kotWidth = switch (pattern) {
      0 => 140.0,
      1 => 120.0,
      2 => 155.0,
      _ => 130.0,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: 2-Tier responsive skeleton layout
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier 1: Table Badge on Left, Time Ago & Status Badge on Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Table badge skeleton matching live UI
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShimmerBone.circular(
                              size: 11,
                              color: AppColors.primaryDark.withValues(alpha: 0.35),
                            ),
                            const SizedBox(width: 4),
                            ShimmerBone.rectangular(
                              width: tableWidth,
                              height: 11,
                              borderRadius: BorderRadius.circular(3),
                              color: AppColors.primaryDark.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Time Ago + Status badge skeleton
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShimmerBone.circular(
                            size: 12,
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          ShimmerBone.rectangular(
                            width: 38,
                            height: 11,
                            borderRadius: BorderRadius.circular(3),
                            color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ShimmerBone.rectangular(
                              width: 50,
                              height: 11,
                              borderRadius: BorderRadius.circular(3),
                              color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Tier 2: Receipt icon + KOT ticket number bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ShimmerBone.rectangular(
                        width: 14,
                        height: 14,
                        borderRadius: BorderRadius.circular(3),
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      ShimmerBone.rectangular(
                        width: kotWidth,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.textPrimary.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body: Food Items Skeleton List with realistic variations
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Build varied item configurations
                  if (pattern == 0) ...[
                    _buildItemRowSkeleton(
                      titleWidth: 150,
                      hasNote: true,
                      noteWidth: 95,
                    ),
                    const SizedBox(height: 2),
                    _buildItemRowSkeleton(
                      titleWidth: 115,
                      hasNote: false,
                    ),
                  ] else if (pattern == 1) ...[
                    _buildItemRowSkeleton(
                      titleWidth: 165,
                      hasNote: false,
                    ),
                    const SizedBox(height: 2),
                    _buildItemRowSkeleton(
                      titleWidth: 125,
                      hasNote: true,
                      noteWidth: 105,
                    ),
                    const SizedBox(height: 2),
                    _buildItemRowSkeleton(
                      titleWidth: 90,
                      hasNote: false,
                    ),
                  ] else if (pattern == 2) ...[
                    _buildItemRowSkeleton(
                      titleWidth: 140,
                      hasNote: false,
                    ),
                    const SizedBox(height: 2),
                    _buildItemRowSkeleton(
                      titleWidth: 160,
                      hasNote: false,
                    ),
                  ] else ...[
                    _buildItemRowSkeleton(
                      titleWidth: 135,
                      hasNote: true,
                      noteWidth: 85,
                    ),
                    const SizedBox(height: 2),
                    _buildItemRowSkeleton(
                      titleWidth: 145,
                      hasNote: false,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Bottom Action Button Skeleton
                  Container(
                    width: double.infinity,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerBone.circular(
                          size: 16,
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 8),
                        ShimmerBone.rectangular(
                          width: 110,
                          height: 13,
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRowSkeleton({
    required double titleWidth,
    required bool hasNote,
    double noteWidth = 90,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quantity Badge Skeleton matching ChefOrderItemTile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: ShimmerBone.rectangular(
              width: 14,
              height: 14,
              borderRadius: BorderRadius.circular(3),
              color: AppColors.primaryDark.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 10),

          // Item Title & Special Instructions Note Chip Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerBone.rectangular(
                  width: titleWidth,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFFCBD5E1),
                ),
                if (hasNote) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmerBone.circular(
                          size: 11,
                          color: const Color(0xFFD97706).withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 3.5),
                        ShimmerBone.rectangular(
                          width: noteWidth,
                          height: 9,
                          borderRadius: BorderRadius.circular(3),
                          color: const Color(0xFF92400E).withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Food Image Thumbnail Skeleton
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.restaurant_rounded,
                size: 20,
                color: const Color(0xFFCBD5E1).withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
