import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import '../../../view_models/providers/table_provider.dart';

class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading tables...',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardErrorState extends StatelessWidget {
  final TableProvider tableProvider;

  const DashboardErrorState({
    super.key,
    required this.tableProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error Loading Tables',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tableProvider.error ?? 'Unknown error occurred',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => tableProvider.clearError(),
                    child: const Text('Clear Error'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      tableProvider.clearError();
                      tableProvider.initializeTables();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Tables Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tables found for $selectedLocation',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onChangeLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Change Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
