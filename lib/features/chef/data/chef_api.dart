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

      // Group rows by kotId (kotId-wise grouping)
      final Map<String, List<dynamic>> groups = {};
      for (final row in data) {
        if (row is! Map) continue;
        final kotId = (row['kotId'] ?? '').toString();
        if (kotId.isEmpty) continue;
        groups.putIfAbsent(kotId, () => []).add(row);
      }

      final List<ChefOrder> orders = [];

      for (final entry in groups.entries) {
        final kotId = entry.key;
        final rows = entry.value;

        DateTime? orderTime;
        String kotNo = '';
        String? kotHeadId;
        String? orderIdentifier;
        String? channelName;
        String? generatedOrderNo;
        int? waitingMinutes;
        final List<ChefOrderItem> items = [];

        bool hasRejected = false;
        bool hasServed = false;
        bool hasReady = false;
        bool hasInProgress = false;

        for (final r in rows) {
          if (r is! Map) continue;

          final rKotNo = r['kotNo']?.toString();
          if (rKotNo != null && rKotNo.trim().isNotEmpty) kotNo = rKotNo.trim();

          final rKotHeadId = r['kotHeadId']?.toString();
          if (rKotHeadId != null && rKotHeadId.trim().isNotEmpty) kotHeadId = rKotHeadId.trim();

          final rOrderIdentifier = r['orderIdentifier']?.toString();
          if (rOrderIdentifier != null && rOrderIdentifier.trim().isNotEmpty) orderIdentifier = rOrderIdentifier.trim();

          final rChannelName = r['channelName']?.toString();
          if (rChannelName != null && rChannelName.trim().isNotEmpty) channelName = rChannelName.trim();

          final rGeneratedOrderNo = r['generatedOrderNo']?.toString();
          if (rGeneratedOrderNo != null && rGeneratedOrderNo.trim().isNotEmpty) generatedOrderNo = rGeneratedOrderNo.trim();

          final wmRaw = r['waitingMinutes'];
          if (wmRaw is num) {
            waitingMinutes = wmRaw.toInt();
          } else if (wmRaw is String) {
            waitingMinutes = int.tryParse(wmRaw);
          }

          final productName = r['productName']?.toString() ?? 'Item';
          final qtyRaw = r['productQty'];
          int qty = 0;
          if (qtyRaw is num) {
            qty = qtyRaw.toInt();
          } else if (qtyRaw is String) {
            qty = double.tryParse(qtyRaw)?.toInt() ?? int.tryParse(qtyRaw) ?? 0;
          }

          final created = _parseDateTime(r['createdOn']);
          if (created != null) {
            orderTime =
                orderTime == null
                    ? created
                    : (created.isBefore(orderTime) ? created : orderTime);
          }

          final statusId =
              (r['kotStatusId'] is num)
                  ? (r['kotStatusId'] as num).toInt()
                  : int.tryParse(r['kotStatusId']?.toString() ?? '') ?? 1;

          if (statusId == 4) hasRejected = true;
          if (statusId == 5) hasServed = true;
          if (statusId == 3) hasReady = true;
          if (statusId == 2) hasInProgress = true;

          items.add(
            ChefOrderItem(
              id: kotId,
              name: productName,
              quantity: qty > 0 ? qty : 1,
              price: 0.0,
              specialInstructions: r['instruction']?.toString(),
              imageUrl: '',
            ),
          );
        }

        ChefOrderStatus status;
        if (hasReady) {
          status = ChefOrderStatus.ready;
        } else if (hasInProgress) {
          status = ChefOrderStatus.preparing;
        } else if (hasServed) {
          status = ChefOrderStatus.served;
        } else if (hasRejected) {
          status = ChefOrderStatus.rejected;
        } else {
          status = ChefOrderStatus.pending;
        }

        final displayTable =
            (orderIdentifier != null && orderIdentifier.trim().isNotEmpty)
                ? orderIdentifier.trim()
                : (channelName != null && channelName.trim().isNotEmpty
                    ? channelName.trim()
                    : 'Table');

        final displayKotNo = kotNo.trim().isNotEmpty ? kotNo.trim() : 'KOT';
        final resolvedOrderNo =
            (generatedOrderNo != null && generatedOrderNo.trim().isNotEmpty)
                ? generatedOrderNo.trim()
                : displayKotNo;

        orders.add(
          ChefOrder(
            id: kotId, // Unique KOT ID (UUID)
            kotNo: displayKotNo,
            kotHeadId: kotHeadId,
            orderIdentifier: orderIdentifier,
            channelName: channelName,
            generatedOrderNo:
                (generatedOrderNo != null && generatedOrderNo.trim().isNotEmpty)
                    ? generatedOrderNo.trim()
                    : null,
            waitingMinutes: waitingMinutes,
            orderNumber: resolvedOrderNo,
            tableNumber: displayTable,
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
