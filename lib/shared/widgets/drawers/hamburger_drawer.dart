// lib/shared/widgets/drawers/hamburger_drawer.dart

import 'dart:ui';
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

    return InkWell(
      onTap: () => _showStatusFilterDialog(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Slate 100
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ), // Slate 200
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list_rounded,
              size: 15,
              color: AppColors.primary,
            ),
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
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilterDialog(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final allTables = Provider.of<TableProvider>(context, listen: false).tables;

    final locationTables =
        allTables.where((t) => t.location == selectedLocation).toList();

    final uniqueStatuses = locationTables.map((t) => t.status).toSet().toList();

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final maxWidth = size.width < 480 ? size.width * 0.92 : 380.0;

        return Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogContext).maybePop(),
            child: Stack(
              children: [
                // Fullscreen Glassmorphism Blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: GestureDetector(
                          onTap:
                              () {}, // Prevent backdrop tap from dismissing dialog
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.52),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        16,
                                        16,
                                        16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.filter_list_rounded,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Filter by Status',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                Text(
                                                  'Select table status to filter view',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                            ),
                                            onPressed:
                                                () => Navigator.pop(
                                                  dialogContext,
                                                ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black
                                                  .withValues(alpha: 0.05),
                                              foregroundColor:
                                                  AppColors.textSecondary,
                                              padding: const EdgeInsets.all(8),
                                              minimumSize: const Size(32, 32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Items List
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          // All Statuses item
                                          _buildStatusFilterItem(
                                            context: dialogContext,
                                            dashboardProvider:
                                                dashboardProvider,
                                            value: 'all',
                                            displayName: 'All Statuses',
                                            count: locationTables.length,
                                            icon: Icons.all_inclusive_rounded,
                                            iconColor: AppColors.primary,
                                          ),
                                          const SizedBox(height: 8),

                                          // Dynamic statuses items
                                          ...uniqueStatuses.map((status) {
                                            final count =
                                                locationTables
                                                    .where(
                                                      (t) => t.status == status,
                                                    )
                                                    .length;
                                            final filterVal = _getFilterValue(
                                              status,
                                            );
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: _buildStatusFilterItem(
                                                context: dialogContext,
                                                dashboardProvider:
                                                    dashboardProvider,
                                                value: filterVal,
                                                displayName:
                                                    _getStatusDisplayName(
                                                      status,
                                                    ),
                                                count: count,
                                                statusColor: _getStatusColor(
                                                  status,
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterItem({
    required BuildContext context,
    required DashboardProvider dashboardProvider,
    required String value,
    required String displayName,
    required int count,
    IconData? icon,
    Color? iconColor,
    Color? statusColor,
  }) {
    final isSelected =
        dashboardProvider.selectedStatusFilter.toLowerCase() ==
        value.toLowerCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          dashboardProvider.changeStatusFilter(value);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon, size: 18, color: iconColor ?? AppColors.primary)
              else if (statusColor != null)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count ${count == 1 ? 'table' : 'tables'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const Color(0xFF10B981); // Emerald
      case TableStatus.occupied:
        return const Color(0xFFEF4444); // Red
      case TableStatus.kotGenerated:
        return const Color.fromRGBO(139, 92, 246, 1); // Purple (0xFF8B5CF6)
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
