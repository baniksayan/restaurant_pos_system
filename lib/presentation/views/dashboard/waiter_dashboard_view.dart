import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/presentation/views/reservations/table_reservation_view.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../shared/widgets/drawers/hamburger_drawer.dart';
import '../../../shared/widgets/layout/location_header.dart';
import '../../view_models/providers/dashboard_provider.dart';
import '../../view_models/providers/navigation_provider.dart';
import '../../view_models/providers/table_provider.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_states.dart';
import 'widgets/table_action_dialog.dart';
import 'widgets/table_grid.dart';
import 'widgets/multi_order_management_dialog.dart';

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
                final filterName = _getStatusFilterDisplayName(statusFilter);
                _showSnackBar('Filtered by: $filterName', Colors.green);
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
                      ),
                      LocationHeader(
                        selectedLocation: dashboardProvider.selectedLocation,
                        locations: dashboardProvider.locations ?? [],
                        tables: tables,
                      ),
                      Expanded(
                        child:
                            tables.isEmpty
                                ? DashboardEmptyState(
                                  selectedLocation:
                                      dashboardProvider.selectedLocation.isEmpty
                                          ? 'All Tables'
                                          : dashboardProvider.selectedLocation,
                                  onChangeLocation:
                                      () =>
                                          _scaffoldKey.currentState
                                              ?.openDrawer(),
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

  String _getStatusFilterDisplayName(String statusFilter) {
    switch (statusFilter) {
      case 'all':
        return 'All Tables';
      case 'available':
        return 'Available Tables';
      case 'occupied':
        return 'Occupied Tables';
      case 'reserved':
        return 'Reserved Tables';
      case 'kot_generated':
        return 'KOT Generated';
      case 'bill_generated':
        return 'Bill Generated';
      default:
        return statusFilter;
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
        builder:
            (BuildContext context) => TableActionDialog(
              table: table,
              onOccupy: () async {
                // API-driven table occupation
                final success = await tableProvider.createOrderForTable(
                  table.id,
                  table.name,
                );
                if (success) {
                  context.read<NavigationProvider>().selectTable(
                    table.id,
                    table.name,
                    dashboardProvider.selectedLocation,
                  );
                  _showSnackBar('${table.name} is now occupied', Colors.green);
                  if (kDebugMode) {
                    print(
                      '[Dashboard] Table ${table.name} successfully occupied',
                    );
                  }
                } else {
                  _showSnackBar('Failed to occupy ${table.name}', Colors.red);
                }
              },
              onReserve: () => _showReservationPage(table, tableProvider),
            ),
      );
    } else if (table.status == TableStatus.occupied) {
      // Occupied table logic based on requirements
      if (table.orderCount == 1) {
        // Single order - navigate directly to menu
        final orderId = table.activeOrders.first.orderId;
        await tableProvider.loadCartStateForOrder(orderId);
        context.read<NavigationProvider>().selectTable(
          table.id,
          table.name,
          dashboardProvider.selectedLocation,
        );
        if (kDebugMode) {
          print('[Dashboard] Single order table - direct navigation to menu');
        }
      } else if (table.orderCount > 1) {
        // Multiple orders - show management dialog
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
