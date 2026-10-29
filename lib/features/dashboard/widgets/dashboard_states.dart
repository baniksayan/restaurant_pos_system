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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 1. Skeleton matching DashboardHeader
          _buildHeaderSkeleton(),

          // 2. Skeleton matching LocationHeader
          _buildLocationHeaderSkeleton(),

          // 3. Grid of Skeleton Cards matching TableGrid & EnhancedTableCard
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                return _buildTableCardSkeleton();
              },
            ),
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

  /// Skeleton matching EnhancedTableCard
  Widget _buildTableCardSkeleton() {
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
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Skeleton circular icon container (56x56)
            SkeletonLoader.circular(size: 56),
            SizedBox(height: 8),
            // Skeleton table name
            SkeletonLoader.rectangular(
              width: 75,
              height: 16,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            SizedBox(height: 5),
            // Skeleton capacity text
            SkeletonLoader.rectangular(
              width: 85,
              height: 12,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            SizedBox(height: 8),
            // Skeleton status badge pill
            SkeletonLoader.rectangular(
              width: 70,
              height: 20,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ],
        ),
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
