import 'package:flutter/material.dart';
import '../../view_models/providers/animated_cart_provider.dart';

class BillingPage extends StatelessWidget {
  final String orderNumber;
  final List<CartItem> cartItems;
  final VoidCallback onBillGenerated;

  const BillingPage({
    super.key,
    required this.orderNumber,
    required this.cartItems,
    required this.onBillGenerated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Bill - Order #$orderNumber'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Bill Generation Page',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Order #$orderNumber'),
            Text('${cartItems.length} items'),
            const SizedBox(height: 20),
            const Text(
              'This page will be implemented later\nwith all customer billing functionalities',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                onBillGenerated();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
