import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class MenuHeader extends StatelessWidget {
  final bool canOrder;
  final String? tableName;
  final String? selectedLocation;
  final VoidCallback? onPrintKOT;

  const MenuHeader({
    super.key,
    required this.canOrder,
    this.tableName,
    this.selectedLocation,
    this.onPrintKOT,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (canOrder)
                  Text(
                    tableName ?? 'Select Table',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if ((selectedLocation ?? '').isNotEmpty)
                  Text(
                    'Location: $selectedLocation',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
              ],
            ),
          ),
          if (canOrder) ...[
            IconButton(
              onPressed: onPrintKOT,
              icon: const Icon(Icons.print, color: AppColors.primary),
              tooltip: 'Print KOT',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ORDERING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'VIEW ONLY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
