import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/features/chef/data/chef_api.dart';
import '../models/chef_order_model.dart';

class ChefProvider extends ChangeNotifier {
  List<ChefOrder> _orders = [];
  final List<ChefMenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _errorMessage;
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
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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
    // Load live KOT data from backend
    fetchOrders();
  }

  /// Fetch latest orders from backend and replace local orders when available
  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await ChefApi.fetchChefOrders();
      if (fetched.isNotEmpty) {
        _orders = fetched;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ChefProvider.fetchOrders error: $e');
        debugPrint('$st');
      }
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    _updateOrderStatusOptimistic(
      orderId,
      ChefOrderStatus.preparing,
      apiStatus: 'preparing',
      setStartedPreparing: true,
    );
  }

  // Step 1: In Queue -> Chef rejects order
  void rejectOrder(String orderId, String reason) {
    _updateOrderStatusOptimistic(
      orderId,
      ChefOrderStatus.rejected,
      apiStatus: 'rejected',
      setRejectionReason: reason,
      setCompletedTime: true,
    );
  }

  // Step 2: In Preparing -> Chef marks Ready to Serve, moving it to Serve
  void markReadyToServe(String orderId) {
    _updateOrderStatusOptimistic(
      orderId,
      ChefOrderStatus.ready,
      apiStatus: 'ready',
    );
  }

  // Step 3: In Serve -> Chef clicks Ready to Serve (Handed over), marking it Served
  void giveOrder(String orderId) {
    _updateOrderStatusOptimistic(
      orderId,
      ChefOrderStatus.served,
      apiStatus: 'served',
      setCompletedTime: true,
    );
  }

  /// Internal helper: optimistic update + backend sync via UpdateOrderHeadStatus
  Future<void> _updateOrderStatusOptimistic(
    String orderId,
    ChefOrderStatus targetStatus, {
    required String apiStatus,
    bool setStartedPreparing = false,
    bool setCompletedTime = false,
    String? setRejectionReason,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final previous = _orders[index].copyWith();

    // Apply optimistic changes locally
    _orders[index].status = targetStatus;
    if (setStartedPreparing)
      _orders[index].startedPreparingTime = DateTime.now();
    if (setCompletedTime) _orders[index].completedTime = DateTime.now();
    if (setRejectionReason != null)
      _orders[index].rejectionReason = setRejectionReason;
    notifyListeners();

    try {
      // Map local chef status to KOT status id
      int kotStatusId;
      switch (targetStatus) {
        case ChefOrderStatus.pending:
          kotStatusId = 1;
          break;
        case ChefOrderStatus.preparing:
          kotStatusId = 2;
          break;
        case ChefOrderStatus.ready:
        case ChefOrderStatus.served:
          kotStatusId = 3;
          break;
        case ChefOrderStatus.rejected:
          kotStatusId = 4;
          break;
      }

      final kotIds =
          _orders[index].items
              .map((i) => i.id)
              .where((id) => id.isNotEmpty)
              .toList();

      if (kotIds.isEmpty) {
        // Nothing to update on backend for this order - refresh from server
        await fetchOrders();
        return;
      }

      final results = await Future.wait(
        kotIds.map(
          (k) => ChefApi.updateKotStatus(kotId: k, statusId: kotStatusId),
        ),
      );

      if (results.any((r) => r != true)) {
        // Revert optimistic changes if any update failed
        _orders[index] = previous;
        notifyListeners();
      } else {
        // On success, refresh to pick up any backend-side changes
        await fetchOrders();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ChefProvider._updateOrderStatus error: $e');
      _orders[index] = previous;
      notifyListeners();
    }
  }
}
