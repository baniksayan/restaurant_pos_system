import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/presentation/views/reservations/table_reservation_view.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../shared/widgets/drawers/location_drawer.dart';
import '../../../shared/widgets/layout/location_header.dart';
import '../../view_models/providers/dashboard_provider.dart';
import '../../view_models/providers/navigation_provider.dart';
import '../../view_models/providers/table_provider.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_states.dart';
import 'widgets/location_selector_dialog.dart';
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
        providers: [ChangeNotifierProvider(create: (_) => DashboardProvider())],
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

            // Get tables for selected location
            final tables = tableProvider.getTablesForLocation(
              dashboardProvider.selectedLocation,
            );

            // Handle empty state
            if (tables.isEmpty) {
              return DashboardEmptyState(
                selectedLocation: dashboardProvider.selectedLocation,
                onChangeLocation:
                    () => _showLocationSelector(context, dashboardProvider),
              );
            }

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.grey[50],
              drawer: LocationDrawer(
                locations: dashboardProvider.locations,
                selectedLocation: dashboardProvider.selectedLocation,
                onLocationChanged: (location) {
                  dashboardProvider.changeLocation(location);
                  _showSnackBar('Switched to $location', Colors.blue);
                },
              ),
              body: Container(
                color: Colors.grey[50],
                child: Column(
                  children: [
                    DashboardHeader(
                      scaffoldKey: _scaffoldKey,
                      onLocationTap:
                          () =>
                              _showLocationSelector(context, dashboardProvider),
                      onSyncTap: () => _handleSync(dashboardProvider),
                    ),
                    LocationHeader(
                      selectedLocation: dashboardProvider.selectedLocation,
                      locations: dashboardProvider.locations,
                      tables: tables,
                    ),
                    Expanded(
                      child: TableGrid(
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
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLocationSelector(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => LocationSelectorDialog(
            locations: dashboardProvider.locations,
            selectedLocation: dashboardProvider.selectedLocation,
            onLocationChanged: (location) {
              dashboardProvider.changeLocation(location);
              _showSnackBar('Switched to $location', Colors.blue);
            },
          ),
    );
  }

  Future<void> _handleSync(DashboardProvider dashboardProvider) async {
    await dashboardProvider.syncData();
    if (dashboardProvider.syncMessage != null && mounted) {
      final isSuccess = dashboardProvider.syncMessage!.contains('successfully');
      _showSnackBar(
        dashboardProvider.syncMessage!,
        isSuccess ? Colors.green : Colors.red,
      );
      dashboardProvider.clearSyncMessage();
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
        builder:
            (context) => TableActionDialog(
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
      builder:
          (context) => AlertDialog(
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
