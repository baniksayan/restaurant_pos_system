import 'package:flutter/material.dart';

class KotSectionWidget extends StatelessWidget {
  final Color backgroundColor;
  final IconData headerIcon;
  final String headerTitle;
  final Color headerColor;
  final String itemCountText;
  final Color badgeColor;
  final Widget child;
  final String? kotNote;
  final VoidCallback? onEditKotNote;
  final VoidCallback? onClearKotNote;

  const KotSectionWidget({
    super.key,
    required this.backgroundColor,
    required this.headerIcon,
    required this.headerTitle,
    required this.headerColor,
    required this.itemCountText,
    required this.badgeColor,
    required this.child,
    this.kotNote,
    this.onEditKotNote,
    this.onClearKotNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: headerColor.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(headerIcon, color: headerColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    headerTitle,
                    style: TextStyle(
                      color: headerColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  itemCountText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (kotNote != null && kotNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildKotNoteFooter(context),
          ],
        ],
      ),
    );
  }

  Widget _buildKotNoteFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: headerColor.withValues(alpha: 0.22),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.soup_kitchen_rounded,
              size: 16,
              color: headerColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Note for Kitchen',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: headerColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kotNote!.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onEditKotNote != null)
            InkWell(
              onTap: onEditKotNote,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: headerColor,
                ),
              ),
            ),
          if (onClearKotNote != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onClearKotNote,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: headerColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
