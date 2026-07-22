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
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return CartItemCard(
          item: item,
          onEdit: () => onEditItem(item),
        );
      },
    );
  }
}
