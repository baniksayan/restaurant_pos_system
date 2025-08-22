import 'package:flutter/material.dart';
import '../../../../view_models/providers/animated_cart_provider.dart';
import 'cart_item_card.dart';

class CartItemsList extends StatelessWidget {
  final List<CartItem> items;
  final Function(CartItem) onEditItem;

  const CartItemsList({
    super.key,
    required this.items,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items
            .map((item) => CartItemCard(
                  item: item,
                  onEdit: () => onEditItem(item),
                ))
            .toList(),
      ),
    );
  }
}
