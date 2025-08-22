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
          padding: const EdgeInsets.all(4),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusIndicator(cardData),
                  const SizedBox(height: 4),
                  _buildTableIcon(cardData),
                  const SizedBox(height: 4),
                  _buildTableName(cardData),
                  _buildCapacity(),
                  const SizedBox(height: 2),
                  _buildStatusBadge(cardData),
                  if (table.status == TableStatus.reserved &&
                      table.reservationInfo != null) ...[
                    const SizedBox(height: 1),
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

  Widget _buildStatusIndicator(Map<String, dynamic> cardData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _getLiveStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                color: _getLiveStatusColor(),
              ),
            ),
          ],
        ),
        if (table.status == TableStatus.reserved)
          const Icon(Icons.schedule, size: 8, color: Colors.orange),
      ],
    );
  }

  Widget _buildTableIcon(Map<String, dynamic> cardData) {
    return Stack(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: cardData['borderColor'].withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.table_restaurant,
            color: cardData['borderColor'],
            size: 16,
          ),
        ),
        if (table.status == TableStatus.occupied)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 6,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableName(Map<String, dynamic> cardData) {
    return Text(
      table.name,
      style: TextStyle(
        fontSize: 12,
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
        fontSize: 8,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> cardData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: cardData['borderColor'],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: cardData['borderColor'].withOpacity(0.25),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        table.status.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 6,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildReservationInfo() {
    return Column(
      children: [
        Text(
          table.reservationInfo!.timeRange,
          style: const TextStyle(
            fontSize: 4,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          table.reservationInfo!.customerName,
          style: const TextStyle(fontSize: 4, color: Colors.orange),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getLiveStatusColor() {
    switch (table.status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> _getEnhancedCardData() {
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
