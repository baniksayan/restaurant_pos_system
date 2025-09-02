// lib/presentation/views/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../view_models/providers/navigation_provider.dart';
import '../view_models/providers/animated_cart_provider.dart';
import 'dashboard/waiter_dashboard_view.dart';
import 'menu_management/menu_view.dart';
import 'order_taking/cart/cart_view.dart';
import 'reports/reports_view.dart';
import '../../core/themes/app_colors.dart';
import '../../shared/widgets/overlays/cart_animation_overlay.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<CartAnimationOverlayState> _overlayKey = GlobalKey<CartAnimationOverlayState>();

  // Updated navigation items - removed Profile
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
      icon: Icons.analytics,
      label: 'Reports',
      activeColor: Colors.red,
    ),
  ];

  void _handleAddToCart(
    String itemId,
    String itemName,
    double price,
    String categoryId,
    String categoryName,
    Offset buttonPosition,
  ) {
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

    // Check if the overlay is available and has the animateToCart method
    final overlayState = _overlayKey.currentState;
    if (overlayState != null && overlayState is CartAnimationOverlayState) {
      overlayState.animateToCart(
        item: flyingItem,
        startPosition: buttonPosition,
        onComplete: () {
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          Provider.of<AnimatedCartProvider>(context, listen: false).addItem(
            itemId,
            itemName,
            price,
            navProvider.selectedTableId ?? '',
            navProvider.selectedTableName ?? '',
            categoryId: categoryId,
            categoryName: categoryName,
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
    } else {
      // Fallback if animation overlay is not available
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      Provider.of<AnimatedCartProvider>(context, listen: false).addItem(
        itemId,
        itemName,
        price,
        navProvider.selectedTableId ?? '',
        navProvider.selectedTableName ?? '',
        categoryId: categoryId,
        categoryName: categoryName,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName added to cart!'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

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
      child: Consumer<NavigationProvider>(
        builder: (context, navProvider, _) {
          return Scaffold(
            body: CartAnimationOverlay(
              key: _overlayKey,
              child: IndexedStack(
                index: navProvider.currentIndex,
                children: [
                  // Tables Tab
                  WaiterDashboardView(
                    onTableSelected: (tableId, tableName) {
                      navProvider.selectTable(
                        tableId,
                        tableName,
                        navProvider.selectedLocation ?? '',
                      );
                    },
                  ),
                  // Menu Tab
                  MenuView(
                    selectedTableId: navProvider.selectedTableId,
                    tableName: navProvider.selectedTableName,
                    selectedLocation: navProvider.selectedLocation,
                    onAddToCart: _handleAddToCart,
                  ),
                  // Cart Tab
                  CartView(
                    tableId: navProvider.selectedTableId,
                    tableName: navProvider.selectedTableName,
                    selectedLocation: navProvider.selectedLocation,
                  ),
                  // Reports Tab (moved from index 4 to index 3)
                  const ReportsView(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(context, navProvider),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    NavigationProvider navProvider,
  ) {
    return Consumer<AnimatedCartProvider>(
      builder: (context, cartProvider, _) {
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
              // Inactive icons row
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
                        onTap: () => navProvider.navigateToIndex(index),
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    _navigationItems[index].icon,
                                    size: navProvider.currentIndex == index ? 0 : 20,
                                    color: navProvider.currentIndex == index
                                        ? Colors.transparent
                                        : Colors.grey[600],
                                  ),
                                  if (index == 2 && // Cart tab
                                      cartProvider.totalItems > 0 &&
                                      navProvider.currentIndex != 2)
                                    Positioned(
                                      right: -8,
                                      top: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF6B6B),
                                              Color(0xFFFF8E53),
                                            ],
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
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          '${cartProvider.totalItems > 99 ? '99+' : cartProvider.totalItems}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
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
                                  fontWeight: navProvider.currentIndex == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: navProvider.currentIndex == index
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
              // Active/floating tab
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: (navProvider.currentIndex * MediaQuery.of(context).size.width / 4) +
                    (MediaQuery.of(context).size.width / 4 / 2) - 25,
                top: 8,
                child: _buildFloatingActiveTab(cartProvider, navProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActiveTab(
    AnimatedCartProvider cartProvider,
    NavigationProvider navProvider,
  ) {
    final activeItem = _navigationItems[navProvider.currentIndex];

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
          child: Icon(activeItem.icon, color: Colors.white, size: 24),
        ),
        if (navProvider.currentIndex == 2 && cartProvider.totalItems > 0)
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
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
}

// Navigation item model
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
