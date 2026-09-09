import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/empty_state_widget.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';
import 'menu_item_card.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class MenuGrid extends StatelessWidget {
  final bool canOrder;
  final Function(String, String, double, String, String, Offset)? onAddToCart;

  const MenuGrid({super.key, required this.canOrder, this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MenuProvider, AnimatedCartProvider>(
      builder: (context, menuProvider, cartProvider, child) {
        if (menuProvider.isLoading) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 185,
                mainAxisExtent: 245,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: SkeletonLoader(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      SizedBox(height: 12),
                      SkeletonLoader.rectangular(width: 100, height: 16),
                      SizedBox(height: 6),
                      SkeletonLoader.rectangular(width: 60, height: 12),
                      Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonLoader.rectangular(width: 55, height: 14),
                          SkeletonLoader.rectangular(
                            width: 40,
                            height: 28,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        if (menuProvider.errorMessage != null) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height:
                        constraints.maxHeight > 0 ? constraints.maxHeight : 400,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline_rounded,
                      title: AppStrings.menu.failedToLoadMenu,
                      description: menuProvider.errorMessage!,
                      action: ElevatedButton.icon(
                        onPressed: () async {
                          final outletId = HiveService.getOutletId();
                          if (outletId != null && outletId > 0) {
                            await menuProvider.loadMenuData(outletId: outletId);
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(AppStrings.retry),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }

        final filteredItems = menuProvider.filteredItems;

        if (filteredItems.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height:
                        constraints.maxHeight > 0 ? constraints.maxHeight : 400,
                    child: EmptyStateWidget(
                      icon: Icons.restaurant_menu_rounded,
                      title: AppStrings.menu.noItemsAvailable,
                      description:
                          menuProvider.searchQuery.isNotEmpty
                              ? 'No menu items match "${menuProvider.searchQuery}". Try adjusting your filters or search.'
                              : 'There are currently no items in this category.',
                    ),
                  ),
                ],
              );
            },
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 185,
              mainAxisExtent: 245,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final itemId = item.productId ?? '';

              return MenuItemCard(
                id: itemId,
                canOrder: canOrder,
                name: item.productName ?? '',
                imageUrl: item.imageThumbUrl,
                description: item.description ?? '',
                price: item.productPrice?.toDouble() ?? 0.0,
                quantity: cartProvider.getNewItemQuantity(
                  itemId,
                ), // Show count of new (unprinted) items only
                cid: item.categoryId ?? '',
                cname: item.categoryName ?? '',
                onAdd: () => _addToCart(context, item, cartProvider),
                onRemove: () => _removeFromCart(itemId, cartProvider),
                onAddToCart: onAddToCart,
                isVeg: item.pureVeg ?? false,
                onQuantityChanged: (newQty) {
                  _updateCartQuantity(context, item, cartProvider, newQty);
                },
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
        imageUrl: item.imageThumbUrl ?? item.imageUrl,
        categoryId: item.categoryId ?? '',
        categoryName: item.categoryName ?? '',
      );
    }
  }

  // Helper method to remove item from cart
  void _removeFromCart(String itemId, AnimatedCartProvider cartProvider) {
    cartProvider.removeItem(itemId);
  }

  // Helper method to update item quantity directly
  void _updateCartQuantity(
    BuildContext context,
    dynamic item,
    AnimatedCartProvider cartProvider,
    int newQty,
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
      cartProvider.setItemQuantity(
        item.productId ?? '',
        newQty,
        item.productName ?? '',
        (item.productPrice?.toDouble() ?? 0.0),
        tableId,
        tableName,
        imageUrl: item.imageThumbUrl ?? item.imageUrl,
        categoryId: item.categoryId ?? '',
        categoryName: item.categoryName ?? '',
      );
    }
  }
}
