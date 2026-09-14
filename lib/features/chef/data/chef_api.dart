import 'package:flutter/foundation.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import '../../chef/models/chef_order_model.dart';
// Note: we use ApiService models via ApiService calls; avoid direct model import here

class ChefApi {
  ChefApi._();

  /// Fetch KOT details for the given outlet and status ids and map them into
  /// `ChefOrder` objects grouped by `kotHeadId`.
  static Future<List<ChefOrder>> fetchChefOrders({
    List<int>? statusIds,
    String searchBy = '',
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final outletId = HiveService.getOutletId();
    if (outletId == null) return [];

    final ids = statusIds ?? [1, 2, 3]; // New, InProgress, Completed

    final now = DateTime.now();
    final fd = fromDate ?? DateTime(now.year, now.month, now.day);
    final td = toDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    final body = {
      'statusIds': ids.map((i) => {'statusId': i}).toList(),
      'searchBy': searchBy,
      'fromDate': fd.toIso8601String(),
      'toDate': td.toIso8601String(),
      'outletId': outletId,
    };

    try {
      final response = await ApiService.apiRequestHttpRawBody(
        'Order/fetchKotDetails',
        body,
        method: 'POST',
      );

      if (response == null) return [];

      final data = response['data'];
      if (data == null || data is! List) return [];

      // Group rows by kotHeadId
      final Map<String, List<dynamic>> groups = {};
      for (final row in data) {
        if (row is! Map) continue;
        final headId =
            (row['kotHeadId'] ?? row['orderIdentifier'] ?? row['kotNo'])
                .toString();
        groups.putIfAbsent(headId, () => []).add(row);
      }

      final List<ChefOrder> orders = [];

      for (final entry in groups.entries) {
        final headId = entry.key;
        final rows = entry.value;

        DateTime? orderTime;
        String tableName = 'Unknown';
        String orderNumber = headId;
        final List<ChefOrderItem> items = [];

        // Determine aggregate status priority: if any rejected -> rejected,
        // else if any completed -> ready, else if any in-progress -> preparing,
        // else pending.
        bool hasRejected = false;
        bool hasCompleted = false;
        bool hasInProgress = false;

        for (final r in rows) {
          if (r is! Map) continue;

          final kotId = r['kotId']?.toString() ?? '';
          final productName = r['productName']?.toString() ?? 'Item';
          final qtyRaw = r['productQty'];
          int qty = 0;
          if (qtyRaw is num) {
            qty = qtyRaw.toInt();
          } else if (qtyRaw is String) {
            qty = int.tryParse(qtyRaw) ?? 0;
          }

          final created = _parseDateTime(r['createdOn']);
          if (created != null) {
            orderTime =
                orderTime == null
                    ? created
                    : (created.isBefore(orderTime) ? created : orderTime);
          }

          tableName =
              r['channelName']?.toString() ??
              r['orderIdentifier']?.toString() ??
              tableName;
          orderNumber =
              r['generatedOrderNo']?.toString() ??
              r['kotNo']?.toString() ??
              orderNumber;

          final statusId =
              (r['kotStatusId'] is num)
                  ? (r['kotStatusId'] as num).toInt()
                  : int.tryParse(r['kotStatusId']?.toString() ?? '') ?? 1;

          if (statusId == 4) hasRejected = true;
          if (statusId == 3) hasCompleted = true;
          if (statusId == 2) hasInProgress = true;

          items.add(
            ChefOrderItem(
              id: kotId.isNotEmpty ? kotId : '${headId}_${items.length}',
              name: productName,
              quantity: qty > 0 ? qty : 1,
              price: 0.0,
              specialInstructions: r['instruction']?.toString(),
              imageUrl: '',
            ),
          );
        }

        ChefOrderStatus status;
        if (hasRejected) {
          status = ChefOrderStatus.rejected;
        } else if (hasCompleted) {
          status = ChefOrderStatus.ready;
        } else if (hasInProgress) {
          status = ChefOrderStatus.preparing;
        } else {
          status = ChefOrderStatus.pending;
        }

        orders.add(
          ChefOrder(
            id: headId,
            orderNumber: orderNumber,
            tableNumber: tableName,
            orderTime: orderTime ?? DateTime.now(),
            items: items,
            status: status,
          ),
        );
      }

      orders.sort((a, b) => b.orderTime.compareTo(a.orderTime));
      return orders;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ChefApi.fetchChefOrders error: $e');
        debugPrint('$st');
      }
      return [];
    }
  }

  /// Update a single KOT item's status using the backend API.
  static Future<bool> updateKotStatus({
    required String kotId,
    required int statusId,
  }) async {
    try {
      final body = {'kotId': kotId, 'statusId': statusId};
      final resp = await ApiService.apiRequestHttpRawBody(
        'Order/updateKotDetails',
        body,
        method: 'POST',
      );
      if (resp == null) return false;
      return resp['isSuccess'] == true || resp['statusCode'] == 200;
    } catch (e) {
      if (kDebugMode) debugPrint('ChefApi.updateKotStatus error: $e');
      return false;
    }
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    try {
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v).toLocal();
      return null;
    } catch (_) {
      return null;
    }
  }
}
