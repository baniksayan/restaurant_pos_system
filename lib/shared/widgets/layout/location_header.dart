import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/table.dart';
import '../../../presentation/views/dashboard/waiter_dashboard_view.dart';

class LocationHeader extends StatelessWidget {
  final String selectedLocation;
  final List<LocationSection> locations;
  final List<RestaurantTable> tables;

  const LocationHeader({
    super.key,
    required this.selectedLocation,
    required this.locations,
    required this.tables,
  });

  @override
  Widget build(BuildContext context) {
    final locationData = locations.firstWhere(
      (loc) => loc.name == selectedLocation,
    );
    final occupiedCount = tables
        .where((t) => t.status == TableStatus.occupied)
        .length;
    final totalCount = tables.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(locationData.icon, color: locationData.color, size: 24),
          const SizedBox(width: 12),
          Text(
            selectedLocation,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$occupiedCount/$totalCount Occupied',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
