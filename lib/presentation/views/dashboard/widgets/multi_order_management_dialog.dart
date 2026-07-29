import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import '../../payment/payment_page.dart';
import '../../../view_models/providers/table_provider.dart';
import '../../../view_models/providers/navigation_provider.dart';
import '../../../view_models/providers/cart_provider.dart';
import '../../../view_models/providers/animated_cart_provider.dart';

class MultiOrderManagementDialog extends StatefulWidget {
  final RestaurantTable table;

  const MultiOrderManagementDialog({super.key, required this.table});

  @override
  State<MultiOrderManagementDialog> createState() =>
      _MultiOrderManagementDialogState();
}

class _MultiOrderManagementDialogState
    extends State<MultiOrderManagementDialog> {
  bool _isCreatingOrder = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        // Always resolve latest table state from provider
        final currentTable = tableProvider.tables.firstWhere(
          (t) => t.id == widget.table.id,
          orElse: () => widget.table,
        );

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 12,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 620, minHeight: 380),
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
                _buildCompactHeader(context, currentTable),
                Expanded(
                  child: _buildContent(context, currentTable, tableProvider),
                ),
                _buildFooter(context, currentTable, tableProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader(BuildContext context, RestaurantTable table) {
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
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
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
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  color: Color(0xFF166534),
                  size: 16,
                ),
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

  Widget _buildContent(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
  ) {
    if (table.hasActiveOrders) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: table.activeOrders.length,
        itemBuilder: (context, index) {
          final order = table.activeOrders[index];
          return _buildCompactOrderCard(
            context,
            table,
            order,
            index,
            tableProvider,
          );
        },
      );
    } else {
      return _buildNoActiveOrders();
    }
  }

  Widget _buildCompactOrderCard(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    int index,
    TableProvider tableProvider,
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
              onTap: () => _handleOrderTap(context, table, order, tableProvider),
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
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                          Text(
                            isBilled
                                ? 'Tap to proceed to payment'
                                : 'Tap to view cart items',
                            style: TextStyle(
                              fontSize: 11.5,
                              color:
                                  isBilled
                                      ? Colors.green.shade700
                                      : AppColors.primary,
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
                    color:
                        isBilled
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isBilled
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFBAE6FD),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isBilled ? 'Billed' : (order.orderStatus.isNotEmpty ? order.orderStatus : 'Active'),
                    style: TextStyle(
                      color:
                          isBilled
                              ? const Color(0xFF166534)
                              : const Color(0xFF0369A1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                // Compact Remove Button (Calls Order/UpdateOrderHeadStatus with statusId: 6)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: () => _removeOrder(context, table, order),
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
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
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
            'Tap "+ Add New Order" below to create an order',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          // Add New Order Button (Calls Order/saveOrderHead API)
          Expanded(
            child: SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed:
                    _isCreatingOrder
                        ? null
                        : () => _handleAddNewOrder(context, table, tableProvider),
                icon:
                    _isCreatingOrder
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  _isCreatingOrder ? 'Adding...' : '+ Add New Order',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Close Button
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle Add New Order to table via Order/saveOrderHead
  Future<void> _handleAddNewOrder(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
  ) async {
    setState(() => _isCreatingOrder = true);
    try {
      final success = await tableProvider.createOrderForTable(
        table.id,
        table.name,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New order added to ${table.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add order to server'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingOrder = false);
      }
    }
  }

  /// Handle tapping an order (opens PaymentPage if billed, otherwise loads cart & navigates)
  Future<void> _handleOrderTap(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    TableProvider tableProvider,
  ) async {
    if (order.isBilled) {
      final storedBillId = tableProvider.getBillId(table.id);
      Navigator.pop(context); // Close dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PaymentPage(
                orderId: order.orderId,
                orderNumber: order.generatedOrderNo,
                tableId: table.id,
                billId: storedBillId,
                onPaymentCompleted: () {
                  tableProvider.refreshTables();
                  Provider.of<NavigationProvider>(
                    context,
                    listen: false,
                  ).clearTableSelection();
                },
              ),
        ),
      );
    } else {
      final items = await tableProvider.loadCartStateForOrder(order.orderId);
      tableProvider.setCurrentOrder(order.orderId);

      if (context.mounted) {
        final animatedCart = Provider.of<AnimatedCartProvider>(
          context,
          listen: false,
        );
        animatedCart.importFromOrderCart(
          items,
          tableId: table.id,
          tableName: table.name,
          clearExisting: true,
        );

        final navProvider = Provider.of<NavigationProvider>(
          context,
          listen: false,
        );
        navProvider.selectTable(table.id, table.name, table.location);

        Navigator.pop(context);
      }
    }
  }

  /// Handle removing an order via Order/UpdateOrderHeadStatus (statusId: 6)
  void _removeOrder(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Remove Order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Remove order ${order.generatedOrderNo}?\n\nThis will cancel the order on server and clear local items.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close confirm dialog
                  final tableProvider = Provider.of<TableProvider>(
                    context,
                    listen: false,
                  );
                  final cartProvider = Provider.of<CartProvider>(
                    context,
                    listen: false,
                  );

                  final success = await tableProvider.removeOrderFromTable(
                    table.id,
                    order.orderId,
                  );

                  cartProvider.clearCart();
                  await tableProvider.refreshTables();

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order ${order.generatedOrderNo} removed'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to remove order'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
