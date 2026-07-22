import 'package:flutter/material.dart';

class KotSectionWidget extends StatelessWidget {
  final Color backgroundColor;
  final IconData headerIcon;
  final String headerTitle;
  final Color headerColor;
  final String itemCountText;
  final Color badgeColor;
  final Widget child;

  const KotSectionWidget({
    super.key,
    required this.backgroundColor,
    required this.headerIcon,
    required this.headerTitle,
    required this.headerColor,
    required this.itemCountText,
    required this.badgeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(headerIcon, color: headerColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    headerTitle,
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  itemCountText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
