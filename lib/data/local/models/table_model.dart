import 'package:hive/hive.dart';

part 'table_model.g.dart';

@HiveType(typeId: 0)
class TableModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int capacity;

  @HiveField(3)
  String status; // 'available', 'occupied', 'reserved', 'cleaning'

  @HiveField(4)
  String? currentOrderId;

  @HiveField(5)
  bool kotGenerated;

  @HiveField(6)
  bool billGenerated;

  @HiveField(7)
  DateTime lastUpdated;

  @HiveField(8)
  bool synced; // Track if data is synced to server

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    this.kotGenerated = false,
    this.billGenerated = false,
    required this.lastUpdated,
    this.synced = false,
  });
}
