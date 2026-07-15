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
      backgroundColor: AppColors.backgroundEnd,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const SkeletonLoader.circular(size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoader.rectangular(width: 120, height: 16),
                      const SizedBox(height: 6),
                      const SkeletonLoader.rectangular(width: 80, height: 12),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grid of Skeleton Cards
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SkeletonLoader.circular(size: 24),
                            const SkeletonLoader.rectangular(width: 50, height: 12),
                          ],
                        ),
                        const SkeletonLoader.rectangular(width: 100, height: 20),
                        const SkeletonLoader.rectangular(width: 70, height: 12),
                      ],
                    ),
                  );
                },
              ),
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

