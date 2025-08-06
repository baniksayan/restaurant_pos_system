import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos_system/main.dart';

void main() {
  testWidgets('Restaurant POS app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RestaurantPOSApp());

    // Verify that the app starts properly
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Add more specific tests as needed
  });
}
