import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().initializeTables();
      // Set Main Hall as default location if none is selected
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
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ],
        child: Consumer2<TableProvider, DashboardProvider>(
          builder: (context, tableProvider, dashboardProvider, child) {
            // Handle loading state
            if (tableProvider.isLoading) {
              return const DashboardLoadingState();
            }

            // Handle error state
            if (tableProvider.error != null) {
              return DashboardErrorState(tableProvider: tableProvider);
            }

            // Get tables based on selected location and status filter
            final tables = tableProvider.getTablesForLocation(
              dashboardProvider.selectedLocation,
              dashboardProvider.selectedStatusFilter,
            );

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.grey[50],
              drawer: HamburgerDrawer(
                selectedLocation: dashboardProvider.selectedLocation,
                selectedStatusFilter: dashboardProvider.selectedStatusFilter,
                onLocationChanged: (location) {
                  dashboardProvider.changeLocation(location);
                  Navigator.pop(context); // Close drawer
                  _showSnackBar('Showing: $location', Colors.blue);
                },
                onStatusFilterChanged: (statusFilter) {
                  dashboardProvider.changeStatusFilter(statusFilter);
                  Navigator.pop(context); // Close drawer
                  final filterName = _getStatusFilterDisplayName(statusFilter);
                  _showSnackBar('Filtered by: $filterName', Colors.green);
                },
              ),
              body: Container(
                color: Colors.grey[50],
                child: Column(
                  children: [
                    DashboardHeader(
                      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    // Safe LocationHeader usage - now passes selected location directly
                    LocationHeader(
                      selectedLocation: dashboardProvider.selectedLocation,
                      locations: dashboardProvider.locations ?? [], // Ensure non-null
                      tables: tables ?? [], // Ensure non-null
                    ),
                    Expanded(
                      child: tables.isEmpty
                          ? DashboardEmptyState(
                              selectedLocation: dashboardProvider.selectedLocation.isEmpty
                                  ? 'All Tables'
                                  : dashboardProvider.selectedLocation,
                              onChangeLocation: () => _scaffoldKey.currentState?.openDrawer(),
                            )
                          : TableGrid(
                              tables: tables,
                              onTableTap: (table) => _handleTableClick(
                                table,
                                tableProvider,
                                dashboardProvider,
                              ),
                              onTableLongPress: (table) => _handleTableLongPress(table),
                            ),
                    ),
                  ],
                ),
              ),
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

  Future<void> _handleTableClick(
    RestaurantTable table,
    TableProvider tableProvider,
    DashboardProvider dashboardProvider,
  ) async {
    await HapticHelper.triggerFeedback();
    
    if (table.status == TableStatus.available) {
      showDialog(
        context: context,
        builder: (context) => TableActionDialog(
          table: table,
          onOccupy: () {
            tableProvider.updateTableStatus(table.id, 'occupied');
            context.read<NavigationProvider>().selectTable(
              table.id,
              table.name,
              dashboardProvider.selectedLocation,
            );
          },
          onReserve: () => _showReservationPage(table, tableProvider),
        ),
      );
    } else if (table.status == TableStatus.occupied ||
        table.status == TableStatus.reserved) {
      context.read<NavigationProvider>().selectTable(
        table.id,
        table.name,
        dashboardProvider.selectedLocation,
      );
    }
  }

  Future<void> _handleTableLongPress(RestaurantTable table) async {
    await HapticHelper.triggerFeedback();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.cleaning_services,
              color: Colors.blue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('${table.name} - Cleaning Request')),
          ],
        ),
        content: const Text(
          'Send cleaning request to KOT team for this table?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCleaningRequest(table);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Send Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showReservationPage(
    RestaurantTable table,
    TableProvider tableProvider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableReservationView(
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

  void _sendCleaningRequest(RestaurantTable table) async {
    await HapticHelper.triggerFeedback();
    _showSnackBar('Cleaning request sent for ${table.name}', Colors.blue);
    // TODO: Send to KOT team via API
    print('Cleaning request sent for table: ${table.id}');
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
