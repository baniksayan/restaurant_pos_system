// lib/shared/widgets/layout/location_header.dart

import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../presentation/view_models/providers/dashboard_provider.dart';

class LocationHeader extends StatelessWidget {
  final String selectedLocation;
  final List<LocationSection> locations;
  final List tables;

  const LocationHeader({
    super.key,
    required this.selectedLocation,
    required this.locations,
    required this.tables,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Location info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getLocationIcon(),
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        selectedLocation.isEmpty ? 'All Tables' : selectedLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${tables.length} ${tables.length == 1 ? 'table' : 'tables'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Table status summary
          _buildTableStatusSummary(),
        ],
      ),
    );
  }

  Widget _buildTableStatusSummary() {
    if (tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No tables',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Count tables by status safely
    final availableCount = _countTablesByStatus('available');
    final occupiedCount = _countTablesByStatus('occupied'); 
    final reservedCount = _countTablesByStatus('reserved');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (availableCount > 0) _buildStatusChip('${availableCount}A', Colors.green),
        if (occupiedCount > 0) ...[
          if (availableCount > 0) const SizedBox(width: 4),
          _buildStatusChip('${occupiedCount}O', Colors.red),
        ],
        if (reservedCount > 0) ...[
          if (availableCount > 0 || occupiedCount > 0) const SizedBox(width: 4),
          _buildStatusChip('${reservedCount}R', Colors.orange),
        ],
      ],
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  int _countTablesByStatus(String status) {
    if (tables.isEmpty) return 0;
    
    try {
      return tables.where((table) {
        // Safe access to table status
        if (table?.status?.name != null) {
          return table.status.name.toLowerCase() == status.toLowerCase();
        }
        return false;
      }).length;
    } catch (e) {
      // If there's any error accessing table properties, return 0
      return 0;
    }
  }

  IconData _getLocationIcon() {
    if (selectedLocation.isEmpty) return Icons.all_inclusive;
    
    // Safe access to locations list
    if (locations.isNotEmpty) {
      try {
        final location = locations.firstWhere(
          (loc) => loc.name == selectedLocation,
          orElse: () => LocationSection('Default', Icons.location_on, Colors.grey),
        );
        return location.icon;
      } catch (e) {
        // If firstWhere fails, return default icon
        return Icons.location_on;
      }
    }
    
    return Icons.location_on;
  }
}
