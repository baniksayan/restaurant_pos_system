import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';

class EnhancedTableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const EnhancedTableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cardData = _getEnhancedCardData();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          gradient: cardData['gradient'],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardData['borderColor'], width: 2),
          boxShadow: [
            BoxShadow(
              color: cardData['borderColor'].withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(6),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTableIcon(cardData),
                  const SizedBox(height: 6),
                  _buildTableName(cardData),
                  const SizedBox(height: 6),
                  _buildCapacity(),
                  const SizedBox(height: 6),
                  _buildStatusBadge(cardData),
                  // NEW: Show multiple orders indicator
                  if (table.isSharedTable) ...[
                    const SizedBox(height: 4),
                    _buildSharedTableIndicator(),
                  ],
                  if (table.status == TableStatus.reserved && table.reservationInfo != null) ...[
                    const SizedBox(height: 6),
                    _buildReservationInfo(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableIcon(Map cardData) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cardData['borderColor'].withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.table_restaurant,
            color: cardData['borderColor'],
            size: 30,
          ),
        ),
        if (table.status == TableStatus.occupied)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 8,
                color: Colors.white,
              ),
            ),
          ),
        // NEW: Multiple orders indicator
        if (table.isSharedTable)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                '${table.orderCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableName(Map cardData) {
    return Text(
      table.name,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: cardData['textColor'],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCapacity() {
    return Text(
      'Capacity: ${table.capacity}',
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStatusBadge(Map cardData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cardData['borderColor'],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: cardData['borderColor'].withOpacity(0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        table.status.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // NEW: Shared table indicator
  Widget _buildSharedTableIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.share, size: 8, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            'SHARED (${table.orderCount})',
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfo() {
    return Column(
      children: [
        Text(
          table.reservationInfo!.timeRange,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          table.reservationInfo!.customerName,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.orange,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Map _getEnhancedCardData() {
    switch (table.status) {
      case TableStatus.available:
        return {
          'gradient': const LinearGradient(
            colors: [Colors.white, Color(0xFFF0FFF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'borderColor': const Color(0xFF10B981),
          'textColor': const Color(0xFF047857),
        };
      case TableStatus.occupied:
        return {
          'gradient': const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'borderColor': const Color(0xFFEF4444),
          'textColor': const Color(0xFFDC2626),
        };
      case TableStatus.reserved:
        return {
          'gradient': const LinearGradient(
            colors: [Colors.white, Color(0xFFFFFBF0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'borderColor': const Color(0xFFF59E0B),
          'textColor': const Color(0xFFD97706),
        };
      default:
        return {
          'gradient': const LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'borderColor': Colors.grey,
          'textColor': Colors.grey,
        };
    }
  }
}
