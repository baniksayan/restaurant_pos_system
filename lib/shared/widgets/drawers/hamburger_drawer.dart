// lib/shared/widgets/layout/location_header.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../presentation/view_models/providers/dashboard_provider.dart';
import '../../../presentation/view_models/providers/table_provider.dart';
import '../../../data/models/restaurant_table.dart';

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
                        selectedLocation.isEmpty
                            ? 'All Tables'
                            : selectedLocation,
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Dynamic status filter dropdown on the right top
          _buildFilterDropdown(context),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final allTables = Provider.of<TableProvider>(context, listen: false).tables;

    // Get all tables for this location to compute counts and unique statuses
    final locationTables =
        allTables.where((t) => t.location == selectedLocation).toList();

    // Get unique statuses dynamically from the location tables list
    final uniqueStatuses = locationTables.map((t) => t.status).toSet().toList();

    return PopupMenuButton<String>(
      initialValue: dashboardProvider.selectedStatusFilter,
      onSelected: (String status) {
        dashboardProvider.changeStatusFilter(status);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      elevation: 8,
      offset: const Offset(0, 38),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Slate 100
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2), // Slate 200
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              _getStatusFilterDisplayName(
                dashboardProvider.selectedStatusFilter,
              ),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return [
          // 'All' option
          PopupMenuItem<String>(
            value: 'all',
            height: 38,
            child: Row(
              children: [
                const Icon(Icons.all_inclusive_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                const Text(
                  'All Statuses',
                  style: TextStyle(
                    fontSize: 13.5, 
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${locationTables.length}',
                    style: const TextStyle(
                      fontSize: 10.5, 
                      fontWeight: FontWeight.w700, 
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...uniqueStatuses.map((status) {
            final count =
                locationTables.where((t) => t.status == status).length;
            final filterVal = _getFilterValue(status);
            return PopupMenuItem<String>(
              value: filterVal,
              height: 38,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(status).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getStatusDisplayName(status),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10.5, 
                        fontWeight: FontWeight.w700, 
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF10B981); // Emerald
      case TableStatus.occupied:
        return const Color(0xFFEF4444); // Red
      case TableStatus.kotGenerated:
        return AppColors.kotStatus; // Purple (0xFF8B5CF6)
      case TableStatus.billGenerated:
        return const Color(0xFF3B82F6); // Blue
      case TableStatus.billSettled:
        return const Color(0xFF06B6D4); // Cyan
      case TableStatus.reserved:
        return const Color(0xFFF59E0B); // Amber
      case TableStatus.outOfOrder:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.kotGenerated:
        return 'KOT Generated';
      case TableStatus.billGenerated:
        return 'Bill Generated';
      case TableStatus.billSettled:
        return 'Bill Settled';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.outOfOrder:
        return 'Out of Order';
    }
  }

  String _getStatusFilterDisplayName(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return 'All Statuses';
      case 'available':
        return 'Available';
      case 'occupied':
        return 'Occupied';
      case 'kot_generated':
      case 'kotgenerated':
        return 'KOT Generated';
      case 'bill_generated':
      case 'billgenerated':
        return 'Bill Generated';
      case 'bill_settled':
      case 'billsettled':
        return 'Bill Settled';
      case 'reserved':
        return 'Reserved';
      case 'out_of_order':
      case 'outoforder':
        return 'Out of Order';
      default:
        return filter;
    }
  }

  String _getFilterValue(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return 'available';
      case TableStatus.occupied:
        return 'occupied';
      case TableStatus.kotGenerated:
        return 'kot_generated';
      case TableStatus.billGenerated:
        return 'bill_generated';
      case TableStatus.billSettled:
        return 'bill_settled';
      case TableStatus.reserved:
        return 'reserved';
      case TableStatus.outOfOrder:
        return 'out_of_order';
    }
  }

  IconData _getLocationIcon() {
    if (selectedLocation.isEmpty) return Icons.all_inclusive;

    // Safe access to locations list
    if (locations.isNotEmpty) {
      try {
        final location = locations.firstWhere(
          (loc) => loc.name == selectedLocation,
          orElse:
              () => LocationSection('Default', Icons.location_on, Colors.grey),
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
