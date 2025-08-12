// lib/presentation/views/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dashboard/waiter_dashboard_view.dart';
import 'menu_management/menu_view.dart';
import 'order_taking/cart_view.dart';
import 'settings/profile_view.dart';
import 'reports/reports_view.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/providers/animated_cart_provider.dart';
import '../../shared/widgets/overlays/cart_animation_overlay.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String? _selectedTableId;
  String? _selectedTableName;
  
  final GlobalKey<CartAnimationOverlayState> _overlayKey = GlobalKey();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.table_restaurant, label: 'Tables', activeColor: AppColors.primary),
    NavigationItem(icon: Icons.restaurant_menu, label: 'Menu', activeColor: Colors.orange),
    NavigationItem(icon: Icons.shopping_cart, label: 'Cart', activeColor: Colors.green),
    NavigationItem(icon: Icons.person, label: 'Profile', activeColor: Colors.purple),
    NavigationItem(icon: Icons.analytics, label: 'Reports', activeColor: Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: CartAnimationOverlay(
          key: _overlayKey,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              WaiterDashboardView(
                onTableSelected: (tableId, tableName) {
                  _selectTableAndGoToMenu(tableId, tableName);
                },
              ),
              MenuView(
                selectedTableId: _selectedTableId,
                tableName: _selectedTableName,
                onAddToCart: _handleAddToCart,
              ),
              const CartView(),
              const ProfileView(),
              const ReportsView(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  void _handleAddToCart(String itemId, String itemName, double price, Offset buttonPosition) {
    final flyingItem = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.restaurant, color: Colors.white, size: 25),
    );

    _overlayKey.currentState?.animateToCart(
      item: flyingItem,
      startPosition: buttonPosition,
      onComplete: () {
        Provider.of<AnimatedCartProvider>(context, listen: false).addItem(
          itemId,
          itemName,
          price,
          _selectedTableId ?? '',
          _selectedTableName ?? '',
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName added to cart!'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
      },
    );
  }

  void _selectTableAndGoToMenu(String tableId, String tableName) {
    setState(() {
      _selectedTableId = tableId;
      _selectedTableName = tableName;
      _currentIndex = 1;
    });
  }

  Widget _buildBottomNavigationBar() {
    return Consumer<AnimatedCartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          height: 75,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 55,
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
                              Stack(
                                clipBehavior: Clip.none, // 👈 Allow badge to overflow
                                children: [
                                  Icon(
                                    _navigationItems[index].icon,
                                    size: _currentIndex == index ? 0 : 20,
                                    color: _currentIndex == index 
                                        ? Colors.transparent 
                                        : Colors.grey[600],
                                  ),
                                  // 🎨 IMPROVED Cart Badge Design
                                  if (index == 2 && cartProvider.totalItems > 0 && _currentIndex != 2) // Hide when cart tab is active
                                    Positioned(
                                      right: -8, // 👈 Move further right
                                      top: -8,   // 👈 Move further up
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient( // 👈 Beautiful gradient instead of flat red
                                            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: Border.all(color: Colors.white, width: 2), // 👈 White border for contrast
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          '${cartProvider.totalItems > 99 ? '99+' : cartProvider.totalItems}', // 👈 Handle large numbers
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0, // 👈 Better text alignment
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _navigationItems[index].label,
                                style: TextStyle(
                                  fontSize: 11,
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
              
              // Floating active tab with cart badge when cart is active
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: (_currentIndex * MediaQuery.of(context).size.width / 5) + 
                       (MediaQuery.of(context).size.width / 5 / 2) - 25,
                top: 8,
                child: _buildFloatingActiveTab(cartProvider), // 👈 Pass cart provider
              ),
            ],
          ),
        );
      },
    );
  }

  // Updated floating active tab to show cart badge
  Widget _buildFloatingActiveTab(AnimatedCartProvider cartProvider) {
    final activeItem = _navigationItems[_currentIndex];
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: activeItem.activeColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: activeItem.activeColor.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            activeItem.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        
        // 🎨 Cart badge on floating tab when cart is active
        if (_currentIndex == 2 && cartProvider.totalItems > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '${cartProvider.totalItems > 99 ? '99+' : cartProvider.totalItems}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      
      if (index != 1) {
        _selectedTableId = null;
        _selectedTableName = null;
      }
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
