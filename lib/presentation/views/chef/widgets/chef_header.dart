import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/chef_provider.dart';
import 'chef_status_filter_dialog.dart';

class ChefHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback? onFilterPressed;
  final bool showFilter;

  const ChefHeader({
    super.key,
    required this.onMenuPressed,
    this.onFilterPressed,
    this.showFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    final chefProvider = context.watch<ChefProvider>();
    final isFilterActive = chefProvider.selectedStatusFilter != 'All Statuses';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Hamburger Menu Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 22, color: AppColors.primary),
                onPressed: onMenuPressed,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
              ),
            ),
            const SizedBox(width: 12),

            // Header Title
            const Expanded(
              child: Text(
                'WhizEats KDS',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Filter Icon Button shown ONLY when in "All" tab (showFilter == true)
            if (showFilter)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isFilterActive
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: isFilterActive
                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2)
                          : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: isFilterActive ? AppColors.primary : AppColors.textPrimary,
                      ),
                      onPressed: () {
                        if (onFilterPressed != null) {
                          onFilterPressed!();
                        } else {
                          showChefStatusFilterDialog(context, chefProvider);
                        }
                      },
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: const EdgeInsets.all(6),
                      tooltip: 'Filter by Status',
                    ),
                  ),

                  // Active Filter Indicator Badge
                  if (isFilterActive)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B), // Amber badge dot
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            else
              const SizedBox(width: 36, height: 36),
          ],
        ),
      ),
    );
  }
}
