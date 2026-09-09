import 'package:flutter/foundation.dart';
import '../models/chef_order_model.dart';

class ChefProvider extends ChangeNotifier {
  List<ChefOrder> _orders = [];
  final List<ChefMenuItem> _menuItems = [];
  String _selectedStatusFilter = 'All Statuses';
  String _selectedLocation = 'Main Kitchen';
  String _historyFilter = 'all';
  int _currentTabIndex = 0; // 0 = All, 1 = Queue, 2 = Preparing, 3 = Serve

  final List<String> _locations = [
    'Main Kitchen',
    'Bar Kitchen',
    'Dessert & Bakery',
  ];

  final List<String> _statusFilters = [
    'All Statuses',
    'Pending',
    'Preparing',
    'Ready to Serve',
  ];

  List<ChefOrder> get orders => _orders;
  List<ChefMenuItem> get menuItems => _menuItems;
  List<ChefMenuItem> get filteredMenuItems => _menuItems;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedLocation => _selectedLocation;
  String get historyFilter => _historyFilter;
  List<String> get locations => _locations;
  List<String> get statusFilters => _statusFilters;
  List<String> get availableCategories => [
    'All',
    'Main Course',
    'Starters',
    'Breads',
  ];
  String get selectedMenuCategory => 'All';
  int get currentTabIndex => _currentTabIndex;

