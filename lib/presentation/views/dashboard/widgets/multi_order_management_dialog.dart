import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600, minHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: table.isSharedTable
            ? Colors.orange.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: table.isSharedTable ? Colors.orange : Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  table.isSharedTable ? Icons.share : Icons.table_restaurant,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Orders - ${table.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (table.isSharedTable)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'SHARED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Compact Plus Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _addNewOrder(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, color: Colors.green[600], size: 16),
              const SizedBox(width: 6),
              Text(
                'Capacity: ${table.capacity} | Active Orders: ${table.orderCount}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (table.hasActiveOrders) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Clickable Order ID Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToCart(context, order),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      order.generatedOrderNo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view cart',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Status and Remove Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.isBilled ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                // Compact Remove Button
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _removeOrder(context, order),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Orders',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the + button above to add the first order',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Close',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _navigateToCart(BuildContext context, ActiveOrder order) {
    // Load cart state for this specific order - FIXED: Use TableProvider
    Provider.of<TableProvider>(
      context,
      listen: false,
    ).loadCartStateForOrder(order.orderId);

    // Set this as the current active order
    Provider.of<TableProvider>(
      context,
      listen: false,
    ).setCurrentOrder(order.orderId);

    // Navigate to menu with this order selected
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    navProvider.selectTable(table.id, table.name, table.location);

    Navigator.pop(context);

    if (kDebugMode) {
      print(
        '[MultiOrderDialog] Navigating to cart with order: ${order.generatedOrderNo}',
      );
    }
  }

  void _addNewOrder(BuildContext context) async {
    try {
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      final token = tableProvider.getAuthToken(); // Make sure this method is public in TableProvider
      final userId = HiveService.getUserId();
      final waiterId = HiveService.getWaiterId();

      if (token == null || userId == null) {
        print('[Error] Missing authentication credentials for new order');
        return;
      }

      // Call saveOrderHead API to create new order (same as single table click)
      final orderResponse = await ApiService.saveOrderHead(
        token: token,
        orderChannelId: table.id,
        waiterId: waiterId ?? userId,
        customerName: 'Walk-in Customer',
        outletId: tableProvider.outletId,
        userId: userId,
      );

      if (orderResponse != null && orderResponse.isSuccess == true) {
        final orderId = orderResponse.data?.orderId;
        final generatedOrderNo = orderResponse.data?.generatedOrderNo;

        if (orderId != null && generatedOrderNo != null) {
          print('[MultiOrderDialog] New order created: $generatedOrderNo');

          // Set as current order
          tableProvider.setCurrentOrder(orderId);

          // Navigate to menu
          final navProvider = Provider.of<NavigationProvider>(
            context,
            listen: false,
          );
          navProvider.selectTable(table.id, table.name, table.location);

          Navigator.pop(context);

          if (kDebugMode) {
            print(
              '[MultiOrderDialog] Added new order via API: $generatedOrderNo',
            );
          }
        } else {
          print('[Error] Failed to create new order via API');
        }
      } else {
        print('[Error] Failed to create new order via API');
      }
    } catch (e) {
      print('[Error] Adding new order: $e');
    }
  }

  void _removeOrder(BuildContext context, ActiveOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Remove Order'),
        content: Text(
          'Remove order ${order.generatedOrderNo}?\n\nThis will clear all cart items for this order and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
