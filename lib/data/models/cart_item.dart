class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? specialNotes;
  final String tableId;
  final String tableName;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialNotes,
    required this.tableId,
    required this.tableName,
  });

  // Add factory constructor to convert from dynamic/Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      specialNotes: map['specialNotes'],
      tableId: map['tableId'] ?? '',
      tableName: map['tableName'] ?? '',
    );
  }

  // Convert to map for API calls
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialNotes': specialNotes,
      'tableId': tableId,
      'tableName': tableName,
    };
  }
}
