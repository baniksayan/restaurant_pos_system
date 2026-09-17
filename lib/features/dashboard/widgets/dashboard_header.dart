import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/features/orders/providers/ready_to_collect_provider.dart';
import 'package:restaurant_pos_system/features/orders/views/ready_to_collect_orders_view.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onAddOrderPressed;
  final VoidCallback? onReadyToCollectPressed;

  const DashboardHeader({
    super.key,
    required this.onMenuPressed,
    required this.onAddOrderPressed,
    this.onReadyToCollectPressed,
  });

  @override
  Widget build(BuildContext context) {
    final readyProvider = context.watch<ReadyToCollectProvider?>();
    final readyCount = readyProvider?.readyCount ?? 0;
    final hasReadyItems = readyCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 22),
                onPressed: onMenuPressed,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'WhizEats Pro',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Notification icon for Ready to Collect orders (appears ONLY when readyCount > 0)
            if (hasReadyItems) ...[
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_active_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        if (onReadyToCollectPressed != null) {
                          onReadyToCollectPressed!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReadyToCollectOrdersView(),
                            ),
                          );
                        }
                      },
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: const EdgeInsets.all(6),
                      tooltip: 'Ready to Collect',
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1.5,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          readyCount > 99 ? '99+' : '$readyCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],

            // Add Order / Cart Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.add_shopping_cart_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: onAddOrderPressed,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                tooltip: AppStrings.dashboard.newOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
