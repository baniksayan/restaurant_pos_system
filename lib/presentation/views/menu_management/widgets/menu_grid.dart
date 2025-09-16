import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/providers/menu_provider.dart';
import '../../../view_models/providers/animated_cart_provider.dart';
import '../../../view_models/providers/navigation_provider.dart';
import 'menu_item_card.dart';

class MenuGrid extends StatelessWidget {
  final bool canOrder;
  final Function(String, String, double, String, String, Offset)? onAddToCart;

  const MenuGrid({super.key, required this.canOrder, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MenuProvider, AnimatedCartProvider>(
      builder: (context, menuProvider, cartProvider, child) {
        if (menuProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (menuProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  menuProvider.errorMessage!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: menuProvider.loadMenuData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredItems = menuProvider.filteredItems;

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No menu items available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                if (menuProvider.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or category filter',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final itemId = item.productId ?? '';

              return MenuItemCard(
                id: itemId,
                canOrder: canOrder,
                name: item.productName ?? '',
                imageUrl:
                    item.imageId == 206
                        ? "https://assetrmsfiles.uvanij.com/Dev/Company/D02B4B68-B244-462D-B564-CD2848D19F0F/images/RMS/Reciepe/ApplePi-àlaMode_16092025114648.jpg"
                        : item.imageThumbUrl ??
                            'https://assetrmsfiles.uvanij.com/Dev/Company/D02B4B68-B244-462D-B564-CD2848D19F0F/images/RMS/Reciepe/ApplePi-àlaMode_16092025114648.jpg',
                description: item.description ?? '',
                price: item.productPrice?.toDouble() ?? 0.0,
                quantity: cartProvider.getItemQuantity(
                  itemId,
                ), // Use AnimatedCartProvider
                cid: item.categoryId ?? '',
                cname: item.categoryName ?? '',
                onAdd: () => _addToCart(context, item, cartProvider),
                onRemove: () => _removeFromCart(itemId, cartProvider),
                onAddToCart: onAddToCart,
                isVeg: item.pureVeg ?? false,
              );
            },
          ),
        );
      },
    );
  }

  // Helper method to add item to cart
  void _addToCart(
    BuildContext context,
    dynamic item,
    AnimatedCartProvider cartProvider,
  ) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    // Determine table context for both table orders and phone/takeaway orders
    String tableId = navProvider.selectedTableId ?? '';
    String tableName = navProvider.selectedTableName ?? '';

    // For phone/takeaway orders, use appropriate identifiers
    if (tableId.isEmpty) {
      if (navProvider.selectedOrderType == 'PhoneOrder') {
        tableId = 'PhoneOrder';
        tableName = 'Phone Order - ${navProvider.customerName ?? 'Customer'}';
      } else if (navProvider.selectedOrderType == 'Takeaway') {
        tableId = 'Takeaway';
        tableName = 'Takeaway - ${navProvider.customerName ?? 'Customer'}';
      }
    }

    if (tableId.isNotEmpty && tableName.isNotEmpty) {
      cartProvider.addItem(
        item.productId ?? '',
        item.productName ?? '',
        (item.productPrice?.toDouble() ?? 0.0),
        tableId,
        tableName,
        categoryId: item.categoryId ?? '',
        categoryName: item.categoryName ?? '',
      );
    }
  }

  // Helper method to remove item from cart
  void _removeFromCart(String itemId, AnimatedCartProvider cartProvider) {
    cartProvider.removeItem(itemId);
  }
}
