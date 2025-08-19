import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:vibration/vibration.dart';
import 'package:restaurant_pos_system/presentation/views/menu_management/menu_view.dart';
import '../../../core/themes/app_colors.dart';
import '../../../shared/widgets/animations/fade_in_animation.dart';
import '../../view_models/providers/auth_provider.dart';
import '../../../data/local/models/table_model.dart';
import '../auth/login_view.dart';
import '../table_management/table_detail_view.dart';
import '../../../shared/widgets/drawers/location_drawer.dart';
import '../../../shared/widgets/layout/location_header.dart';
import '../../../services/sync_service.dart';
import '../../view_models/providers/table_provider.dart';

class WaiterDashboardView extends StatefulWidget {
  final Function(String tableId, String tableName)? onTableSelected;

  const WaiterDashboardView({super.key, this.onTableSelected});

  @override
  State<WaiterDashboardView> createState() => _WaiterDashboardViewState();
}

class _WaiterDashboardViewState extends State<WaiterDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedLocation = 'Main Hall';

  final List<LocationSection> _locations = [
    LocationSection('All', Icons.all_inclusive, Colors.grey),
    LocationSection('Main Hall', Icons.home, Colors.blue),
    LocationSection('VIP Section', Icons.star, Colors.purple),
    LocationSection('Terrace', Icons.deck, Colors.orange),
    LocationSection('Garden Area', Icons.local_florist, Colors.green),
    LocationSection('Balcony', Icons.balcony, Colors.teal),
    LocationSection('Private Room', Icons.meeting_room, Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().initializeTables();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Consumer<TableProvider>(
        builder: (context, tableProvider, child) {
          // Handle loading state
          if (tableProvider.isLoading) {
            return _buildLoadingState();
          }

          // Handle error state with retry
          if (tableProvider.error != null) {
            return _buildErrorState(tableProvider);
          }

          // Get tables for selected location
          final tables = tableProvider.getTablesForLocation(_selectedLocation);

          // Handle empty tables state
          if (tables.isEmpty) {
            return _buildEmptyState();
          }

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.grey[50],
            drawer: LocationDrawer(
              locations: _locations,
              selectedLocation: _selectedLocation,
              onLocationChanged: _handleLocationChange,
            ),
            body: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  _buildOptimizedHeader(),
                  LocationHeader(
                    selectedLocation: _selectedLocation,
                    locations: _locations,
                    tables: tables,
                  ),
                  Expanded(child: _buildTableGrid(tables)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableGrid(List<RestaurantTable> tables) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return _buildEnhancedTableCard(table, context.read<TableProvider>());
      },
    );
  }

  // Loading state with better UX
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading tables...',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // Error state with clear retry action
  Widget _buildErrorState(TableProvider tableProvider) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Tables',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tableProvider.error ?? 'Unknown error occurred',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      tableProvider.clearError();
                    },
                    child: const Text('Clear Error'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      tableProvider.clearError();
                      tableProvider.initializeTables();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty state for better UX
  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Tables Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tables found for $_selectedLocation',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  () => _showLocationSelector(
                    context,
                    context.read<TableProvider>(),
                  ),
              icon: const Icon(Icons.location_on),
              label: const Text('Change Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced header with location selector
  Widget _buildOptimizedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 22),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'WiZARD Restaurant',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Location filter button
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed:
                    () => _showLocationSelector(
                      context,
                      context.read<TableProvider>(),
                    ),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
                tooltip: 'Filter by Location',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.sync,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: _handleSync,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: const EdgeInsets.all(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Enhanced Table Card with Proper ReservationInfo Access
  Widget _buildEnhancedTableCard(
    RestaurantTable table,
    TableProvider tableProvider,
  ) {
    final cardData = _getEnhancedCardData(table);

    return GestureDetector(
      onTap: () => _handleTableClick(table, tableProvider),
      onLongPress: () => _handleTableLongPress(table, tableProvider),
      child: Container(
        decoration: BoxDecoration(
          gradient: cardData['gradient'],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardData['borderColor'], width: 2),
          boxShadow: [
            BoxShadow(
              color: cardData['borderColor'].withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),

          // child: Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     // LIVE status indicator
          //     Row(
          //       children: [
          //         Container(
          //           width: 8,
          //           height: 8,
          //           decoration: BoxDecoration(
          //             color: _getLiveStatusColor(table.status),
          //             shape: BoxShape.circle,
          //           ),
          //         ),
          //         const SizedBox(width: 4),
          //         Text(
          //           'LIVE',
          //           style: TextStyle(
          //             fontSize: 8,
          //             fontWeight: FontWeight.bold,
          //             color: _getLiveStatusColor(table.status),
          //           ),
          //         ),
          //         const Spacer(),
          //         if (table.status == TableStatus.reserved)
          //           const Icon(Icons.schedule, size: 12, color: Colors.orange),
          //       ],
          //     ),

          //     const SizedBox(height: 8),

          //     // Icon with capacity indicator
          //     Stack(
          //       children: [
          //         Container(
          //           width: 40,
          //           height: 40,
          //           decoration: BoxDecoration(
          //             color: cardData['borderColor'].withOpacity(0.2),
          //             borderRadius: BorderRadius.circular(12),
          //           ),
          //           child: Icon(
          //             Icons.table_restaurant,
          //             color: cardData['borderColor'],
          //             size: 22,
          //           ),
          //         ),
          //         if (table.status == TableStatus.occupied)
          //           Positioned(
          //             right: -2,
          //             top: -2,
          //             child: Container(
          //               width: 16,
          //               height: 16,
          //               decoration: const BoxDecoration(
          //                 color: Colors.red,
          //                 shape: BoxShape.circle,
          //               ),
          //               child: const Icon(
          //                 Icons.person,
          //                 size: 10,
          //                 color: Colors.white,
          //               ),
          //             ),
          //           ),
          //       ],
          //     ),

          //     const SizedBox(height: 10),

          //     // Table name
          //     Text(
          //       table.name,
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //         color: cardData['textColor'],
          //       ),
          //       maxLines: 1,
          //       overflow: TextOverflow.ellipsis,
          //     ),

          //     const SizedBox(height: 3),

          //     // Capacity
          //     Text(
          //       'Capacity: ${table.capacity}',
          //       style: const TextStyle(
          //         fontSize: 12,
          //         color: Colors.grey,
          //         fontWeight: FontWeight.w500,
          //       ),
          //     ),

          //     const SizedBox(height: 6),

          //     // Status badge
          //     Container(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 10,
          //         vertical: 4,
          //       ),
          //       decoration: BoxDecoration(
          //         color: cardData['borderColor'],
          //         borderRadius: BorderRadius.circular(16),
          //         boxShadow: [
          //           BoxShadow(
          //             color: cardData['borderColor'].withOpacity(0.25),
          //             blurRadius: 3,
          //             offset: const Offset(0, 1),
          //           ),
          //         ],
          //       ),
          //       child: Text(
          //         table.status.name.toUpperCase(),
          //         style: const TextStyle(
          //           fontSize: 10,
          //           color: Colors.white,
          //           fontWeight: FontWeight.bold,
          //           letterSpacing: 0.2,
          //         ),
          //       ),
          //     ),

          //     // ✅ FIXED: Proper reservation info display with null safety
          //     if (table.status == TableStatus.reserved &&
          //         table.reservationInfo != null) ...[
          //       const SizedBox(height: 4),
          //       Text(
          //         table.reservationInfo!.timeRange,
          //         style: const TextStyle(
          //           fontSize: 8,
          //           color: Colors.orange,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       Text(
          //         table.reservationInfo!.customerName,
          //         style: const TextStyle(fontSize: 7, color: Colors.orange),
          //         maxLines: 1,
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //     ],
          //   ],
          // ), //eklfweklflkfnffnlkffffffff
          child: Container(
            height: 145, // Constrain height to prevent overflow
            padding: const EdgeInsets.all(6), // REDUCED
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LIVE status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getLiveStatusColor(table.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: _getLiveStatusColor(table.status),
                          ),
                        ),
                      ],
                    ),
                    if (table.status == TableStatus.reserved)
                      const Icon(
                        Icons.schedule,
                        size: 10,
                        color: Colors.orange,
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Icon with capacity indicator
                Stack(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: cardData['borderColor'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.table_restaurant,
                        color: cardData['borderColor'],
                        size: 20,
                      ),
                    ),
                    if (table.status == TableStatus.occupied)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                // Table name
                Text(
                  table.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cardData['textColor'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Capacity
                Text(
                  'Capacity: ${table.capacity}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cardData['borderColor'],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cardData['borderColor'].withOpacity(0.25),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    table.status.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Conditional reservation info
                if (table.status == TableStatus.reserved &&
                    table.reservationInfo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    table.reservationInfo!.timeRange,
                    style: const TextStyle(
                      fontSize: 6,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    table.reservationInfo!.customerName,
                    style: const TextStyle(fontSize: 6, color: Colors.orange),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ), // jhvhdvhvhjhvfffffffffffffffffh
          ),
        ),
      ),
    );
  }

  // Location selector dialog
  void _showLocationSelector(
    BuildContext context,
    TableProvider tableProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Select Location'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  final isSelected = _selectedLocation == location.name;

                  return ListTile(
                    leading: Icon(
                      location.icon,
                      color: isSelected ? AppColors.primary : location.color,
                    ),
                    title: Text(
                      location.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    trailing:
                        isSelected
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                    selected: isSelected,
                    onTap: () {
                      _handleLocationChange(location.name);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  // Handle long press for cleaning requests
  Future<void> _handleTableLongPress(
    RestaurantTable table,
    TableProvider tableProvider,
  ) async {
    await _triggerHapticFeedback();

    if (!mounted) return;

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
                Text('${table.name} - Cleaning Request'),
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

  // ✅ FIXED: Trigger haptic feedback with proper import
  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 100, amplitude: 128);
      }
      await HapticFeedback.lightImpact();
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }

  // Send cleaning request
  void _sendCleaningRequest(RestaurantTable table) async {
    await _triggerHapticFeedback();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cleaning_services, color: Colors.white),
            const SizedBox(width: 8),
            Text('Cleaning request sent for ${table.name}'),
          ],
        ),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cleaning request cancelled'),
                backgroundColor: Colors.grey,
              ),
            );
          },
        ),
      ),
    );

    // TODO: Send to KOT team via API
    print('Cleaning request sent for table: ${table.id}');
  }

  // Get live status color
  Color _getLiveStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get card styling data
  Map<String, dynamic> _getEnhancedCardData(RestaurantTable table) {
    switch (table.status) {
      case TableStatus.available:
        return {
          'gradient': const LinearGradient(
            colors: [Colors.white, Color(0xFFF0FFF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'borderColor': const Color(0xFF10B981),
          'textColor': const Color(0xFF047857),
        };
      case TableStatus.occupied:
        return {
          'gradient': const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'borderColor': const Color(0xFFEF4444),
          'textColor': const Color(0xFFDC2626),
        };
      case TableStatus.reserved:
        return {
          'gradient': const LinearGradient(
            colors: [Colors.white, Color(0xFFFFFBF0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'borderColor': const Color(0xFFF59E0B),
          'textColor': const Color(0xFFD97706),
        };
    }
  }

  // Enhanced table click handler with reservation system
  void _handleTableClick(
    RestaurantTable table,
    TableProvider tableProvider,
  ) async {
    await _triggerHapticFeedback();

    if (table.status == TableStatus.available) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('${table.name} - Available'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('What would you like to do with this table?'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Capacity: ${table.capacity} persons',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showReservationPage(table, tableProvider);
                  },
                  icon: const Icon(Icons.schedule, size: 18),
                  label: const Text('Reserve Table'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    tableProvider.updateTableStatus(table.id, 'occupied');
                    widget.onTableSelected?.call(table.id, table.name);
                  },
                  icon: const Icon(Icons.restaurant_menu, size: 18),
                  label: const Text('Occupy & Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                  ),
                ),
              ],
            ),
      );
    } else if (table.status == TableStatus.occupied ||
        table.status == TableStatus.reserved) {
      widget.onTableSelected?.call(table.id, table.name);
    }
  }

  // Show reservation page (placeholder)
  void _showReservationPage(
    RestaurantTable table,
    TableProvider tableProvider,
  ) {
    _showSnackBar(
      'Reservation feature coming soon for ${table.name}',
      Colors.orange,
    );
  }

  void _navigateToMenuForTable(RestaurantTable table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MenuView(selectedTableId: table.id, tableName: table.name),
      ),
    );
  }

  void _handleLocationChange(String location) {
    if (mounted) {
      setState(() => _selectedLocation = location);
      Navigator.of(context).pop();
      _showSnackBar('Switched to $location', Colors.blue);
    }
  }

  Future<void> _handleSync() async {
    try {
      final success = await SyncService.syncAllData();
      if (mounted) {
        _showSnackBar(
          success
              ? 'Data synced successfully!'
              : 'Sync failed. Please try again.',
          success ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Sync error: ${e.toString()}', Colors.red);
      }
    }
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

class LocationSection {
  final String name;
  final IconData icon;
  final Color color;

  LocationSection(this.name, this.icon, this.color);
}
