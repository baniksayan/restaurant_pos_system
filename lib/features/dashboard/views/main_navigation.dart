// lib/features/dashboard/views/main_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/auth/providers/auth_provider.dart';
import 'waiter_dashboard_view.dart';
import 'package:restaurant_pos_system/features/menu/views/menu_view.dart';
import 'package:restaurant_pos_system/features/order_taking/views/cart_view.dart';
import 'package:restaurant_pos_system/features/reports/views/reports_view.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/shared/widgets/overlays/cart_animation_overlay.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<CartAnimationOverlayState> _overlayKey =
      GlobalKey<CartAnimationOverlayState>();

  late PageController _pageController;
  NavigationProvider? _navProvider;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Check if we need to auto-select a table and navigate to menu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAutoTableSelection();

      // Jump page controller to initial index
      final navProvider = Provider.of<NavigationProvider>(
        context,
        listen: false,
      );
      if (_pageController.hasClients) {
        _pageController.jumpToPage(navProvider.currentIndex);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    if (_navProvider != navProvider) {
      _navProvider?.removeListener(_onNavProviderChanged);
      _navProvider = navProvider;
      _navProvider?.addListener(_onNavProviderChanged);
    }
  }

  @override
  void dispose() {
    _navProvider?.removeListener(_onNavProviderChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onNavProviderChanged() {
    if (_navProvider != null && _pageController.hasClients) {
      final int targetIndex = _navProvider!.currentIndex;
      final int currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != targetIndex) {
        // If moving to or from Reports (index 3), jump instantly to avoid layout glitches
        if (targetIndex == 3 || currentPage == 3) {
          _pageController.jumpToPage(targetIndex);
        } else {
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
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
          return PopScope(
            canPop: navProvider.currentIndex == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              navProvider.navigateToIndex(0);
            },
            child: Scaffold(
            body: CartAnimationOverlay(
              key: _overlayKey,
              child: PageView(
                controller: _pageController,
                physics:
                    navProvider.currentIndex == 3
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  if (navProvider.currentIndex != index) {
                    navProvider.navigateToIndex(index);
                  }
                },
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
                  if (navProvider.currentIndex == 3) const ReportsView(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(
              context,
              navProvider,
            ),
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
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: List.generate(_navigationItems.length, (index) {
                  final int safeCurrentIndex =
                      navProvider.currentIndex.clamp(
                        0,
                        _navigationItems.length - 1,
                      );
                  final bool isSelected = index == safeCurrentIndex;
                  final item = _navigationItems[index];
                  return Expanded(
                    child: _NavBarItem(
                      item: item,
                      isSelected: isSelected,
                      totalCartItems: cartProvider.newItemsCount,
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.selectionClick();
                          navProvider.navigateToIndex(index);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final int totalCartItems;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.totalCartItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCart = item.icon == Icons.shopping_cart;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? item.activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: item.activeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 280),
                    tween: ColorTween(
                      begin: Colors.grey[500],
                      end: isSelected ? Colors.white : Colors.grey[500],
                    ),
                    builder: (context, color, _) {
                      return Icon(item.icon, color: color, size: 24);
                    },
                  ),
                ),
                if (isCart && totalCartItems > 0)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? item.activeColor : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '${totalCartItems > 99 ? '99+' : totalCartItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child:
                  isSelected
                      ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: isSelected ? 1 : 0,
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
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
