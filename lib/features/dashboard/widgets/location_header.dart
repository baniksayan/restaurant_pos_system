// lib/features/dashboard/widgets/location_header.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'location_selector_dialog.dart';
import '../providers/dashboard_provider.dart';
import '../providers/table_provider.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

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
    final availableCount =
        tables.where((t) => t.status == TableStatus.available).length;
    final totalCount = tables.length;
    final statsText = totalCount == 0
        ? 'No tables'
        : '$totalCount ${totalCount == 1 ? "table" : "tables"} • $availableCount free';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 16, 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Minimalist Premium Outlet Title & Real-Time Stats (Unboxed & Elegant)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: locations.length > 1
                    ? () {
                        HapticHelper.triggerFeedback();
                        _showLocationDialog(context);
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              selectedLocation.isEmpty
                                  ? 'All Tables'
                                  : selectedLocation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (locations.length > 1) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          // Clean emerald live indicator dot
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              statsText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                                letterSpacing: -0.1,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sleek minimal filter capsule on the right
          _buildFilterDropdown(context),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    final dashboardProvider = context.read<DashboardProvider>();
    LocationSelectorDialog.show(
      context,
      locations: dashboardProvider.locations,
      selectedLocation: dashboardProvider.selectedLocation,
      onLocationChanged: (location) {
        if (dashboardProvider.selectedLocation != location) {
          dashboardProvider.changeLocation(location);
          final matched =
              dashboardProvider.locations
                  .where((l) => l.name == location)
                  .firstOrNull;
          final outletId = matched?.id ?? HiveService.getOutletId();
          if (outletId != null && outletId > 0) {
            final tableProvider = context.read<TableProvider>();
            tableProvider.setOutletId(outletId);
            tableProvider.setSelectedLocation(location);
            tableProvider.refreshTables();

            context.read<MenuProvider>().loadMenuData(
                  outletId: outletId,
                  forceRefresh: true,
                );
          }
        }
      },
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final isFiltered =
        dashboardProvider.selectedStatusFilter.toLowerCase() != 'all';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticHelper.triggerFeedback();
          _showStatusFilterDialog(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isFiltered
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 14,
                color:
                    isFiltered ? AppColors.primary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                _getStatusFilterDisplayName(
                  dashboardProvider.selectedStatusFilter,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isFiltered ? AppColors.primary : const Color(0xFF334155),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color:
                    isFiltered ? AppColors.primary : const Color(0xFF94A3B8),
              ),
            ],
          ),
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
}
