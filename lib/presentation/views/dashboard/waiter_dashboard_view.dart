import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/presentation/views/reservations/table_reservation_view.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../shared/widgets/drawers/hamburger_drawer.dart';
import '../../../shared/widgets/layout/location_header.dart';
import '../../../shared/widgets/layout/premium_refresh_indicator.dart';
import '../../view_models/providers/dashboard_provider.dart';
import '../../view_models/providers/navigation_provider.dart';
import '../../view_models/providers/table_provider.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_states.dart';
import 'widgets/table_action_dialog.dart';
import 'widgets/table_grid.dart';
import 'widgets/multi_order_management_dialog.dart';
import 'package:restaurant_pos_system/data/models/order_channel_types_model.dart';
import 'widgets/order_type_selector_dialog.dart';
import '../payment/payment_page.dart';
import 'widgets/customer_details_dialog.dart';
import 'dialogs/customer_info_dialog.dart';

class WaiterDashboardView extends StatefulWidget {
  final Function(String tableId, String tableName)? onTableSelected;
  const WaiterDashboardView({super.key, this.onTableSelected});

  @override
  State<WaiterDashboardView> createState() => _WaiterDashboardViewState();
}

class _WaiterDashboardViewState extends State<WaiterDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
              print('[UI] Building with ${tableProvider.tables.length} tables');
              print('[UI] Loading: ${tableProvider.isLoading}');
              print('[UI] Error: ${tableProvider.error}');
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
                  print('[UI] Filtered tables: ${tables.length}');
                }

                return Container(
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      DashboardHeader(
                        onMenuPressed:
                            () => _scaffoldKey.currentState?.openDrawer(),
                        onAddOrderPressed: _handleAddOrderPressed,
                      ),
                      LocationHeader(
                        selectedLocation: dashboardProvider.selectedLocation,
                        locations: dashboardProvider.locations,
                        tables: tables,
                      ),
                      // Pull-to-refresh for tables area
                      Expanded(
                        child: PremiumRefreshIndicator(
                          onRefresh: () async {
                              try {
                              // Re-initialize / reload tables from provider (API)
                              context.read<TableProvider>().initializeTables();
                              // Removed green SnackBar per request
                            } catch (e) {
                              if (kDebugMode) print('Refresh error: $e');
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
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          children: [
                                            Container(
                                              constraints: BoxConstraints(
                                                minHeight: constraints.maxHeight,
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
                                                        _scaffoldKey.currentState
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
                                        (table) => _handleTableLongPress(table),
                                  ),
                        ),
                      ),
                    ],
                  ),
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
                builder:
            (context) => CustomerInfoDialog(
              orderChannelType: orderType.channelType,
              onSuccess: () {
                // Removed green SnackBar per request: success handled by dialog flow
              },
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
        print('Error handling customer details: $e');
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
    await HapticHelper.triggerFeedback();
    if (kDebugMode) {
      print(
        '[Dashboard] Table ${table.name} clicked - Status: ${table.status}, Orders: ${table.orderCount}',
      );
    }

    if (table.status == TableStatus.available) {
      // Available table - show occupy/reserve dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        builder:
            (BuildContext context) => TableActionDialog(
              table: table,
              onOccupy: () {
                // Navigate to the menu instantly for responsive UI
                context.read<NavigationProvider>().selectTable(
                  table.id,
                  table.name,
                  dashboardProvider.selectedLocation,
                );
                
                // Trigger API-driven table occupation in the background
                tableProvider.createOrderForTable(
                  table.id,
                  table.name,
                ).then((success) {
                  if (!success) {
                    _showSnackBar('Failed to occupy ${table.name} on server', Colors.red);
                  }
                });
              },
              onReserve: () => _showReservationPage(table, tableProvider),
            ),
      );
    } else if (table.status == TableStatus.billGenerated) {
      // Bill Generated - redirect directly to payment page using stored amount
      if (table.hasActiveOrders) {
        final tableProvider = context.read<TableProvider>();
        final orderNumber = table.activeOrders.last.generatedOrderNo;

        try {
          // Get the stored bill ID for this table
          final storedBillId = tableProvider.getBillId(table.id);

          if (storedBillId != null && storedBillId.isNotEmpty) {
            debugPrint(
              '[Dashboard] Found bill ID for ${table.name}: $storedBillId',
            );

            // Navigate directly to payment page with bill ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PaymentPage(
                      orderNumber: orderNumber,
                      totalAmount: 0.0, // Will be fetched from API using billId
                      tableId: table.id,
                      billId: storedBillId, // Pass the bill ID
                      onPaymentCompleted: () {
                        // Refresh tables after payment completion
                        tableProvider.refreshTables();
                        // Clear the active ordering session
                        Provider.of<NavigationProvider>(context, listen: false).clearTableSelection();
                        _showSnackBar(
                          'Payment completed for ${table.name}',
                          Colors.green,
                        );
                      },
                    ),
              ),
            );
          } else {
            _showSnackBar(
              'No bill ID found for ${table.name}. Please generate bill first.',
              Colors.orange,
            );
          }
        } catch (e) {
          _showSnackBar('Error loading bill details: $e', Colors.red);
        }
      } else {
        _showSnackBar('${table.name} has no active orders', Colors.orange);
      }
    } else if (table.status == TableStatus.occupied ||
        table.status == TableStatus.kotGenerated ||
        table.status == TableStatus.billSettled) {
      // Tables with active orders - allow entry for other statuses in the order lifecycle
      if (table.hasActiveOrders) {
        final tableProvider = context.read<TableProvider>();
        final animatedCart = context.read<AnimatedCartProvider>();
        final orderId = table.activeOrders.last.orderId;

        // Load from API (this will also update TableProvider state)
        final items = await tableProvider.loadCartStateForOrder(orderId);

        // Import into AnimatedCartProvider so UI shows them
        animatedCart.importFromOrderCart(
          items,
          tableId: table.id,
          tableName: table.name,
          clearExisting: true,
        );

        debugPrint(
          '[Dashboard] ${table.status.name} table with ${table.orderCount} orders - allowing entry',
        );

        // Navigate to table
        context.read<NavigationProvider>().selectTable(
          table.id,
          table.name,
          dashboardProvider.selectedLocation,
        );

        if (kDebugMode) {
          print('[Dashboard] Table with order - direct navigation to menu');
        }

        if (table.orderCount > 1) {
          // Show management dialog for multiple orders
          showDialog(
            context: context,
            builder: (context) => MultiOrderManagementDialog(table: table),
          );
          if (kDebugMode) {
            print(
              '[Dashboard] Multiple orders table (${table.orderCount}) - showing management dialog',
            );
          }
        }
      } else {
        // Edge case: table has status but no active orders
        _showSnackBar('${table.name} has no active orders', Colors.orange);
      }
    } else if (table.status == TableStatus.reserved) {
      // Reserved table - show info or navigate based on orders
      if (table.hasActiveOrders) {
        showDialog(
          context: context,
          builder: (context) => MultiOrderManagementDialog(table: table),
        );
      } else {
        _showSnackBar('${table.name} is reserved', Colors.orange);
      }
    }
  }

  /// Complete table long press handler
  Future<void> _handleTableLongPress(RestaurantTable table) async {
    await HapticHelper.triggerFeedback();
    if (kDebugMode) {
      print(
        '[Dashboard] Table ${table.name} long pressed - Status: ${table.status}, Orders: ${table.orderCount}',
      );
    }

    // Always show management dialog for long press (as per requirements)
    showDialog(
      context: context,
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
}
