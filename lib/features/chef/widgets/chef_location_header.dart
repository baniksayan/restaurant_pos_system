import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import '../providers/chef_provider.dart';

class ChefLocationHeader extends StatelessWidget {
  const ChefLocationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final chefProvider = Provider.of<ChefProvider>(context);
    final orders = chefProvider.filteredOrders;

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
                    const Icon(
                      Icons.soup_kitchen_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        chefProvider.selectedLocation.isEmpty
                            ? 'Main Kitchen'
                            : chefProvider.selectedLocation,
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
                  '${orders.length} ${orders.length == 1 ? 'order' : 'orders'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Dynamic status filter dropdown on the right top
          _buildFilterDropdown(context, chefProvider),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, ChefProvider chefProvider) {
    return InkWell(
      onTap: () => _showStatusFilterDialog(context, chefProvider),
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
              chefProvider.selectedStatusFilter,
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

  void _showStatusFilterDialog(
    BuildContext context,
    ChefProvider chefProvider,
  ) {
    final statusList = chefProvider.statusFilters;

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
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
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
                                          alpha: 0.5,
                                        ),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.withValues(
                                              alpha: 0.2,
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
                                                  'Filter by KDS Status',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  'Select a status to filter kitchen orders',
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
                                              size: 20,
                                            ),
                                            onPressed:
                                                () => Navigator.pop(
                                                  dialogContext,
                                                ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.6),
                                              padding: const EdgeInsets.all(8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Options List
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        children:
                                            statusList.map((status) {
                                              final isSelected =
                                                  chefProvider
                                                      .selectedStatusFilter ==
                                                  status;
                                              final color = _getStatusColor(
                                                status,
                                              );

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 3,
                                                    ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      chefProvider
                                                          .changeStatusFilter(
                                                            status,
                                                          );
                                                      Navigator.pop(
                                                        dialogContext,
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 11,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isSelected
                                                                ? color
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    )
                                                                : Colors
                                                                    .transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              isSelected
                                                                  ? color
                                                                      .withValues(
                                                                        alpha:
                                                                            0.4,
                                                                      )
                                                                  : Colors
                                                                      .transparent,
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: color,
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              status,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    isSelected
                                                                        ? FontWeight
                                                                            .w700
                                                                        : FontWeight
                                                                            .w500,
                                                                color:
                                                                    isSelected
                                                                        ? color
                                                                        : AppColors
                                                                            .textPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                          if (isSelected)
                                                            Icon(
                                                              Icons
                                                                  .check_circle_rounded,
                                                              color: color,
                                                              size: 18,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706); // Amber
      case 'preparing':
        return AppColors.primary; // Blue/Violet
      case 'ready to serve':
      case 'ready':
        return AppColors.success; // Green
      case 'served':
        return const Color(0xFF8B5CF6); // Purple
      case 'all statuses':
      default:
        return AppColors.primary;
    }
  }
}
