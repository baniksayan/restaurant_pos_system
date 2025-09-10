import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../data/models/order_management_model.dart';
import 'channel_partner_order_card.dart';
import 'order_card.dart';

class OrderTabView extends StatelessWidget {
  final List orders;
  final String orderType;
  final Function(OrderItem) onOrderTap;

  const OrderTabView({
    super.key,
    required this.orders,
    required this.orderType,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'No $orderType',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here when placed',
              style: const TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        // Add refresh logic here if needed
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // Method to build appropriate order card based on order type
  Widget _buildOrderCard(OrderItem order) {
    if (orderType == 'Channel Partner') {
      return ChannelPartnerOrderCard(
        order: order,
        onTap: () => onOrderTap(order),
        onAccept: (orderId) => _handleOrderAction(orderId, 'accept'),
        onDecline: (orderId) => _handleOrderAction(orderId, 'decline'),
      );
    } else {
      return OrderCard(order: order, onTap: () => onOrderTap(order));
    }
  }

  // Handle accept/decline actions for Channel Partner orders
  Future<void> _handleOrderAction(String orderId, String action) async {
    // TODO: Implement your API call here
    print('[OrderAction] $action order: $orderId');

    // Example API call:
    // await ApiService.updateOrderStatus(orderId, action == 'accept' ? 'accepted' : 'cancelled');

    // Refresh the orders list after action
    // You might want to call a callback to refresh the parent widget
  }
}
