import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/empty_state_widget.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import '../providers/table_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // 1. Skeleton matching DashboardHeader
          _buildHeaderSkeleton(),

          // 2. Skeleton matching LocationHeader
          _buildLocationHeaderSkeleton(),

          // 3. Grid of Skeleton Cards matching TableGrid & EnhancedTableCard
          const Expanded(
            child: TableGridSkeleton(),
          ),
        ],
      ),
    );
  }

  /// Skeleton matching DashboardHeader
  Widget _buildHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: const SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Skeleton menu button (36x36)
            SkeletonLoader.rectangular(
              width: 36,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            SizedBox(width: 12),
            // Skeleton title
            SkeletonLoader.rectangular(
              width: 140,
              height: 18,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            Spacer(),
            // Skeleton add button (36x36)
            SkeletonLoader.rectangular(
              width: 36,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton matching LocationHeader
  Widget _buildLocationHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 16, 12),
      color: Colors.white,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader.rectangular(
                  width: 140,
                  height: 18,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 5),
                SkeletonLoader.rectangular(
                  width: 95,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Skeleton filter dropdown pill
          SkeletonLoader.rectangular(
            width: 95,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton grid for table cards, matching TableGrid geometry
class TableGridSkeleton extends StatelessWidget {
  final int itemCount;

  const TableGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.25,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return buildTableCardSkeleton();
      },
    );
  }

  /// Skeleton matching EnhancedTableCard
  static Widget buildTableCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          final avatar = (h * 0.30).clamp(32.0, 48.0);
          final gap = (h * 0.022).clamp(2.0, 4.0);
          final compact = h < 132;

          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: compact ? 3 : 5,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skeleton circular icon container
                  SkeletonLoader.circular(size: avatar),
                  SizedBox(height: gap),
                  // Skeleton table name
                  SkeletonLoader.rectangular(
                    width: (w * 0.45).clamp(50.0, 75.0),
                    height: (h * 0.10).clamp(11.0, 14.0),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  SizedBox(height: (gap * 0.8).clamp(2.0, 3.5)),
                  // Skeleton capacity text
                  SkeletonLoader.rectangular(
                    width: (w * 0.52).clamp(60.0, 85.0),
                    height: (h * 0.08).clamp(9.0, 11.5),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  SizedBox(height: gap),
                  // Skeleton status badge pill
                  SkeletonLoader.rectangular(
                    width: (w * 0.42).clamp(52.0, 70.0),
                    height: (h * 0.12).clamp(14.0, 18.0),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DashboardErrorState extends StatelessWidget {
  final TableProvider tableProvider;

  const DashboardErrorState({super.key, required this.tableProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundEnd,
      body: Center(
        child: EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: AppStrings.dashboard.errorLoadingTables,
          description: tableProvider.error ?? 'Unknown error occurred',
          action: ElevatedButton.icon(
            onPressed: () {
              tableProvider.clearError();
              tableProvider.fetchTables();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              AppStrings.retry,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  final String selectedLocation;
  final VoidCallback onChangeLocation;

  const DashboardEmptyState({
    super.key,
    required this.selectedLocation,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyStateWidget(
        icon: Icons.table_restaurant_outlined,
        title: AppStrings.dashboard.noTablesFound,
        description:
            'We couldn\'t find any tables registered for $selectedLocation.',
        action: ElevatedButton.icon(
          onPressed: onChangeLocation,
          icon: const Icon(Icons.location_on, size: 16),
          label: Text(AppStrings.dashboard.changeLocation),
        ),
      ),
    );
  }
}
