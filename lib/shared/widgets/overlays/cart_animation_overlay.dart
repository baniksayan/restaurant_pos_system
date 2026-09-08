import 'package:flutter/material.dart';
import '../animations/flying_cart_animation.dart';

class CartAnimationOverlay extends StatefulWidget {
  final Widget child;

  const CartAnimationOverlay({super.key, required this.child});

  @override
  CartAnimationOverlayState createState() => CartAnimationOverlayState(); // |  Make public
}

class CartAnimationOverlayState extends State<CartAnimationOverlay> {
  // |  No underscore - public class
  final List<Widget> _flyingItems = [];

  @override
  Widget build(BuildContext context) {
    return Stack(children: [widget.child, ..._flyingItems]);
  }

  void animateToCart({
    required Widget item,
    required Offset startPosition,
    required VoidCallback onComplete,
  }) {
    // Calculate cart position first
    final screenSize = MediaQuery.of(context).size;
    final cartPosition = Offset(
      screenSize.width * 0.6, // Cart tab position
      screenSize.height - 100, // Bottom navigation area
    );

    // |  FIXED: Declare flyingItem before usage
    late Widget flyingItem;

    flyingItem = FlyingCartAnimation(
      startPosition: startPosition,
      endPosition: cartPosition,
      onComplete: () {
        if (mounted) {
          setState(() {
            _flyingItems.remove(flyingItem); // |  Now this works
          });
        }
        onComplete();
      },
      child: item,
    );

    if (mounted) {
      setState(() {
        _flyingItems.add(flyingItem);
      });
    }
  }
}
