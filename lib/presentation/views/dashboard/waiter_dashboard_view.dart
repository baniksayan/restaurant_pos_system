// lib/presentation/views/dashboard/waiter_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/presentation/views/menu_management/menu_view.dart';
import '../../../core/themes/app_colors.dart';
import '../../../shared/widgets/animations/fade_in_animation.dart';
import '../../view_models/providers/auth_provider.dart';
import '../../view_models/providers/table_provider.dart';
import '../../../data/models/table.dart';
import '../../../data/local/models/table_model.dart';
import '../auth/login_view.dart';
import '../table_management/table_detail_view.dart';
// import '../menu/menu_view.dart'; // Add this import for menu navigation
import '../../../shared/widgets/drawers/location_drawer.dart';
import '../../../shared/widgets/layout/location_header.dart';
import '../../../services/sync_service.dart';

class WaiterDashboardView extends StatefulWidget {
  const WaiterDashboardView({super.key});

  @override
  State<WaiterDashboardView> createState() => _WaiterDashboardViewState();
}

class _WaiterDashboardViewState extends State<WaiterDashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedLocation = 'Main Hall';

  final List<LocationSection> _locations = [
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

    return Consumer<TableProvider>(
      builder: (context, tableProvider, child) {
        if (tableProvider.isLoading) {
          return _buildLoadingState();
        }

        if (tableProvider.error != null) {
          return _buildErrorState(tableProvider);
        }

        final hiveTables = tableProvider.getTablesForLocation(_selectedLocation);
        final tables = _convertHiveTablesToRestaurantTables(hiveTables);

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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isMobile ? 1.0 : 1.05,
                      ),
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        return FadeInAnimation(
                          delay: Duration(milliseconds: 50 * index),
                          child: _buildOptimizedTableCard(table, tableProvider),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptimizedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardShadow, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.sync, color: AppColors.primary, size: 20),
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

  Widget _buildOptimizedTableCard(RestaurantTable table, TableProvider tableProvider) {
    final cardData = _getEnhancedCardData(table);
    
    return GestureDetector(
      onTap: () => _handleTableClick(table, tableProvider),
      child: Container(
        decoration: BoxDecoration(
          gradient: cardData['gradient'],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardData['borderColor'], width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cardData['borderColor'].withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactIconSection(table, cardData),
              const SizedBox(height: 8),
              Text(
                table.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cardData['textColor'],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Cap: ${table.capacity}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              _buildCompactStatusBadge(table, cardData),
              if (table.status == TableStatus.occupied) ...[
                const SizedBox(height: 5),
                _buildCompactStatusIndicators(table),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIconSection(RestaurantTable table, Map<String, dynamic> cardData) {
    return Stack(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cardData['borderColor'].withOpacity(0.15),
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
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.person, size: 8, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactStatusBadge(RestaurantTable table, Map<String, dynamic> cardData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cardData['borderColor'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cardData['borderColor'].withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        table.status.name.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCompactStatusIndicators(RestaurantTable table) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (table.kotGenerated) _buildMiniIndicator('KOT', Colors.orange),
        if (table.kotGenerated && table.billGenerated) const SizedBox(width: 6),
        if (table.billGenerated) _buildMiniIndicator('BILL', Colors.green),
      ],
    );
  }

  Widget _buildMiniIndicator(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tables...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(TableProvider tableProvider) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Error: ${tableProvider.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => tableProvider.initializeTables(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

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

  // ✅ UPDATED TABLE CLICK HANDLER
  void _handleTableClick(RestaurantTable table, TableProvider tableProvider) {
    if (table.status == TableStatus.available) {
      // For available tables, show occupy/reserve options first
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${table.name} - Available'),
          content: const Text('What would you like to do with this table?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                tableProvider.updateTableStatus(table.id, 'occupied');
                // After occupying, navigate to menu
                _navigateToMenuForTable(table);
              },
              child: const Text('Occupy & Order'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                tableProvider.updateTableStatus(table.id, 'reserved');
                _showSnackBar('${table.name} is now reserved', Colors.orange);
              },
              child: const Text('Reserve Table'),
            ),
          ],
        ),
      );
    } else if (table.status == TableStatus.occupied || table.status == TableStatus.reserved) {
      // For occupied/reserved tables, directly go to menu
      _navigateToMenuForTable(table);
    }
  }

  // lib/presentation/views/dashboard/waiter_dashboard_view.dart
// Update the _navigateToMenuForTable method (around line 454):

void _navigateToMenuForTable(RestaurantTable table) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MenuView(
        selectedTableId: table.id,
        tableName: table.name,
        // Remove this line - tableCapacity parameter doesn't exist:
        // tableCapacity: table.capacity,
      ),
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
          success ? 'Data synced successfully!' : 'Sync failed. Please try again.',
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

  List<RestaurantTable> _convertHiveTablesToRestaurantTables(List<TableModel> hiveTables) {
    if (hiveTables.isEmpty) {
      return _getStaticTablesForLocation(_selectedLocation);
    }
    
    return hiveTables.map((hiveTable) {
      return RestaurantTable(
        id: hiveTable.id,
        name: hiveTable.name,
        capacity: hiveTable.capacity,
        status: TableStatus.values.firstWhere(
          (status) => status.name == hiveTable.status,
          orElse: () => TableStatus.available,
        ),
        kotGenerated: hiveTable.kotGenerated,
        billGenerated: hiveTable.billGenerated,
        lastUpdated: hiveTable.lastUpdated,
      );
    }).toList();
  }

  List<RestaurantTable> _getStaticTablesForLocation(String location) {
    switch (location) {
      case 'Main Hall':
        return [
          RestaurantTable(id: '1', name: 'Table 1', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '2', name: 'Table 2', capacity: 2, status: TableStatus.occupied, kotGenerated: true, billGenerated: false),
          RestaurantTable(id: '3', name: 'Table 3', capacity: 6, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '4', name: 'Table 4', capacity: 4, status: TableStatus.occupied, kotGenerated: true, billGenerated: true),
          RestaurantTable(id: '5', name: 'Table 5', capacity: 8, status: TableStatus.reserved, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '6', name: 'Table 6', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
        ];
      case 'VIP Section':
        return [
          RestaurantTable(id: '9', name: 'VIP 1', capacity: 10, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '10', name: 'VIP 2', capacity: 8, status: TableStatus.occupied, kotGenerated: true, billGenerated: false),
          RestaurantTable(id: '11', name: 'VIP 3', capacity: 6, status: TableStatus.reserved, kotGenerated: false, billGenerated: false),
        ];
      case 'Terrace':
        return [
          RestaurantTable(id: '13', name: 'Terrace 1', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '14', name: 'Terrace 2', capacity: 6, status: TableStatus.occupied, kotGenerated: true, billGenerated: true),
        ];
      case 'Garden Area':
        return [
          RestaurantTable(id: '16', name: 'Garden 1', capacity: 6, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '17', name: 'Garden 2', capacity: 8, status: TableStatus.occupied, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '18', name: 'Garden 3', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
        ];
      case 'Balcony':
        return [
          RestaurantTable(id: '20', name: 'Balcony 1', capacity: 2, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '21', name: 'Balcony 2', capacity: 4, status: TableStatus.occupied, kotGenerated: true, billGenerated: false),
        ];
      case 'Private Room':
        return [
          RestaurantTable(id: '22', name: 'Private 1', capacity: 12, status: TableStatus.available, kotGenerated: false, billGenerated: false),
        ];
      default:
        return [];
    }
  }
}

class LocationSection {
  final String name;
  final IconData icon;
  final Color color;

  LocationSection(this.name, this.icon, this.color);
}
