import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
import '../../../../data/models/menu_item.dart'; // Updated import
import '../../../view_models/providers/menu_provider.dart';
import 'menu_item_card.dart';

// Rest of the file remains the same

class MenuGrid extends StatelessWidget {
  final bool canOrder;
  final Function(String, String, double, Offset)? onAddToCart;
  final MenuApiResModel data;

  const MenuGrid({
    super.key,
    required this.canOrder,
    this.onAddToCart,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        final items = menuProvider.filteredItems;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: data.data?.length ?? 0,
          itemBuilder: (context, index) {
            return MenuItemCard(
              id: "${data.data?[index].productId}",
              canOrder: canOrder,
              name: "${data.data?[index].productName}",
              imageUrl: "${data.data?[index].imageUrl}",
              description: "${data.data?[index].categoryName}",
              price:
                  double.tryParse("${data.data?[index].productPrice}") ?? 0.0,

              quantity: 0,
              onAdd: () {},
              onRemove: () {},
              onAddToCart: (id, name, price, offset) {},
              isVeg: data.data?[index].pureVeg ?? false,
            );
          },
        );
      },
    );
  }
}
