import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../chef/data/chef_api.dart';
import '../../chef/models/chef_order_model.dart';

/// Available date filter options for the All KOTs (Served History) tab.
enum ServedDateFilter {
  today,
  yesterday,
  custom,
  all,
}

/// Provider that monitors kitchen orders at status 3 ("Ready to Serve") and
/// status 5 ("Served") for Waiter pickup and KOT history tracking.
///
/// In WhizEats Pro (Waiter login) this powers the "Ready to Collect" screen
/// with two tabs:
///   1. Ready to Collect (Active KOTs waiting on the pass)
///   2. All KOTs (Served KOT history, view-only with dynamic search & date filters)
class ReadyToCollectProvider extends ChangeNotifier {
  List<ChefOrder> _orders = [];
  final Set<String> _collectedKotIds = {}; // locally dismissed orders
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;
  int _currentTabIndex = 0;

  // ────────────────────────── Search & Filter State ───────────────────────────
  String _servedSearchQuery = '';
  ServedDateFilter _servedDateFilter = ServedDateFilter.today;
  DateTimeRange? _customDateRange;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;

  // ──────────────────────────────── Getters ────────────────────────────────

  /// Prepared orders that have NOT yet been marked as collected by the waiter.
  List<ChefOrder> get readyOrders => _orders
      .where((o) =>
          o.status == ChefOrderStatus.ready &&
          !_collectedKotIds.contains(o.id))
      .toList();

  /// All raw served orders without search/date filter applied.
  List<ChefOrder> get rawServedOrders => _orders
      .where((o) =>
          o.status == ChefOrderStatus.served ||
          _collectedKotIds.contains(o.id))
      .toList();

