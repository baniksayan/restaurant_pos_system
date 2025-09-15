import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

import '../../view_models/providers/menu_provider.dart';
import '../../view_models/providers/navigation_provider.dart';
import 'widgets/menu_header.dart';
import 'widgets/menu_search_bar.dart';
import 'widgets/category_tabs.dart';
import 'widgets/menu_grid.dart';
import 'widgets/cart_footer.dart';

class MenuView extends StatefulWidget {
  final String? selectedTableId;
  final String? tableName;
  final String? selectedLocation;
  final Function(
    String itemId,
    String itemName,
    double price,
    String categoryId,
    String categoryName,
    Offset position,
  )?
  onAddToCart;

  const MenuView({
    super.key,
    this.selectedTableId,
    this.tableName,
    this.selectedLocation,
    this.onAddToCart,
  });

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  @override
  void initState() {
    super.initState();
    // Load menu data when the widget initializes - BUT ONLY IF AUTHENTICATED
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      // Switch to selected table for proper state isolation
      if (widget.selectedTableId != null) {
        menuProvider.switchToTable(widget.selectedTableId);
      }

      // Check if user is authenticated before loading menu
      final token = HiveService.getAuthToken();
      if (token.isNotEmpty) {
        menuProvider.loadMenuData();
      } else {
        debugPrint('No auth token available - skipping menu load in MenuView');
      }
    });
  }

  @override
  void didUpdateWidget(MenuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switch to new table when table selection changes
    if (widget.selectedTableId != oldWidget.selectedTableId) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      menuProvider.switchToTable(widget.selectedTableId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Consumer2<MenuProvider, NavigationProvider>(
          builder: (context, menuProvider, navProvider, child) {
            // Debug prints
            debugPrint(
              'MenuView DEBUG: selectedTableId = ${widget.selectedTableId}',
            );
            debugPrint(
              'MenuView DEBUG: selectedOrderType = ${navProvider.selectedOrderType}',
            );

            // Can order if table is selected OR if phone/takeaway order is active
            final canOrder =
                widget.selectedTableId != null ||
                (navProvider.selectedOrderType != null &&
                    [
                      'PhoneOrder',
                      'Takeaway',
                    ].contains(navProvider.selectedOrderType));

            debugPrint('MenuView DEBUG: canOrder = $canOrder');

            return Column(
              children: [
                MenuHeader(
                  canOrder: canOrder,
                  tableName:
                      widget.tableName ?? _getOrderDisplayName(navProvider),
                  selectedLocation: widget.selectedLocation,
                  onPrintKOT: _printKOT,
                ),
                const MenuSearchBar(),
                const CategoryTabs(),
                Expanded(
                  child: MenuGrid(
                    canOrder: canOrder,
                    onAddToCart: widget.onAddToCart,
                  ),
                ),
                if (canOrder && menuProvider.totalCartItems > 0)
                  CartFooter(
                    onPlaceOrder: () {
                      // Navigate to Cart tab (index 2)
                      Provider.of<NavigationProvider>(
                        context,
                        listen: false,
                      ).navigateToIndex(2);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _printKOT() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KOT sent to kitchen printer!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String? _getOrderDisplayName(NavigationProvider navProvider) {
    if (navProvider.selectedOrderType != null) {
      return '${navProvider.selectedOrderType} Order - ${navProvider.customerName}';
    }
    return null;
  }
}
