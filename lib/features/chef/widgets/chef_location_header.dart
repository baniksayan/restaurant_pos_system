import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/dashboard/widgets/location_selector_dialog.dart';
import '../providers/chef_provider.dart';
import 'chef_status_filter_dialog.dart';

/// Minimalist, borderless, premium location header for WhizEats KDS.
///
/// Features dynamic outlet selection matching the Waiter Dashboard,
/// live order statistics, and status filter capsule.
class ChefLocationHeader extends StatelessWidget {
  const ChefLocationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final chefProvider = context.watch<ChefProvider>();
    final orders = chefProvider.filteredOrders;
    final totalCount = orders.length;
    final queueCount = chefProvider.queueCount;

    final statsText = totalCount == 0
        ? 'No active orders'
        : '$totalCount ${totalCount == 1 ? "order" : "orders"} • $queueCount in queue';

    final isFiltered = chefProvider.selectedStatusFilter != 'All Statuses';

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
                onTap: chefProvider.locations.length > 1
                    ? () {
                        HapticHelper.triggerFeedback();
                        _showLocationDialog(context, chefProvider);
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              chefProvider.selectedLocation.isEmpty
                                  ? 'All Outlets'
                                  : chefProvider.selectedLocation,
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
                          if (chefProvider.locations.length > 1) ...[
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticHelper.triggerFeedback();
                showChefStatusFilterDialog(context, chefProvider);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
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
                      color: isFiltered
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      chefProvider.selectedStatusFilter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFiltered
                            ? AppColors.primary
                            : const Color(0xFF334155),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isFiltered
                          ? AppColors.primary
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context, ChefProvider chefProvider) {
    LocationSelectorDialog.show(
      context,
      locations: chefProvider.locations,
      selectedLocation: chefProvider.selectedLocation,
      onLocationChanged: (location) {
        if (chefProvider.selectedLocation != location) {
          chefProvider.changeLocation(location);
        }
      },
    );
  }
}
