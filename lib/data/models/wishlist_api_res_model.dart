// lib/data/models/wishlist_api_res_model.dart
class WishListApiResModel {
  final bool success;
  final String message;
  final List<WishListItem> data;

  WishListApiResModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory WishListApiResModel.fromJson(Map<String, dynamic> json) {
    return WishListApiResModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List?)
          ?.map((item) => WishListItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class WishListItem {
  final int id;
  final String name;
  final String description;
  final double price;

  WishListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  factory WishListItem.fromJson(Map<String, dynamic> json) {
    return WishListItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
