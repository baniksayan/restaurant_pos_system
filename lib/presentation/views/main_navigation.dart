// lib/presentation/views/main_navigation.dart
import 'package:flutter/material.dart';
import 'dashboard/waiter_dashboard_view.dart';
import 'menu_management/menu_view.dart';
import 'order_taking/cart_view.dart';
import 'settings/profile_view.dart';
import 'reports/reports_view.dart';
import '../../core/themes/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const WaiterDashboardView(),
    const MenuView(),
    const CartView(),
    const ProfileView(),
    const ReportsView(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.table_restaurant,
      label: 'Tables',
      activeColor: AppColors.primary,
    ),
    NavigationItem(
      icon: Icons.restaurant_menu,
      label: 'Menu',
      activeColor: Colors.orange,
    ),
    NavigationItem(
      icon: Icons.shopping_cart,
      label: 'Cart',
      activeColor: Colors.green,
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Profile',
      activeColor: Colors.purple,
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Reports',
      activeColor: Colors.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 75, // ✅ OPTIMIZED: Reduced from 85 to 75
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // ✅ OPTIMIZED: Reduced shadow opacity
            blurRadius: 15, // ✅ OPTIMIZED: Reduced from 20
            offset: const Offset(0, -3), // ✅ OPTIMIZED: Reduced from -5
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background navigation items
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 55, // ✅ OPTIMIZED: Reduced from 65
            child: Row(
              children: List.generate(
                _navigationItems.length,
                (index) => Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _navigationItems[index].icon,
                            size: _currentIndex == index ? 0 : 20, // ✅ OPTIMIZED: Reduced from 24
                            color: _currentIndex == index 
                                ? Colors.transparent 
                                : Colors.grey[600],
                          ),
                          const SizedBox(height: 2), // ✅ OPTIMIZED: Reduced from 4
                          Text(
                            _navigationItems[index].label,
                            style: TextStyle(
                              fontSize: 11, // ✅ OPTIMIZED: Reduced from 12
                              fontWeight: _currentIndex == index 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                              color: _currentIndex == index 
                                  ? _navigationItems[index].activeColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Floating active tab indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: (_currentIndex * MediaQuery.of(context).size.width / 5) + 
                   (MediaQuery.of(context).size.width / 5 / 2) - 25, // ✅ OPTIMIZED: Better centering
            top: 8, // ✅ OPTIMIZED: Adjusted from 5
            child: _buildFloatingActiveTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActiveTab() {
    final activeItem = _navigationItems[_currentIndex];
    
    return Container(
      width: 50, // ✅ OPTIMIZED: Reduced from 60
      height: 50, // ✅ OPTIMIZED: Reduced from 60
      decoration: BoxDecoration(
        color: activeItem.activeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: activeItem.activeColor.withOpacity(0.25), // ✅ OPTIMIZED: Reduced opacity
            blurRadius: 12, // ✅ OPTIMIZED: Reduced from 15
            offset: const Offset(0, 3), // ✅ OPTIMIZED: Reduced from 5
          ),
        ],
      ),
      child: Icon(
        activeItem.icon,
        color: Colors.white,
        size: 24, // ✅ OPTIMIZED: Reduced from 28
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}
