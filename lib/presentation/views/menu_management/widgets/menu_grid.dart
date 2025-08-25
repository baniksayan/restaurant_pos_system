// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
// import '../../../../data/models/menu_item.dart'; // Updated import
// import '../../../view_models/providers/menu_provider.dart';
// import 'menu_item_card.dart';

// // Rest of the file remains the same

// class MenuGrid extends StatelessWidget {
//   final bool canOrder;
//   final Function(String, String, double, Offset)? onAddToCart;
//   final MenuApiResModel data;

//   const MenuGrid({
//     super.key,
//     required this.canOrder,
//     this.onAddToCart,
//     required this.data,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MenuProvider>(
//       builder: (context, menuProvider, child) {
//         final items = menuProvider.filteredItems;

//         return GridView.builder(
//           padding: const EdgeInsets.all(16),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             childAspectRatio: 0.75,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//           ),
//           itemCount: data.data?.length ?? 0,
//           itemBuilder: (context, index) {
//             return MenuItemCard(
//               id: "${data.data?[index].productId}",
//               canOrder: canOrder,
//               name: "${data.data?[index].productName}",
//               imageUrl: "${data.data?[index].imageUrl}",
//               description: "${data.data?[index].categoryName}",
//               price:
//                   double.tryParse("${data.data?[index].productPrice}") ?? 0.0,

//               quantity: 0,
//               onAdd: () {},
//               onRemove: () {},
//               onAddToCart: (id, name, price, offset) {},
//               isVeg: data.data?[index].pureVeg ?? false,
//             );
//           },
//         );
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
import '../../../view_models/providers/menu_provider.dart';
import 'menu_item_card.dart';

class MenuGrid extends StatelessWidget {
  final bool canOrder;
  final Function(String, String, double, Offset)? onAddToCart;

  const MenuGrid({
    super.key,
    required this.canOrder,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (menuProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  menuProvider.errorMessage!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => menuProvider.loadMenuData(),
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
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  menuProvider.selectedCategory == 'All' 
                    ? 'No items found'
                    : 'No items found in ${menuProvider.selectedCategory}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                if (menuProvider.searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Try searching for something else',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return MenuItemCard(
              id: item.productId ?? '',
              canOrder: canOrder,
              name: item.productName ?? '',
              imageUrl: item.imageUrl ?? '',
              description: item.description ?? '',
              price: item.productPrice?.toDouble() ?? 0.0,
              quantity: menuProvider.getCartQuantity(item.productId ?? ''),
              onAdd: () => menuProvider.addToCart(item.productId ?? ''),
              onRemove: () => menuProvider.removeFromCart(item.productId ?? ''),
              onAddToCart: onAddToCart,
              isVeg: item.pureVeg ?? false,
            );
          },
        );
      },
    );
  }
}