  ChefProvider() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    _orders = [
      // 1. Queue Stage (Pending Orders)
      ChefOrder(
        id: 'ord_1048',
        orderNumber: '1048',
        tableNumber: 'Table 12',
        orderTime: now.subtract(const Duration(minutes: 2)),
        status: ChefOrderStatus.pending,
        items: [
          ChefOrderItem(
            id: 'item_1',
            name: 'Chicken Biryani',
            quantity: 2,
            price: 280.0,
            specialInstructions: 'Extra spicy',
            imageUrl:
                'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80',
          ),
          ChefOrderItem(
            id: 'item_2',
            name: 'Butter Chicken',
            quantity: 1,
            price: 320.0,
            specialInstructions: 'No onion',
            imageUrl:
                'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=300&q=80',
          ),
          ChefOrderItem(
            id: 'item_3',
            name: 'Garlic Naan',
            quantity: 2,
            price: 60.0,
            imageUrl:
                'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300&q=80',
          ),
        ],
      ),
      ChefOrder(
        id: 'ord_1049',
        orderNumber: '1049',
        tableNumber: 'Table 05',
        orderTime: now.subtract(const Duration(minutes: 4)),
        status: ChefOrderStatus.pending,
        items: [
          ChefOrderItem(
            id: 'item_4',
            name: 'Paneer Tikka',
            quantity: 1,
            price: 240.0,
            specialInstructions: 'Less spicy',
            imageUrl:
                'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=300&q=80',
          ),
          ChefOrderItem(
            id: 'item_5',
            name: 'Masala Dosa',
            quantity: 2,
            price: 140.0,
            imageUrl:
                'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=300&q=80',
          ),
        ],
      ),

      // 2. Preparing Stage (In Kitchen Cooking)
      ChefOrder(
        id: 'ord_1050',
        orderNumber: '1050',
        tableNumber: 'Table 03',
        orderTime: now.subtract(const Duration(minutes: 9)),
        startedPreparingTime: now.subtract(const Duration(minutes: 7)),
        status: ChefOrderStatus.preparing,
        items: [
          ChefOrderItem(
            id: 'item_6',
            name: 'Chicken Fried Rice',
            quantity: 2,
            price: 220.0,
            imageUrl:
                'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=300&q=80',
          ),
          ChefOrderItem(
            id: 'item_7',
            name: 'Chilli Chicken',
            quantity: 1,
            price: 260.0,
            specialInstructions: 'Extra gravy',
            imageUrl:
                'https://images.unsplash.com/photo-1525755662778-989d0524087e?w=300&q=80',
          ),
        ],
      ),
      ChefOrder(
        id: 'ord_1051',
        orderNumber: '1051',
        tableNumber: 'Table 11',
        orderTime: now.subtract(const Duration(minutes: 12)),
        startedPreparingTime: now.subtract(const Duration(minutes: 10)),
        status: ChefOrderStatus.preparing,
        items: [
          ChefOrderItem(
            id: 'item_1',
            name: 'Chicken Biryani',
            quantity: 3,
            price: 280.0,
            specialInstructions: 'Medium spicy',
            imageUrl:
                'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80',
          ),
        ],
      ),

      // 3. Serve Stage (Ready to Serve)
      ChefOrder(
        id: 'ord_1052',
        orderNumber: '1052',
        tableNumber: 'Takeaway',
        orderTime: now.subtract(const Duration(minutes: 16)),
        status: ChefOrderStatus.ready,
        items: [
          ChefOrderItem(
            id: 'item_4',
            name: 'Paneer Tikka',
            quantity: 2,
            price: 240.0,
            imageUrl:
                'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=300&q=80',
          ),
          ChefOrderItem(
            id: 'item_3',
            name: 'Garlic Naan',
            quantity: 3,
            price: 60.0,
            imageUrl:
                'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300&q=80',
          ),
        ],
      ),
      ChefOrder(
        id: 'ord_1053',
        orderNumber: '1053',
        tableNumber: 'Table 07',
        orderTime: now.subtract(const Duration(minutes: 20)),
        status: ChefOrderStatus.ready,
        items: [
          ChefOrderItem(
            id: 'item_5',
            name: 'Masala Dosa',
            quantity: 1,
            price: 140.0,
            imageUrl:
                'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=300&q=80',
          ),
        ],
      ),
    ];
  }

  // Filtered orders for currently active tab + status dropdown filter
  List<ChefOrder> get filteredOrders {
    List<ChefOrder> tabOrders;

    switch (_currentTabIndex) {
      case 0: // All: Shows all active orders (Pending, Preparing, Ready)
        tabOrders =
            _orders
                .where(
                  (o) =>
                      o.status == ChefOrderStatus.pending ||
                      o.status == ChefOrderStatus.preparing ||
                      o.status == ChefOrderStatus.ready,
                )
                .toList();
        break;
      case 1: // Queue: Only Pending
        tabOrders =
            _orders.where((o) => o.status == ChefOrderStatus.pending).toList();
        break;
      case 2: // Preparing: In Kitchen
        tabOrders =
            _orders
                .where((o) => o.status == ChefOrderStatus.preparing)
                .toList();
        break;
      case 3: // Serve: Ready to Serve
      default:
        tabOrders =
            _orders.where((o) => o.status == ChefOrderStatus.ready).toList();
        break;
    }

    // Apply status filter dropdown if selected and not "All Statuses"
    if (_selectedStatusFilter != 'All Statuses') {
      tabOrders =
          tabOrders.where((o) {
            switch (_selectedStatusFilter.toLowerCase()) {
              case 'pending':
                return o.status == ChefOrderStatus.pending;
              case 'preparing':
                return o.status == ChefOrderStatus.preparing;
              case 'ready to serve':
              case 'ready':
                return o.status == ChefOrderStatus.ready;
              case 'served':
                return o.status == ChefOrderStatus.served;
              default:
                return true;
            }
          }).toList();
    }

    return tabOrders;
  }

  // Footer tab badge counts
  int get allActiveCount =>
      _orders
          .where(
            (o) =>
                o.status == ChefOrderStatus.pending ||
                o.status == ChefOrderStatus.preparing ||
                o.status == ChefOrderStatus.ready,
          )
          .length;

  int get queueCount =>
      _orders.where((o) => o.status == ChefOrderStatus.pending).length;
  int get preparingCount =>
      _orders.where((o) => o.status == ChefOrderStatus.preparing).length;
  int get serveCount =>
      _orders.where((o) => o.status == ChefOrderStatus.ready).length;
  int get totalOrdersCount => _orders.length;

  // History orders compatibility
  List<ChefOrder> get historyOrders =>
      _orders
          .where(
            (o) =>
                o.status == ChefOrderStatus.served ||
                o.status == ChefOrderStatus.rejected,
          )
          .toList();

  void setHistoryFilter(String filter) {
    _historyFilter = filter;
    notifyListeners();
  }

  // Item availability compatibility
  void setMenuSearchQuery(String query) {}
  void setSelectedMenuCategory(String category) {}
  void markItemUnavailable(String id, String reason) {}
  void markItemAvailable(String id) {}
  int getActiveOrderImpact(String name) => 0;

  // Filter & Navigation controls
  void changeTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void changeStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void changeLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  // Order state workflow:
  // Step 1: In Queue -> Chef approves order, moving it to Preparing
  void approveOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = ChefOrderStatus.preparing;
      _orders[index].startedPreparingTime = DateTime.now();
      notifyListeners();
    }
  }

  // Step 1: In Queue -> Chef rejects order
  void rejectOrder(String orderId, String reason) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = ChefOrderStatus.rejected;
      _orders[index].rejectionReason = reason;
      _orders[index].completedTime = DateTime.now();
      notifyListeners();
    }
  }

  // Step 2: In Preparing -> Chef marks Ready to Serve, moving it to Serve
  void markReadyToServe(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = ChefOrderStatus.ready;
      notifyListeners();
    }
  }

  // Step 3: In Serve -> Chef clicks Ready to Serve (Handed over), marking it Served
  void giveOrder(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = ChefOrderStatus.served;
      _orders[index].completedTime = DateTime.now();
      notifyListeners();
    }
  }
}
