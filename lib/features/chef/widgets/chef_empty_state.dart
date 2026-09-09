import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/empty_state_widget.dart';

class ChefEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ChefEmptyState({
    super.key,
    this.title = 'Kitchen is all caught up!',
    this.description = 'No new or active orders at the moment.',
    this.icon = Icons.soup_kitchen_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon,
      title: title,
      description: description,
      iconColor: AppColors.primary,
    );
  }
}
