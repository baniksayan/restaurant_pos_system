import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../chef/data/chef_api.dart';
import '../../chef/models/chef_order_model.dart';

/// Provider that monitors kitchen orders at status 3 ("Ready to Serve").
///
/// In WhizEats Pro (Waiter login) these appear as "Ready to Collect" in
/// the hamburger drawer so waiters know which trays are sitting on the
/// kitchen pass waiting to be carried to the guest.
class ReadyToCollectProvider extends ChangeNotifier {
  List<ChefOrder> _orders = [];
  final Set<String> _collectedKotIds = {}; // locally dismissed orders
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;

  // ──────────────────────────────── Getters ────────────────────────────────

  /// Prepared orders that have NOT yet been marked as collected by the waiter.
  List<ChefOrder> get readyOrders =>
      _orders.where((o) => !_collectedKotIds.contains(o.id)).toList();

  /// Number of orders waiting to be picked up from the kitchen.
  int get readyCount => readyOrders.length;

  /// Total item count across all ready orders (for the summary bar).
  int get totalItemCount =>
      readyOrders.fold(0, (sum, o) => sum + o.totalItemCount);

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ────────────────────────────── Lifecycle ────────────────────────────────

  /// Call once (e.g. in `main.dart` or when the waiter dashboard loads).
  void init() {
    fetchReadyOrders();
    _startPolling();
  }

  void _startPolling({Duration interval = const Duration(seconds: 20)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      fetchReadyOrders(silent: true);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // ────────────────────────────── API calls ────────────────────────────────

  /// Fetches KOT orders with status 3 (Prepared / Ready to Serve).
  ///
  /// [silent] – if true, skips the loading spinner (used for background polls).
  Future<void> fetchReadyOrders({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // statusId 3 == "Prepared / Ready to Serve" in KOTStatusMaster.
      final fresh = await ChefApi.fetchChefOrders(statusIds: [3]);
      _orders = fresh;
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ReadyToCollectProvider] fetchReadyOrders error: $e');
      }
      if (!silent) _error = 'Could not load prepared orders. Pull down to retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark an order as collected by this waiter session.
  ///
  /// The dismissal is local-only: the KOT status on the server is already 3
  /// (Prepared); the waiter just needs to clear it from their own queue once
  /// they've physically carried the food to the table.
  void markAsCollected(String kotId) {
    _collectedKotIds.add(kotId);
    notifyListeners();
  }
}
