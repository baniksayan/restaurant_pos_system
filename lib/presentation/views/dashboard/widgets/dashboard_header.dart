import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final VoidCallback onAddOrderPressed; // Add this

  const DashboardHeader({
    super.key,
    required this.onMenuPressed,
    required this.onAddOrderPressed, // Add this
  });

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.primary.withOpacity(0.1),
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
                'WiZARD Restaurant',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Add the plus button here
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, size: 22, color: Colors.white),
                onPressed: onAddOrderPressed,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                tooltip: 'New Order',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
