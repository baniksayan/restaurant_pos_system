import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/badges/app_status_badge.dart';
import '../models/chef_order_model.dart';

class ChefStatusBadge extends StatelessWidget {
  final ChefOrderStatus status;

  const ChefStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case ChefOrderStatus.pending:
        bg = const Color(0xFFFFFBEB); // Amber 50
        border = const Color(0xFFF59E0B); // Amber 500
        text = const Color(0xFFB45309); // Amber 700
        label = 'PENDING';
        icon = Icons.hourglass_top_rounded;
        break;
      case ChefOrderStatus.preparing:
        bg = const Color(0xFFEFF6FF); // Blue 50
        border = AppColors.primary;
        text = AppColors.primaryDark;
        label = 'PREPARING';
        icon = Icons.soup_kitchen_rounded;
        break;
      case ChefOrderStatus.ready:
        bg = const Color(0xFFECFDF5); // Green 50
        border = AppColors.success;
        text = AppColors.success;
        label = 'READY TO SERVE';
        icon = Icons.check_circle_outline_rounded;
        break;
      case ChefOrderStatus.served:
        bg = const Color(0xFFF3E8FF); // Purple 50
        border = const Color(0xFF8B5CF6);
        text = const Color(0xFF6D28D9);
        label = 'SERVED';
        icon = Icons.done_all_rounded;
        break;
      case ChefOrderStatus.rejected:
        bg = const Color(0xFFFEF2F2); // Red 50
        border = AppColors.error;
        text = AppColors.error;
        label = 'REJECTED';
        icon = Icons.highlight_off_rounded;
        break;
    }

    return AppStatusBadge(
      label: label,
      color: text,
      icon: icon,
      backgroundColor: bg,
      borderColor: border.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      borderRadius: 8,
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
    );
  }
}