  /// Orders that have already been served, dynamically filtered by search query
  /// and selected date range.
  List<ChefOrder> get servedOrders {
    final raw = rawServedOrders;
    final query = _servedSearchQuery.trim().toLowerCase();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayEnd = DateTime(
        yesterdayStart.year, yesterdayStart.month, yesterdayStart.day, 23, 59, 59, 999);

    return raw.where((order) {
      // 1. Date Filter
      final orderTime = order.orderTime;
      switch (_servedDateFilter) {
        case ServedDateFilter.today:
          if (orderTime.isBefore(todayStart) || orderTime.isAfter(todayEnd)) {
            return false;
          }
          break;
        case ServedDateFilter.yesterday:
          if (orderTime.isBefore(yesterdayStart) || orderTime.isAfter(yesterdayEnd)) {
            return false;
          }
          break;
        case ServedDateFilter.custom:
          if (_customDateRange != null) {
            final start = DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day,
            );
            final end = DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
              23,
              59,
              59,
              999,
            );
            if (orderTime.isBefore(start) || orderTime.isAfter(end)) {
              return false;
            }
          }
          break;
        case ServedDateFilter.all:
          break;
      }

      // 2. Search Query Filter
      if (query.isNotEmpty) {
        final matchesTable = order.tableNumber.toLowerCase().contains(query);
        final matchesKotNo = order.kotNo.toLowerCase().contains(query);
        final matchesOrderNum = order.orderNumber.toLowerCase().contains(query);
        final matchesIdentifier =
            (order.orderIdentifier ?? '').toLowerCase().contains(query);
        final matchesGenerated =
            (order.generatedOrderNo ?? '').toLowerCase().contains(query);
        final matchesItem = order.items.any((item) =>
            item.name.toLowerCase().contains(query) ||
            (item.specialInstructions ?? '').toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query));

        if (!matchesTable &&
            !matchesKotNo &&
            !matchesOrderNum &&
            !matchesIdentifier &&
            !matchesGenerated &&
            !matchesItem) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Number of orders waiting to be picked up from the kitchen pass.
  int get readyCount => readyOrders.length;

  /// Number of served KOTs currently visible matching the filter.
  int get servedCount => servedOrders.length;

  /// Total count of all raw served KOTs loaded.
  int get rawServedCount => rawServedOrders.length;

  /// Total item count across all ready orders (for the summary bar).
  int get totalItemCount =>
      readyOrders.fold(0, (sum, o) => sum + o.totalItemCount);

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentTabIndex => _currentTabIndex;

  String get servedSearchQuery => _servedSearchQuery;
  ServedDateFilter get servedDateFilter => _servedDateFilter;
  DateTimeRange? get customDateRange => _customDateRange;
  bool get isServedFilterActive =>
      _servedSearchQuery.trim().isNotEmpty ||
      _servedDateFilter != ServedDateFilter.today;

  // ────────────────────────────── Navigation ───────────────────────────────

  void changeTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  // ────────────────────────── Search & Filter Actions ──────────────────────

  /// Update the live search query for All KOTs (filters table, KOT #, and item names).
  void setServedSearchQuery(String query) {
    if (_servedSearchQuery != query) {
      _servedSearchQuery = query;
      notifyListeners();
    }
  }

  /// Change the active date filter for All KOTs tab and query the server.
  Future<void> setServedDateFilter(
    ServedDateFilter filter, {
    DateTimeRange? customRange,
  }) async {
    _servedDateFilter = filter;
    if (customRange != null) {
      _customDateRange = customRange;
    }
    notifyListeners();

    final now = DateTime.now();
    DateTime? apiFrom;
    DateTime? apiTo;

    if (filter == ServedDateFilter.today) {
      apiFrom = DateTime(now.year, now.month, now.day);
      apiTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filter == ServedDateFilter.yesterday) {
      final y = now.subtract(const Duration(days: 1));
      apiFrom = DateTime(y.year, y.month, y.day);
      apiTo = DateTime(y.year, y.month, y.day, 23, 59, 59);
    } else if (filter == ServedDateFilter.custom && _customDateRange != null) {
      apiFrom = DateTime(
        _customDateRange!.start.year,
        _customDateRange!.start.month,
        _customDateRange!.start.day,
      );
      apiTo = DateTime(
        _customDateRange!.end.year,
        _customDateRange!.end.month,
        _customDateRange!.end.day,
        23,
        59,
        59,
      );
    } else if (filter == ServedDateFilter.all) {
      apiFrom = DateTime(now.year, now.month - 6, now.day);
      apiTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    _currentFromDate = apiFrom;
    _currentToDate = apiTo;

    await fetchOrders(fromDate: apiFrom, toDate: apiTo);
  }

  /// Clears all search queries and date filters back to default ("Today").
  Future<void> clearServedFilters() async {
    _servedSearchQuery = '';
    _servedDateFilter = ServedDateFilter.today;
    _customDateRange = null;
    notifyListeners();

    final now = DateTime.now();
    final apiFrom = DateTime(now.year, now.month, now.day);
    final apiTo = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _currentFromDate = apiFrom;
    _currentToDate = apiTo;

    await fetchOrders(fromDate: apiFrom, toDate: apiTo);
  }

  // ────────────────────────────── Lifecycle ────────────────────────────────

  /// Call once (e.g. in `main.dart` or when the waiter dashboard loads).
  void init() {
    fetchOrders();
    _startPolling();
  }

  void _startPolling({Duration interval = const Duration(seconds: 20)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      fetchOrders(
        silent: true,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
      );
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

  /// Fetches KOT orders with status 3 (Ready to Serve) and status 5 (Served).
  ///
  /// [silent] – if true, skips the loading spinner (used for background polls).
  Future<void> fetchOrders({
    bool silent = false,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // statusId 3 == "Prepared / Ready to Serve", statusId 5 == "Served"
      final fresh = await ChefApi.fetchChefOrders(
        statusIds: [3, 5],
        fromDate: fromDate ?? _currentFromDate,
        toDate: toDate ?? _currentToDate,
      );
      _orders = fresh;
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ReadyToCollectProvider] fetchOrders error: $e');
      }
      if (!silent) _error = 'Could not load kitchen orders. Pull down to retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Backward compatible alias for fetchOrders.
  Future<void> fetchReadyOrders({bool silent = false}) =>
      fetchOrders(silent: silent);

  /// Mark an order as collected by the waiter and transition STATUS 3 -> STATUS 5.
  ///
  /// STATUS 5 (Served) is exclusively completed by the Operator/Waiter side.
  /// Dispatches POST Order/updateKotDetails with statusId: 5.
  Future<bool> markAsCollected(String kotId) async {
    // 1. Optimistic dismissal from readyOrders -> moves to servedOrders
    _collectedKotIds.add(kotId);
    notifyListeners();

    try {
      final success = await ChefApi.updateKotStatus(
        kotId: kotId,
        statusId: 5,
      );

      if (!success) {
        // Rollback if backend update failed
        _collectedKotIds.remove(kotId);
        notifyListeners();
        return false;
      }

      // Update in cached list
      final index = _orders.indexWhere((o) => o.id == kotId);
      if (index != -1) {
        final existing = _orders[index];
        _orders[index] = existing.copyWith(status: ChefOrderStatus.served);
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ReadyToCollectProvider] markAsCollected error: $e');
      }
      _collectedKotIds.remove(kotId);
      notifyListeners();
      return false;
    }
  }
}
