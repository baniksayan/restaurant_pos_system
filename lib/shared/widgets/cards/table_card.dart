import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/table.dart';

class TableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardData = _getTableCardData();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardData.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardData.borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTableIcon(cardData.borderColor),
            const SizedBox(height: 12),
            _buildTableName(cardData.borderColor),
            const SizedBox(height: 4),
            _buildCapacity(),
            const SizedBox(height: 8),
            _buildStatusBadge(cardData),
            if (table.status == TableStatus.occupied) ...[
              const SizedBox(height: 8),
              _buildKotBillIndicators(),
            ],
          ],
        ),
      ),
    );
  }

  TableCardData _getTableCardData() {
    switch (table.status) {
      case TableStatus.available:
        return TableCardData(
          backgroundColor: Colors.white,
          borderColor: Colors.grey[300]!,
          statusText: 'Available',
        );
      case TableStatus.occupied:
        return TableCardData(
          backgroundColor: AppColors.tableOccupied.withValues(alpha: 0.1),
          borderColor: AppColors.tableOccupied,
          statusText: 'Occupied',
        );
      case TableStatus.reserved:
        return TableCardData(
          backgroundColor: AppColors.tableReserved.withValues(alpha: 0.1),
          borderColor: AppColors.tableReserved,
          statusText: 'Reserved',
        );
      case TableStatus.cleaning:
        return TableCardData(
          backgroundColor: AppColors.tableCleaning.withValues(alpha: 0.1),
          borderColor: AppColors.tableCleaning,
          statusText: 'Cleaning',
        );
    }
  }

  Widget _buildTableIcon(Color borderColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.table_restaurant,
        color: borderColor,
        size: 24,
      ),
    );
  }

  Widget _buildTableName(Color borderColor) {
    return Text(
      table.name,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: borderColor == Colors.grey[300] ? AppColors.textPrimary : borderColor,
      ),
    );
  }

  Widget _buildCapacity() {
    return Text(
      'Capacity: ${table.capacity}',
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildStatusBadge(TableCardData cardData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardData.borderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cardData.statusText,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildKotBillIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (table.kotGenerated) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'KOT',
            style: TextStyle(
              fontSize: 8,
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (table.kotGenerated && table.billGenerated) const SizedBox(width: 8),
        if (table.billGenerated) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'BILL',
            style: TextStyle(
              fontSize: 8,
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class TableCardData {
  final Color backgroundColor;
  final Color borderColor;
  final String statusText;

  TableCardData({
    required this.backgroundColor,
    required this.borderColor,
    required this.statusText,
  });
}
