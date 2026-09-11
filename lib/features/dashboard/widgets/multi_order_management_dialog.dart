import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'add_party_dialog.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import '../providers/table_provider.dart';
import '../providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        final currentTable = tableProvider.tables.firstWhere(
          (t) => t.id == widget.table.id,
          orElse: () => widget.table,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent taps inside popup from closing
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.90,
                        constraints: BoxConstraints(
                          maxWidth: 460,
                          maxHeight: MediaQuery.of(context).size.height * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(
                                    0xFF0F172A,
                                  ).withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : Colors.white.withValues(alpha: 0.50),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(context, currentTable, isDark),
                            Flexible(
                              child: _buildContent(
                                context,
                                currentTable,
                                tableProvider,
                                isDark,
                              ),
                            ),
                            _buildFooter(
                              context,
                              currentTable,
                              tableProvider,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RestaurantTable table,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.20),
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // iOS Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : AppColors.textPrimary)
                    .withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Active Orders',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            table.name,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacity: ${table.capacity}  •  Orders: ${table.orderCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Single minimal close X button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
    bool isDark,
  ) {
    if (table.hasActiveOrders) {
      return ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: table.activeOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final order = table.activeOrders[index];
          return _buildCompactOrderCard(
            context,
            table,
            order,
            index,
            tableProvider,
            isDark,
          );
        },
      );
    } else {
      return _buildNoActiveOrders(isDark);
    }
  }

  Widget _buildCompactOrderCard(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
    int index,
    TableProvider tableProvider,
    bool isDark,
  ) {
    final bool isBilled = order.isBilled;

    return _OrderCardItem(
      onTap: () => _handleOrderTap(context, table, order, tableProvider),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    isBilled
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isBilled
                    ? Icons.receipt_long_rounded
                    : Icons.restaurant_rounded,
                color: isBilled ? AppColors.success : AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.displayLabel,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isBilled
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                isBilled
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isBilled
                              ? 'Billed'
                              : (order.orderStatus.isNotEmpty
                                  ? order.orderStatus
                                  : 'Active'),
                          style: TextStyle(
                            color:
                                isBilled
                                    ? AppColors.success
                                    : AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (order.guestCount != null ||
                      order.displayLabel != order.generatedOrderNo)
                    Text(
                      [
                        if (order.displayLabel != order.generatedOrderNo)
                          order.generatedOrderNo,
                        if (order.guestCount != null)
                          '${order.guestCount} '
                              '${order.guestCount == 1 ? 'guest' : 'guests'}',
                      ].join('  ·  '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    isBilled ? 'Tap to pay' : 'Tap to view cart',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isBilled ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Delete button matching Cart UI & Menu Item Card styling
            InkWell(
              onTap: () => _removeOrder(context, table, order),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveOrders(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No Active Orders',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "+ Add New Order" below to create an order',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.20),
        border: Border(
          top: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed:
                _isCreatingOrder
                    ? null
                    : () {
                      HapticFeedback.selectionClick();
                      _handleAddNewOrder(context, table, tableProvider);
                    },
            icon:
                _isCreatingOrder
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.add_rounded, size: 18),
            label: Text(
              _isCreatingOrder ? 'Adding...' : '+ Add New Order',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle Add New Order to table via Order/saveOrderHead
  Future<void> _handleAddNewOrder(
    BuildContext context,
    RestaurantTable table,
    TableProvider tableProvider,
  ) async {
    final party = await AddPartyDialog.show(
      context,
      tableName: table.name,
      existingPartyCount: table.orderCount,
      capacity: table.capacity,
    );
    if (party == null) return; // cancelled
    if (!context.mounted) return;

    setState(() => _isCreatingOrder = true);
    try {
      final success = await tableProvider.createOrderForTable(
        table.id,
        table.name,
        adults: party.adults,
        children: party.children,
        customerName: party.customerName,
      );

      if (context.mounted) {
        if (success) {
          AppSnackBar.showSuccess(context, 'New order added to ${table.name}');
        } else {
          AppSnackBar.showError(
            context,
            AppStrings.dashboard.failedToAddOrderToServer,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Error creating order: $e');
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
      final storedBillId = tableProvider.getBillId(order.orderId);
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
          orderId: order.orderId,
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

  /// Handle removing an order matching cart_item_card.dart delete dialog design
  void _removeOrder(
    BuildContext context,
    RestaurantTable table,
    ActiveOrder order,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Remove order dialog',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        void closeDialog() {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: closeDialog,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(color: Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {},
                      child: Material(
                        color: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 360),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(
                                          0xFF0F172A,
                                        ).withValues(alpha: 0.55)
                                        : Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 52x52 Red Circle Trash Icon (matches Cart UI)
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Remove Order',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Are you sure you want to remove "${order.generatedOrderNo}"?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: closeDialog,
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  isDark
                                                      ? Colors.white.withValues(
                                                        alpha: 0.1,
                                                      )
                                                      : Colors.white.withValues(
                                                        alpha: 0.5,
                                                      ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                              side: BorderSide(
                                                color: (isDark
                                                        ? Colors.white
                                                        : AppColors.textHint)
                                                    .withValues(alpha: 0.3),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : AppColors
                                                            .textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              closeDialog();
                                              final tableProvider =
                                                  Provider.of<TableProvider>(
                                                    context,
                                                    listen: false,
                                                  );
                                              final cartProvider = Provider.of<
                                                AnimatedCartProvider
                                              >(context, listen: false);

                                              final success =
                                                  await tableProvider
                                                      .removeOrderFromTable(
                                                        table.id,
                                                        order.orderId,
                                                      );

                                              cartProvider.clearCart();
                                              await tableProvider
                                                  .refreshTables();

                                              if (context.mounted) {
                                                if (success) {
                                                  AppSnackBar.showSuccess(
                                                    context,
                                                    'Order ${order.generatedOrderNo} removed',
                                                  );
                                                } else {
                                                  AppSnackBar.showError(
                                                    context,
                                                    'Failed to remove order',
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[600],
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 13,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper stateful widget for order card item tap animation
class _OrderCardItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _OrderCardItem({required this.child, required this.onTap});

  @override
  State<_OrderCardItem> createState() => _OrderCardItemState();
}

class _OrderCardItemState extends State<_OrderCardItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnim.value, child: widget.child);
        },
      ),
    );
  }
}
