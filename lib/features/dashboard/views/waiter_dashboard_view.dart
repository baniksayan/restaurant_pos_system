import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/reservations/views/table_reservation_view.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import '../widgets/hamburger_drawer.dart';
import '../widgets/location_header.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/premium_refresh_indicator.dart';
import 'package:restaurant_pos_system/shared/widgets/overlays/hourglass_loading_overlay.dart';
import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/table_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_states.dart';
import '../widgets/table_action_dialog.dart';
import '../widgets/table_grid.dart';
import '../widgets/multi_order_management_dialog.dart';
import 'package:restaurant_pos_system/data/models/order_channel_types_model.dart';
import '../widgets/order_type_selector_dialog.dart';
import 'package:restaurant_pos_system/features/payment/views/payment_view.dart';
import '../widgets/customer_details_dialog.dart';
import '../widgets/dialogs/customer_info_dialog.dart';

class WaiterDashboardView extends StatefulWidget {
  final Function(String tableId, String tableName)? onTableSelected;
  const WaiterDashboardView({super.key, this.onTableSelected});

  @override
  State<WaiterDashboardView> createState() => _WaiterDashboardViewState();
}

class _WaiterDashboardViewState extends State<WaiterDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _navigatingTableName;

  bool get _isTableNavigationInProgress => _navigatingTableName != null;

  @override
  void initState() {
    super.initState();
    // CRITICAL: Delay initialization to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().initializeTables();
      final dashboardProvider = context.read<DashboardProvider>();
      if (dashboardProvider.selectedLocation.isEmpty) {
        dashboardProvider.changeLocation('Main Hall');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawerScrimColor: Colors.black.withValues(alpha: 0.12),
        drawerEnableOpenDragGesture: !_isTableNavigationInProgress,
        drawer: Consumer<DashboardProvider>(
          builder: (context, dashboardProvider, child) {
            return HamburgerDrawer(
              selectedLocation: dashboardProvider.selectedLocation,
              selectedStatusFilter: dashboardProvider.selectedStatusFilter,
              onLocationChanged: (location) {
                dashboardProvider.changeLocation(location);
                Navigator.pop(context);
                _showSnackBar('Showing: $location', Colors.blue);
              },
              onStatusFilterChanged: (statusFilter) {
                dashboardProvider.changeStatusFilter(statusFilter);
                Navigator.pop(context);
                // Removed green SnackBar per request: previously showed filtered-by message in green
              },
            );
          },
        ),
        // CRITICAL FIX: Use Consumer to listen for changes
        body: Consumer<TableProvider>(
          builder: (context, tableProvider, child) {
            if (kDebugMode) {
              debugPrint('[UI] Building with ${tableProvider.tables.length} tables');
              debugPrint('[UI] Loading: ${tableProvider.isLoading}');
              debugPrint('[UI] Error: ${tableProvider.error}');
            }

            if (tableProvider.isLoading) {
              return const DashboardLoadingState();
            }

            if (tableProvider.error != null) {
              return DashboardErrorState(tableProvider: tableProvider);
            }

            // Use Consumer for DashboardProvider too
            return Consumer<DashboardProvider>(
              builder: (context, dashboardProvider, child) {
                final tables = tableProvider.getTablesForLocation(
                  dashboardProvider.selectedLocation,
                  dashboardProvider.selectedStatusFilter,
                );

                if (kDebugMode) {
                  debugPrint('[UI] Filtered tables: ${tables.length}');
                }

                return Stack(
                  children: [
                    Container(
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          DashboardHeader(
                            onMenuPressed:
                                () => _scaffoldKey.currentState?.openDrawer(),
                            onAddOrderPressed: _handleAddOrderPressed,
                          ),
                          LocationHeader(
                            selectedLocation:
                                dashboardProvider.selectedLocation,
                            locations: dashboardProvider.locations,
                            tables: tables,
                          ),
                          // Pull-to-refresh for tables area
                          Expanded(
                            child: PremiumRefreshIndicator(
                              onRefresh: () async {
                                try {
                                  // Re-initialize / reload tables from provider (API)
                                  context
                                      .read<TableProvider>()
                                      .initializeTables();
                                  // Removed green SnackBar per request
                                } catch (e) {
                                  if (kDebugMode) debugPrint('Refresh error: $e');
                                  _showSnackBar(
                                    'Failed to refresh tables',
                                    Colors.red,
                                  );
                                }
                              },
                              // The TableGrid likely uses a scrollable (GridView). For empty state,
                              // provide a scrollable ListView so pull-to-refresh still works.
                              child:
                                  tables.isEmpty
                                      ? LayoutBuilder(
                                        builder: (context, constraints) {
                                          return ListView(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            children: [
                                              Container(
                                                constraints: BoxConstraints(
                                                  minHeight:
                                                      constraints.maxHeight,
                                                ),
                                                child: DashboardEmptyState(
                                                  selectedLocation:
                                                      dashboardProvider
                                                              .selectedLocation
                                                              .isEmpty
                                                          ? 'All Tables'
                                                          : dashboardProvider
                                                              .selectedLocation,
                                                  onChangeLocation:
                                                      () =>
                                                          _scaffoldKey
                                                              .currentState
                                                              ?.openDrawer(),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                      : TableGrid(
                                        tables: tables,
                                        onTableTap:
                                            (table) => _handleTableClick(
                                              table,
                                              tableProvider,
                                              dashboardProvider,
                                            ),
                                        onTableLongPress:
                                            (table) =>
                                                _handleTableLongPress(table),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isTableNavigationInProgress)
                      HourglassLoadingOverlay(
                        message: 'Opening $_navigatingTableName...',
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Handle Add Order button press - NEW METHOD
  void _handleAddOrderPressed() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (context) => OrderTypeSelectorDialog(
            onOrderTypeSelected: _handleOrderTypeSelected,
          ),
    );
  }

  /// Handle order type selection - UPDATED METHOD
  void _handleOrderTypeSelected(OrderType orderType) {
    if (orderType == OrderType.dineIn) {
      // For dine-in, just show table selection (existing behavior)
      _showSnackBar('Select a table for dine-in order', Colors.blue);
    } else if (orderType == OrderType.phoneOrder ||
        orderType == OrderType.takeaway) {
      // Use new CustomerInfoDialog for Phone and Takeaway orders
      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder:
            (context) => CustomerInfoDialog(
              orderChannelType: orderType.channelType,
              onBack: () {
                Navigator.pop(context);
                _handleAddOrderPressed();
              },
              onSuccess: () {},
            ),
      );
    } else {
      // For other order types, use existing flow
      showDialog(
        context: context,
        builder:
            (context) => CustomerDetailsDialog(
              orderType: orderType,
              onConfirm:
                  (name, phone) =>
                      _handleCustomerDetailsConfirm(orderType, name, phone),
            ),
      );
    }
  }

  /// Handle customer details confirmation - FIXED METHOD
  void _handleCustomerDetailsConfirm(
    OrderType orderType,
    String customerName,
    String phoneNumber,
  ) {
    try {
      // CRITICAL FIX: Clear all cart session data to prevent table order contamination
      context.read<AnimatedCartProvider>().clearAllSessionData();

      // Store the order type and customer details
      context.read<DashboardProvider>().setOrderType(orderType);
      context.read<DashboardProvider>().setCustomerDetails(
        customerName,
        phoneNumber,
      );

      // Navigate to menu with the order details
      context.read<NavigationProvider>().selectOrderTypeAndNavigate(
        orderType.channelType,
        customerName,
        phoneNumber,
      );

      // Removed green SnackBar per request: creation success previously shown in green
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error handling customer details: $e');
      }
      _showSnackBar('Error creating order', Colors.red);
    }
  }

  /// Complete table click handler with API integration
  Future<void> _handleTableClick(
    RestaurantTable table,
    TableProvider tableProvider,
    DashboardProvider dashboardProvider,
  ) async {
    if (_isTableNavigationInProgress) {
      return;
    }

    await HapticHelper.triggerFeedback();
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint(
        '[Dashboard] Table ${table.name} clicked - Status: ${table.status}, Orders: ${table.orderCount}',
      );
    }

    // 1. If table has multiple orders, open multi-order management popup directly
    if (table.orderCount > 1) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.15),
        builder: (context) => MultiOrderManagementDialog(table: table),
      );
      return;
    }

    // 2. Check if table has a single billed order
    ActiveOrder? billedOrder;
    if (table.hasActiveOrders) {
      for (final order in table.activeOrders) {
        if (order.isBilled) {
          billedOrder = order;
          break;
        }
      }
    }

    if (billedOrder != null || table.status == TableStatus.billGenerated || table.billGenerated) {
      final targetOrderId =
          billedOrder?.orderId ??
          (table.hasActiveOrders ? table.activeOrders.last.orderId : null);
      final orderNumber =
          billedOrder?.generatedOrderNo ??
          (table.hasActiveOrders ? table.activeOrders.last.generatedOrderNo : null);

      final storedBillId = tableProvider.getBillId(table.id);
      final navProvider = context.read<NavigationProvider>();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PaymentPage(
                orderId: targetOrderId,
                orderNumber: orderNumber,
                tableId: table.id,
                billId: storedBillId,
                onPaymentCompleted: () {
                  tableProvider.refreshTables();
                  navProvider.clearTableSelection();
                  if (mounted) {
                    _showSnackBar(
                      'Payment completed for ${table.name}',
                      Colors.green,
                    );
                  }
                },
              ),
        ),
      );
      return;
    }

    // 3. Single active order (unbilled) -> Load cart state from API so KOTs display in cart
    if (table.hasActiveOrders) {
      final animatedCart = context.read<AnimatedCartProvider>();
      final orderId = table.activeOrders.last.orderId;

      _setTableNavigationLoading(table.name);
      try {
        final items = await tableProvider.loadCartStateForOrder(orderId);
        if (!mounted) return;
        tableProvider.setCurrentOrder(orderId);

        animatedCart.importFromOrderCart(
          items,
          tableId: table.id,
          tableName: table.name,
          clearExisting: true,
        );

        context.read<NavigationProvider>().selectTable(
          table.id,
          table.name,
          dashboardProvider.selectedLocation,
        );
      } finally {
        _clearTableNavigationLoading();
      }
      return;
    }

    // 4. Empty / Available table -> Show occupy or reserve dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder:
          (BuildContext context) => TableActionDialog(
            table: table,
            onOccupy: () {
              context.read<NavigationProvider>().selectTable(
                table.id,
                table.name,
                dashboardProvider.selectedLocation,
              );

              tableProvider.createOrderForTable(table.id, table.name).then((
                success,
              ) {
                if (!success) {
                  _showSnackBar(
                    'Failed to occupy ${table.name} on server',
                    Colors.red,
                  );
                }
              });
            },
            onReserve: () => _showReservationPage(table, tableProvider),
          ),
    );
  }

  /// Complete table long press handler
  Future<void> _handleTableLongPress(RestaurantTable table) async {
    if (_isTableNavigationInProgress) {
      return;
    }

    await HapticHelper.triggerFeedback();
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint(
        '[Dashboard] Table ${table.name} long pressed - Status: ${table.status}, Orders: ${table.orderCount}',
      );
    }

    // Always show management dialog for long press (as per requirements)
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) => MultiOrderManagementDialog(table: table),
    );
  }

  void _showReservationPage(
    RestaurantTable table,
    TableProvider tableProvider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TableReservationView(
              table: table,
              onReservationConfirmed: (reservation) {
                tableProvider.updateTableStatus(table.id, 'reserved');
                _showSnackBar(
                  '${table.name} reserved successfully!',
                  Colors.green,
                );
              },
            ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _setTableNavigationLoading(String tableName) {
    if (!mounted) {
      return;
    }

    setState(() {
      _navigatingTableName = tableName;
    });
  }

  void _clearTableNavigationLoading() {
    if (!mounted || _navigatingTableName == null) {
      return;
    }

    setState(() {
      _navigatingTableName = null;
    });
  }
}
