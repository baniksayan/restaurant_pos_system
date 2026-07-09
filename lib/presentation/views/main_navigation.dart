// lib/presentation/views/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../view_models/providers/navigation_provider.dart';
import '../view_models/providers/animated_cart_provider.dart';
import '../view_models/providers/menu_provider.dart';
import '../view_models/providers/auth_provider.dart';
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
  final GlobalKey<CartAnimationOverlayState> _overlayKey =
      GlobalKey<CartAnimationOverlayState>();

  @override
  void initState() {
    super.initState();
    // Check if we need to auto-select a table and navigate to menu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAutoTableSelection();
    });
  }

  void _handleAutoTableSelection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    if (authProvider.shouldNavigateDirectlyToMenu &&
        authProvider.autoSelectedTableId != null &&
        authProvider.autoSelectedTableName != null) {
      // Auto-select the table and navigate to menu
      navProvider.selectTableAndNavigateToMenu(
        authProvider.autoSelectedTableId!,
        authProvider.autoSelectedTableName!,
        'Main Hall', // Default location
      );

      // Reset the auto navigation flags
      authProvider.resetAutoNavigationFlags();
    }
  }

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
    // NavigationItem(
    //   icon: Icons.analytics,
    //   label: 'Reports',
    //   activeColor: Colors.red,
    // ),
  ];

  void _handleAddToCart(
    String itemId,
    String itemName,
    double price,
    String categoryId,
    String categoryName,
    Offset buttonPosition,
  ) {
    // Immediate add-to-cart (no flying animation). Keep providers in sync.
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final animatedCartProvider = Provider.of<AnimatedCartProvider>(
      context,
      listen: false,
    );

    // Handle both table orders and phone/takeaway orders
    String tableId = navProvider.selectedTableId ?? '';
    String tableName = navProvider.selectedTableName ?? '';

    // For Phone/Takeaway orders, create a virtual table ID based on order type
    if (tableId.isEmpty && navProvider.selectedOrderType != null) {
      tableId = navProvider.selectedOrderType!; // 'PhoneOrder' or 'Takeaway'
      tableName =
          navProvider.selectedOrderType == 'PhoneOrder'
              ? 'Phone Order - ${navProvider.customerName ?? "Unknown"}'
              : 'Takeaway - ${navProvider.customerName ?? "Unknown"}';
    }

    // Ensure both providers are on the same context for proper state isolation
    if (tableId.isNotEmpty) {
      // Switch menu provider to current context if not already
      if (menuProvider.currentTableId != tableId) {
        menuProvider.switchToTable(tableId);
      }

      // Switch cart provider to current context if not already
      if (animatedCartProvider.currentTableId != tableId) {
        animatedCartProvider.switchToTable(tableId);
      }
    }

    // Add item only to AnimatedCartProvider (MenuProvider no longer tracks cart)
    animatedCartProvider.addItem(
      itemId,
      itemName,
      price,
      tableId,
      tableName,
      categoryId: categoryId,
      categoryName: categoryName,
    );

    // MenuProvider no longer tracks cart quantities - removed sync

    // Removed green SnackBar per project request: item added to cart message
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
                    tableId:
                        navProvider.selectedTableId ??
                        navProvider.selectedOrderType,
                    tableName:
                        navProvider.selectedTableName ??
                        (navProvider.selectedOrderType == 'PhoneOrder'
                            ? 'Phone Order - ${navProvider.customerName ?? "Unknown"}'
                            : navProvider.selectedOrderType == 'Takeaway'
                            ? 'Takeaway - ${navProvider.customerName ?? "Unknown"}'
                            : null),
                    selectedLocation: navProvider.selectedLocation,
                  ),
                  // Reports Tab (moved from index 4 to index 3)
                  const ReportsView(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(
              context,
              navProvider,
            ),
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
                                    size:
                                        navProvider.currentIndex == index
                                            ? 0
                                            : 20,
                                    color:
                                        navProvider.currentIndex == index
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFFF6B6B,
                                              ).withOpacity(0.4),
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
                                  fontWeight:
                                      navProvider.currentIndex == index
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      navProvider.currentIndex == index
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
                left:
                    navProvider.currentIndex < _navigationItems.length
                        ? (navProvider.currentIndex *
                                MediaQuery.of(context).size.width /
                                _navigationItems.length) +
                            (MediaQuery.of(context).size.width /
                                _navigationItems.length /
                                2) -
                            25
                        : -100.0, // Move offscreen if active tab is out of bottom bar range
                top: 8,
                child:
                    navProvider.currentIndex < _navigationItems.length
                        ? _buildFloatingActiveTab(cartProvider, navProvider)
                        : const SizedBox.shrink(),
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
