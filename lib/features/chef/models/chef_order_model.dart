enum ChefOrderStatus {
  pending, // STATUS 1: New order in queue, awaiting Chef Approve (-> 2) or Reject (-> 4)
  preparing, // STATUS 2: Chef approved, currently cooking in kitchen (-> 3)
  ready, // STATUS 3: Preparation completed, ready for handover on pass (Chef -> Operator handover point)
  served, // STATUS 5: Operator/Waiter collected & served to table (final state, Operator-owned)
  rejected, // STATUS 4: Rejected by chef
}

class ChefOrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? specialInstructions; // Item-wise KOT note
  final String? imageUrl;
  final String category;

  ChefOrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.specialInstructions,
    this.imageUrl,
    this.category = 'Main Course',
  });

  ChefOrderItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    String? specialInstructions,
    String? imageUrl,
    String? category,
  }) {
    return ChefOrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }
}

class ChefOrder {
  final String id; // Unique KOT ID (UUID)
  final String kotNo; // Human readable KOT number
  final String? kotHeadId;
  final String? orderIdentifier;
  final String? channelName;
  final String? generatedOrderNo;
  final int? waitingMinutes;
  final String orderNumber; // Display KOT No / Order identifier in UI
  final String tableNumber; // e.g. "Table 10 P2" or "Table 12"
  final DateTime orderTime;
  final List<ChefOrderItem> items;
  ChefOrderStatus status;
  String? rejectionReason;
  DateTime? startedPreparingTime;
  DateTime? completedTime;

  ChefOrder({
    required this.id,
    required this.kotNo,
    this.kotHeadId,
    this.orderIdentifier,
    this.channelName,
    this.generatedOrderNo,
    this.waitingMinutes,
    required this.orderNumber,
    required this.tableNumber,
    required this.orderTime,
    required this.items,
    this.status = ChefOrderStatus.pending,
    this.rejectionReason,
    this.startedPreparingTime,
    this.completedTime,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  String get timeAgo {
    final int minutes =
        waitingMinutes ?? DateTime.now().difference(orderTime).inMinutes;
    if (minutes <= 0) {
      return 'Just now';
    }
    final int hours = minutes ~/ 60;
    final int remainingMins = minutes % 60;

    if (hours == 0) {
      return '$remainingMins min';
    } else if (remainingMins == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${remainingMins}m';
    }
  }

  /// Total waiting time in minutes for warning thresholds and status calculations
  int get effectiveWaitingMinutes =>
      waitingMinutes ?? DateTime.now().difference(orderTime).inMinutes;

  ChefOrder copyWith({
    String? id,
    String? kotNo,
    String? kotHeadId,
    String? orderIdentifier,
    String? channelName,
    String? generatedOrderNo,
    int? waitingMinutes,
    String? orderNumber,
    String? tableNumber,
    DateTime? orderTime,
    List<ChefOrderItem>? items,
    ChefOrderStatus? status,
    String? rejectionReason,
    DateTime? startedPreparingTime,
    DateTime? completedTime,
  }) {
    return ChefOrder(
      id: id ?? this.id,
      kotNo: kotNo ?? this.kotNo,
      kotHeadId: kotHeadId ?? this.kotHeadId,
      orderIdentifier: orderIdentifier ?? this.orderIdentifier,
      channelName: channelName ?? this.channelName,
      generatedOrderNo: generatedOrderNo ?? this.generatedOrderNo,
      waitingMinutes: waitingMinutes ?? this.waitingMinutes,
      orderNumber: orderNumber ?? this.orderNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      orderTime: orderTime ?? this.orderTime,
      items: items ?? this.items,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      startedPreparingTime: startedPreparingTime ?? this.startedPreparingTime,
      completedTime: completedTime ?? this.completedTime,
    );
  }
}

class ChefMenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  bool isAvailable;
  String? unavailableReason;

  ChefMenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl = '',
    this.isAvailable = true,
    this.unavailableReason,
  });
}
