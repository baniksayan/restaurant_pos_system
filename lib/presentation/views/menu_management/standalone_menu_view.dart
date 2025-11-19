import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/menu_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/table_provider.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';
import 'package:restaurant_pos_system/presentation/views/profile/profile_view.dart';
import 'widgets/menu_search_bar.dart';
import 'widgets/category_tabs.dart';
import 'widgets/menu_grid.dart';
import 'widgets/cart_footer.dart';
import '../order_taking/cart/cart_view.dart';

class StandaloneMenuView extends StatefulWidget {
  final String? autoSelectedTableId;
  final String? autoSelectedTableName;

  const StandaloneMenuView({
    super.key,
    this.autoSelectedTableId,
    this.autoSelectedTableName,
  });

  @override
  State<StandaloneMenuView> createState() => _StandaloneMenuViewState();
}

class _StandaloneMenuViewState extends State<StandaloneMenuView> {
  String? _selectedTableId;
  String? _selectedTableName;
  String _selectedLocation = 'Main Hall';
  bool _isInitialized = false;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMenuWithTable();
    });
  }

  Future<void> _initializeMenuWithTable() async {
    try {
      // Use provided auto-selected table or fetch the first available table
      if (widget.autoSelectedTableId != null &&
          widget.autoSelectedTableName != null) {
        _selectedTableId = widget.autoSelectedTableId;
        _selectedTableName = widget.autoSelectedTableName;

        if (mounted) {
          debugPrint(
            '[StandaloneMenu] Using auto-selected table: $_selectedTableName ($_selectedTableId)',
          );
        }
      } else {
        // Fetch tables and select first available
        final tableProvider = Provider.of<TableProvider>(
          context,
          listen: false,
        );
        await tableProvider.fetchTables();

        final tables = tableProvider.tables;
        if (tables.isNotEmpty && mounted) {
          final availableTable = tables.firstWhere(
            (table) => table.status.toString().contains('available'),
            orElse: () => tables.first,
          );

          _selectedTableId = availableTable.id;
          _selectedTableName = availableTable.name;

          debugPrint(
            '[StandaloneMenu] Auto-selected first available table: $_selectedTableName ($_selectedTableId)',
          );
        }
      }

      if (_selectedTableId != null && mounted) {
        // Switch to selected table for proper state isolation
        await _switchToTable();

        // Load menu data
        final menuProvider = Provider.of<MenuProvider>(context, listen: false);
        final token = HiveService.getAuthToken();
        final outletId = HiveService.getOutletId();
        debugPrint('[StandaloneMenu] Auth token length: ${token.length}');
        debugPrint('[StandaloneMenu] Outlet ID: $outletId');
        debugPrint('[StandaloneMenu] Starting menu data load...');

        if (token.isNotEmpty) {
          final outletId = HiveService.getOutletId();
          debugPrint('[StandaloneMenu] Raw outlet ID from Hive: $outletId');

          if (outletId == null || outletId <= 0) {
            debugPrint('[StandaloneMenu] ❌ No valid outlet ID available');
            debugPrint('[StandaloneMenu] This will prevent menu loading');

            // Show error in UI
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No outlet ID available. Menu cannot be loaded.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }

            setState(() {
              _isInitialized = true;
            });
            return;
          }

          debugPrint('[StandaloneMenu] ✅ Using outlet ID: $outletId');
          await menuProvider.loadMenuData(outletId: outletId);
          debugPrint(
            '[StandaloneMenu] Menu data loaded. Items count: ${menuProvider.apiMenuItems.length}',
          );
          debugPrint(
            '[StandaloneMenu] Filtered items count: ${menuProvider.filteredItems.length}',
          );
          debugPrint(
            '[StandaloneMenu] Categories count: ${menuProvider.categories.length}',
          );
          debugPrint(
            '[StandaloneMenu] Error message: ${menuProvider.errorMessage}',
          );
          debugPrint('[StandaloneMenu] Is loading: ${menuProvider.isLoading}');

          // If menu loading failed, show the error in UI
          if (menuProvider.errorMessage != null) {
            debugPrint(
              '[StandaloneMenu] Menu loading failed: ${menuProvider.errorMessage}',
            );
          }
        } else {
          debugPrint('[StandaloneMenu] No auth token - cannot load menu data');
        }

        setState(() {
          _isInitialized = true;
        });
      } else {
        debugPrint('[StandaloneMenu] No table selected - cannot initialize');
      }
    } catch (e) {
      debugPrint('[StandaloneMenu] Error initializing menu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing menu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _switchToTable() async {
    if (_selectedTableId == null) return;

    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final animatedCartProvider = Provider.of<AnimatedCartProvider>(
      context,
      listen: false,
    );
    final tableProvider = Provider.of<TableProvider>(context, listen: false);

    debugPrint('[StandaloneMenu] Switching to table: $_selectedTableId');

    // Switch menu provider
    menuProvider.switchToTable(_selectedTableId!);

    // Switch cart provider
    animatedCartProvider.switchToTable(_selectedTableId!);

    // **ENHANCED: Load existing cart data for this table (if any order exists)**
    // This handles the case where login already created an order for companySiteUrl="Menu"
    if (tableProvider.currentOrderId != null) {
      debugPrint(
        '[StandaloneMenu] Found existing order: ${tableProvider.currentOrderId}',
      );
      debugPrint('[StandaloneMenu] Loading cart data for background order...');

      // Load existing cart items from the pre-created order
      await tableProvider.loadCartStateForOrder(tableProvider.currentOrderId!);

      debugPrint('[StandaloneMenu] ✅ Cart data loaded for existing order');
    } else {
      debugPrint(
        '[StandaloneMenu] No existing order found - new cart will be created when items are added',
      );
    }

    debugPrint('[StandaloneMenu] Table switch completed');
  }

  void _handleAddToCart(
    String itemId,
    String itemName,
    double price,
    String categoryId,
    String categoryName,
    Offset buttonPosition,
  ) {
    if (_selectedTableId == null) return;

    final animatedCartProvider = Provider.of<AnimatedCartProvider>(
      context,
      listen: false,
    );

    // Add item to cart
    animatedCartProvider.addItem(
      itemId,
      itemName,
      price,
      _selectedTableId!,
      _selectedTableName ?? 'Unknown Table',
      categoryId: categoryId,
      categoryName: categoryName,
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName added to cart for $_selectedTableName!'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _navigateToCart() {
    if (_selectedTableId == null) return;

    final isTablet = MediaQuery.of(context).size.width > 768;

    if (isTablet) {
      // Enhanced tablet navigation with slide transition
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => CartView(
                tableId: _selectedTableId!,
                tableName: _selectedTableName,
                selectedLocation: _selectedLocation,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.fastOutSlowIn;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      // Standard navigation for phones
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => CartView(
                tableId: _selectedTableId!,
                tableName: _selectedTableName,
                selectedLocation: _selectedLocation,
              ),
        ),
      );
    }
  }

  void _navigateToProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileView()));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isTablet ? 70 : 56),
        child: AppBar(
          title: Row(
            children: [
              Text(
                'Menu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 24 : 20,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          toolbarHeight: isTablet ? 70 : 56,
          actions: [
            // Search Button
            IconButton(
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                });
              },
              icon: Icon(
                _showSearchBar ? Icons.close : Icons.search,
                size: isTablet ? 26 : 22,
              ),
            ),
            // Profile Button
            Container(
              margin: EdgeInsets.only(right: isTablet ? 16 : 8),
              child: IconButton(
                onPressed: _navigateToProfile,
                icon: Icon(Icons.person, size: isTablet ? 26 : 22),
              ),
            ),
          ],
        ),
      ),
      body:
          _isInitialized
              ? SafeArea(
                child: Consumer2<MenuProvider, AnimatedCartProvider>(
                  builder: (context, menuProvider, cartProvider, child) {
                    final isTablet = MediaQuery.of(context).size.width > 768;

                    // Loading State with enhanced tablet design
                    if (menuProvider.isLoading) {
                      return Center(
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 48 : 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: isTablet ? 60 : 40,
                                      height: isTablet ? 60 : 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: isTablet ? 4 : 3,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 24 : 16),
                                    Text(
                                      'Loading delicious menu...',
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 12 : 8),
                                    Text(
                                      'Please wait while we prepare your menu',
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Error State with enhanced design
                    if (menuProvider.errorMessage != null) {
                      return Center(
                        child: Container(
                          margin: EdgeInsets.all(isTablet ? 32 : 16),
                          padding: EdgeInsets.all(isTablet ? 32 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline,
                                  size: isTablet ? 64 : 48,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: isTablet ? 24 : 16),
                              Text(
                                'Oops! Something went wrong',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isTablet ? 12 : 8),
                              Text(
                                menuProvider.errorMessage!,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isTablet ? 24 : 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  debugPrint(
                                    '[StandaloneMenu] Manual retry button pressed',
                                  );
                                  final outletId = HiveService.getOutletId();
                                  if (outletId == null || outletId <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No valid outlet ID available. Cannot load menu.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  await menuProvider.loadMenuData(
                                    outletId: outletId,
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 32 : 24,
                                    vertical: isTablet ? 16 : 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Empty State with enhanced design
                    if (menuProvider.apiMenuItems.isEmpty) {
                      return Center(
                        child: Container(
                          margin: EdgeInsets.all(isTablet ? 32 : 16),
                          padding: EdgeInsets.all(isTablet ? 32 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: isTablet ? 64 : 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              SizedBox(height: isTablet ? 24 : 16),
                              Text(
                                'No Menu Items Available',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: isTablet ? 12 : 8),
                              if (isTablet) ...[
                                Text(
                                  'Items: ${menuProvider.apiMenuItems.length}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Auth: ${HiveService.getAuthToken().isNotEmpty ? "✓ Connected" : "✗ Missing"}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final outletId = HiveService.getOutletId();
                                  if (outletId == null || outletId <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No valid outlet ID available. Cannot load menu.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  await menuProvider.loadMenuData(
                                    outletId: outletId,
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Load Menu'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 32 : 24,
                                    vertical: isTablet ? 16 : 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Main Menu Layout - Enhanced for tablet
                    return Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 8),
                      child: Column(
                        children: [
                          // Search Bar - Show only when search icon is clicked
                          if (_showSearchBar) const MenuSearchBar(),

                          // Category Tabs with enhanced design
                          const CategoryTabs(),

                          // Menu Grid - Main content
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: MenuGrid(
                                canOrder: _selectedTableId != null,
                                onAddToCart: _handleAddToCart,
                              ),
                            ),
                          ),

                          // Enhanced Cart Footer for tablets
                          if (_selectedTableId != null &&
                              cartProvider.totalItems > 0)
                            Container(
                              margin: EdgeInsets.only(top: isTablet ? 16 : 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: CartFooter(onPlaceOrder: _navigateToCart),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
              : Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Setting up your menu...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preparing everything for the best experience',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
