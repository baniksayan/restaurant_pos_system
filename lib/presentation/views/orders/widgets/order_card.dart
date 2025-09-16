import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../data/models/order_management_model.dart';

class OrderCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status badge
                Row(
                  children: [
                    // if (order.status == OrderStatusType.pending)
                    //   Container(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 8,
                    //       vertical: 2,
                    //     ),
                    //     decoration: BoxDecoration(
                    //       color: AppColors.warning.withOpacity(0.1),
                    //       borderRadius: BorderRadius.circular(4),
                    //     ),
                    //     child: const Text(
                    //       'New',
                    //       style: TextStyle(
                    //         color: AppColors.warning,
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 8),

                // Customer Name
                const SizedBox(height: 4),

                // Order Number - Moved below customer name
                Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),

                // Phone Number (if available)
                if (order.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${order.phoneNumber}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Price - No arrow, clean text
                // Text(
                //   '${CurrencyConstants.symbol}${order.totalAmount.toStringAsFixed(2)}',
                //   style: const TextStyle(
                //     color: AppColors.primary,
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (order.status) {
      case OrderStatusType.pending:
        return AppColors.warning;
      case OrderStatusType.accepted:
        return AppColors.info;
      case OrderStatusType.preparing:
        return AppColors.tableCleaning;
      case OrderStatusType.ready:
        return AppColors.success;
      case OrderStatusType.delivered:
        return AppColors.tableAvailable;
      case OrderStatusType.cancelled:
        return AppColors.error;
      case OrderStatusType.completed:
        return AppColors.success;
    }
  }

  String _getStatusText() {
    switch (order.status) {
      case OrderStatusType.pending:
        return 'Pending';
      case OrderStatusType.accepted:
        return 'Accepted';
      case OrderStatusType.preparing:
        return 'Preparing';
      case OrderStatusType.ready:
        return 'Ready';
      case OrderStatusType.delivered:
        return 'Delivered';
      case OrderStatusType.cancelled:
        return 'Cancelled';
      case OrderStatusType.completed:
        return 'Completed';
    }
  }
}
