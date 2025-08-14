// lib/shared/widgets/layout/location_header.dart
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/table.dart' hide TableStatus;
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
      padding: const EdgeInsets.all(12), // ✅ REDUCED from 16
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(locationData.icon, color: locationData.color, size: 20), // ✅ REDUCED from 24
          const SizedBox(width: 8), // ✅ REDUCED from 12
          Text(
            selectedLocation,
            style: const TextStyle(
              fontSize: 18, // ✅ REDUCED from 20
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // ✅ REDUCED from 12,6
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14), // ✅ REDUCED from 16
            ),
            child: Text(
              '$occupiedCount/$totalCount Occupied',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11, // ✅ REDUCED from 12
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
