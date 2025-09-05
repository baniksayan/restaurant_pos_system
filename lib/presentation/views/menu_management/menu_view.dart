import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

import '../../view_models/providers/menu_provider.dart';
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Consumer<MenuProvider>(
          builder: (context, menuProvider, child) {
            return Column(
              children: [
                MenuHeader(
                  canOrder: widget.selectedTableId != null,
                  tableName: widget.tableName,
                  selectedLocation: widget.selectedLocation,
                  onPrintKOT: _printKOT,
                ),
                const MenuSearchBar(),
                const CategoryTabs(),
                Expanded(
                  child: MenuGrid(
                    canOrder: widget.selectedTableId != null,
                    onAddToCart: widget.onAddToCart,
                  ),
                ),
                if (widget.selectedTableId != null &&
                    menuProvider.totalCartItems > 0)
                  CartFooter(onPlaceOrder: () {}),
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
}
