import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../shared/widgets/animations/fade_in_animation.dart';
import '../../view_models/providers/auth_provider.dart';
import '../../../data/models/table.dart';
import '../auth/login_view.dart';
import '../table_management/table_detail_view.dart';
import '../../../shared/widgets/app_bars/waiter_app_bar.dart';
import '../../../shared/widgets/drawers/location_drawer.dart';
import '../../../shared/widgets/cards/table_card.dart';
import '../../../shared/widgets/layout/location_header.dart';

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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      
      appBar: WaiterAppBar(
        isMobile: isMobile,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onLogout: _handleLogout,
      ),

      drawer: LocationDrawer(
        locations: _locations,
        selectedLocation: _selectedLocation,
        onLocationChanged: (location) {
          setState(() {
            _selectedLocation = location;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Switched to $location')),
          );
        },
      ),

      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            LocationHeader(
              selectedLocation: _selectedLocation,
              locations: _locations,
              tables: _getTablesForLocation(_selectedLocation),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _getTablesForLocation(_selectedLocation).length,
                  itemBuilder: (context, index) {
                    final table = _getTablesForLocation(_selectedLocation)[index];
                    return FadeInAnimation(
                      delay: Duration(milliseconds: 50 * index),
                      child: TableCard(
                        table: table,
                        onTap: () => _handleTableClick(table, context),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTableClick(RestaurantTable table, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${table.name} clicked - ${table.status.name.toUpperCase()}'),
        duration: const Duration(seconds: 1),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TableDetailView(table: table),
      ),
    );
  }

  List<RestaurantTable> _getTablesForLocation(String location) {
    switch (location) {
      case 'Main Hall':
        return [
          RestaurantTable(id: '1', name: 'Table 1', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '2', name: 'Table 2', capacity: 2, status: TableStatus.occupied, kotGenerated: true, billGenerated: false),
          RestaurantTable(id: '3', name: 'Table 3', capacity: 6, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '4', name: 'Table 4', capacity: 4, status: TableStatus.occupied, kotGenerated: true, billGenerated: true),
          RestaurantTable(id: '5', name: 'Table 5', capacity: 8, status: TableStatus.reserved, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '6', name: 'Table 6', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '7', name: 'Table 7', capacity: 2, status: TableStatus.cleaning, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '8', name: 'Table 8', capacity: 6, status: TableStatus.occupied, kotGenerated: false, billGenerated: false),
        ];
      case 'VIP Section':
        return [
          RestaurantTable(id: '9', name: 'VIP 1', capacity: 10, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '10', name: 'VIP 2', capacity: 8, status: TableStatus.occupied, kotGenerated: true, billGenerated: false),
          RestaurantTable(id: '11', name: 'VIP 3', capacity: 6, status: TableStatus.reserved, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '12', name: 'VIP 4', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
        ];
      case 'Terrace':
        return [
          RestaurantTable(id: '13', name: 'Terrace 1', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '14', name: 'Terrace 2', capacity: 6, status: TableStatus.occupied, kotGenerated: true, billGenerated: true),
          RestaurantTable(id: '15', name: 'Terrace 3', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
        ];
      case 'Garden Area':
        return [
          RestaurantTable(id: '16', name: 'Garden 1', capacity: 6, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '17', name: 'Garden 2', capacity: 8, status: TableStatus.occupied, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '18', name: 'Garden 3', capacity: 4, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '19', name: 'Garden 4', capacity: 10, status: TableStatus.reserved, kotGenerated: false, billGenerated: false),
        ];
      case 'Balcony':
        return [
          RestaurantTable(id: '20', name: 'Balcony 1', capacity: 2, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '21', name: 'Balcony 2', capacity: 4, status: TableStatus.occupied, kotGenerated: true, billGenerated: false),
        ];
      case 'Private Room':
        return [
          RestaurantTable(id: '22', name: 'Private 1', capacity: 12, status: TableStatus.available, kotGenerated: false, billGenerated: false),
          RestaurantTable(id: '23', name: 'Private 2', capacity: 8, status: TableStatus.reserved, kotGenerated: false, billGenerated: false),
        ];
      default:
        return [];
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Shift?'),
          content: const Text('Are you sure you want to logout and end your shift?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }
}

class LocationSection {
  final String name;
  final IconData icon;
  final Color color;

  LocationSection(this.name, this.icon, this.color);
}
