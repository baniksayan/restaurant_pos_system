import 'dart:convert';

// Test script to verify KOT payload format
void main() {
  final testPayload = {
    "userId": "041f765b-658c-47a4-b1a7-9dedf6e980b9",
    "outletId": 47,
    "orderId": "eb7ef4c5-b88f-f011-8840-00155d931011",
    "kotNote": "",
    "orderDetails": [
      {
        "productId": "7930f280-1a48-4719-9509-373abaa4e576",
        "productName": "Chicken Butter Masala",
        "categoryId": "a8c7d0a5-e3d6-4749-9ff8-447b090523c8",
        "categoryName": "Main Course",
        "productPrice": 500.0,
        "discountPercentage": 0.0,
        "uom": "Plate",
        "quantity": 1,
        "note": "",
      },
    ],
  };

  print('Test payload JSON:');
  print(json.encode(testPayload));

  print('\nPayload formatted:');
  print(JsonEncoder.withIndent('  ').convert(testPayload));
}
