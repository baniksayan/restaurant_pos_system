import 'package:flutter/material.dart';
import '../../../../../shared/widgets/layout/empty_state_widget.dart';

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: 'Your Cart is Empty',
      description: 'Add items from menu to see them here',
    );
  }
}

