import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/services/api_service.dart';
import '../../../view_models/providers/table_provider.dart';
import '../../../view_models/providers/navigation_provider.dart';
import '../../../view_models/providers/cart_provider.dart';

class MultiOrderManagementDialog extends StatelessWidget {
  final RestaurantTable table;

  const MultiOrderManagementDialog({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 12,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 580, minHeight: 380),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactHeader(context),
            Expanded(child: _buildContent(context)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.06),
            AppColors.kotStatus.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Orders',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      table.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFDCFCE7),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline_rounded, color: Color(0xFF166534), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Capacity: ${table.capacity}  |  Active Orders: ${table.orderCount}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (table.hasActiveOrders) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: table.activeOrders.length,
        itemBuilder: (context, index) {
          final order = table.activeOrders[index];
          return _buildCompactOrderCard(context, order, index);
        },
      );
    } else {
      return _buildNoActiveOrders();
    }
  }

  Widget _buildCompactOrderCard(
    BuildContext context,
    ActiveOrder order,
    int index,
  ) {
    final bool isBilled = order.isBilled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Clickable Order ID Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToCart(context, order),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.generatedOrderNo,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tap to view cart items',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Status and Remove Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isBilled ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isBilled ? const Color(0xFFBBF7D0) : const Color(0xFFBAE6FD),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: TextStyle(
                      color: isBilled ? const Color(0xFF166534) : const Color(0xFF0369A1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                // Compact Remove Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: () => _removeOrder(context, order),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                  tooltip: 'Remove Order',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Active Orders',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please tap occupy table to add an order',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Close',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _navigateToCart(BuildContext context, ActiveOrder order) {
    Provider.of<TableProvider>(
      context,
      listen: false,
    ).loadCartStateForOrder(order.orderId);

    Provider.of<TableProvider>(
      context,
      listen: false,
    ).setCurrentOrder(order.orderId);

    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.selectTable(table.id, table.name, table.location);

    Navigator.pop(context);

    if (kDebugMode) {
      print(
        '[MultiOrderDialog] Navigating to cart with order: ${order.generatedOrderNo}',
      );
    }
  }

  void _removeOrder(BuildContext context, ActiveOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Remove Order',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove order ${order.generatedOrderNo}?\n\nThis will clear all cart items for this order and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            onPressed: () {
              Provider.of<TableProvider>(
                context,
                listen: false,
              ).removeOrderFromTable(table.id, order.orderId);
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.pop(context); // Close confirm dialog
              Navigator.pop(context); // Close management dialog

              if (kDebugMode) {
                print(
                  '[MultiOrderDialog] Removed order: ${order.generatedOrderNo}',
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
