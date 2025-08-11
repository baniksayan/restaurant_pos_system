import 'package:hive/hive.dart';

part 'order_model.g.dart';

@HiveType(typeId: 1)
class OrderModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tableId;

  @HiveField(2)
  List<OrderItemModel> items;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String status;

  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  bool synced;

  @HiveField(7)
  String waiterId;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.items,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    this.synced = false,
    required this.waiterId,
  });
}

@HiveType(typeId: 2)
class OrderItemModel extends HiveObject {
  @HiveField(0)
  String menuItemId;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String? notes;

  OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });
}
