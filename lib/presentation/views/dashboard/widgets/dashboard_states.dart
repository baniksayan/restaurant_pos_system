import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/empty_state_widget.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import '../../../view_models/providers/table_provider.dart';

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
              padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        bottom: false,
        child: Row(
          children: const [
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    SkeletonLoader.rectangular(
                      width: 16,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    SizedBox(width: 6),
                    SkeletonLoader.rectangular(
                      width: 90,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                SkeletonLoader.rectangular(
                  width: 55,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
          // Skeleton filter dropdown pill
          const SkeletonLoader.rectangular(
            width: 110,
            height: 30,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // Skeleton icon container (40x40)
            SkeletonLoader.rectangular(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            SizedBox(height: 8),
            // Skeleton table name
            SkeletonLoader.rectangular(
              width: 70,
              height: 18,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            SizedBox(height: 6),
            // Skeleton capacity text
            SkeletonLoader.rectangular(
              width: 80,
              height: 12,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            SizedBox(height: 8),
            // Skeleton status badge pill
            SkeletonLoader.rectangular(
              width: 65,
              height: 18,
              borderRadius: BorderRadius.all(Radius.circular(10)),
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
          title: 'Error Loading Tables',
          description: tableProvider.error ?? 'Unknown error occurred',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => tableProvider.clearError(),
                child: const Text('Clear Error'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  tableProvider.clearError();
                  tableProvider.fetchTables();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
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
        title: 'No Tables Found',
        description: 'We couldn\'t find any tables registered for $selectedLocation.',
        action: ElevatedButton.icon(
          onPressed: onChangeLocation,
          icon: const Icon(Icons.location_on, size: 16),
          label: const Text('Change Location'),
        ),
      ),
    );
  }
}

