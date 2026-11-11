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
    int? outletId,
    List<int>? statusIds,
    String searchBy = '',
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final effectiveOutletId =
        outletId ?? HiveService.getSelectedLocationId() ?? HiveService.getOutletId();
    if (effectiveOutletId == null || effectiveOutletId <= 0) return [];

    final ids = statusIds ?? [1, 2, 3]; // New, InProgress, Completed

    final now = DateTime.now();
    final fd = fromDate ?? DateTime(now.year, now.month, now.day);
    final td = toDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    final body = {
      'statusIds': ids.map((i) => {'statusId': i}).toList(),
      'searchBy': searchBy,
      'fromDate': fd.toIso8601String(),
      'toDate': td.toIso8601String(),
      'outletId': effectiveOutletId,
      'locationId': effectiveOutletId,
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

      // Group rows by KOT ticket (kotHeadId or kotNo)
      final Map<String, List<dynamic>> groups = {};
      for (final row in data) {
        if (row is! Map) continue;
        final headId = (row['kotHeadId'] ?? '').toString().trim();
        final kotNo = (row['kotNo'] ?? '').toString().trim();
        final orderIdentifier = (row['orderIdentifier'] ??
                row['orderNo'] ??
                row['generatedOrderNo'] ??
                '')
            .toString()
            .trim();

        final groupKey =
            (headId.isNotEmpty && headId != '0' && headId != 'null')
                ? headId
                : (orderIdentifier.isNotEmpty && kotNo.isNotEmpty
                    ? '${orderIdentifier}_$kotNo'
                    : (kotNo.isNotEmpty ? kotNo : (row['kotId'] ?? '').toString()));
        if (groupKey.isEmpty) continue;
        groups.putIfAbsent(groupKey, () => []).add(row);
      }

      final List<ChefOrder> orders = [];

      for (final entry in groups.entries) {
        final groupKey = entry.key;
        final rows = entry.value;

        DateTime? orderTime;
        String kotNo = '';
        String? kotHeadId;
        String? orderIdentifier;
        String? channelName;
        String? generatedOrderNo;
        int? waitingMinutes;
        int? rowOutletId;
        String? rowOutletName;
        String? kitchenNote;
        final List<ChefOrderItem> items = [];

        bool hasRejected = false;
        bool hasServed = false;
        bool hasReady = false;
        bool hasInProgress = false;

        // Step 1: Pre-extract metadata, ticket numbers, and check explicit kitchen note across rows
        for (final r in rows) {
          if (r is! Map) continue;

          final rOutletId = r['outletId'] ?? r['locationId'];
          if (rOutletId != null && rowOutletId == null) {
            if (rOutletId is num) {
              rowOutletId = rOutletId.toInt();
            } else if (rOutletId is String) {
              rowOutletId = int.tryParse(rOutletId);
            }
          }
          final rOutletName =
              r['outletName']?.toString() ?? r['locationName']?.toString();
          if (rOutletName != null &&
              rOutletName.trim().isNotEmpty &&
              (rowOutletName == null || rowOutletName.isEmpty)) {
            rowOutletName = rOutletName.trim();
          }

          final rKotNo = r['kotNo']?.toString();
          if (rKotNo != null && rKotNo.trim().isNotEmpty && kotNo.isEmpty) {
            kotNo = rKotNo.trim();
          }

          final rKotHeadId = r['kotHeadId']?.toString();
          if (rKotHeadId != null &&
              rKotHeadId.trim().isNotEmpty &&
              (kotHeadId == null || kotHeadId.isEmpty)) {
            kotHeadId = rKotHeadId.trim();
          }

          final rOrderIdentifier = r['orderIdentifier']?.toString();
          if (rOrderIdentifier != null &&
              rOrderIdentifier.trim().isNotEmpty &&
              (orderIdentifier == null || orderIdentifier.isEmpty)) {
            orderIdentifier = rOrderIdentifier.trim();
          }

          final rChannelName = r['channelName']?.toString();
          if (rChannelName != null &&
              rChannelName.trim().isNotEmpty &&
              (channelName == null || channelName.isEmpty)) {
            channelName = rChannelName.trim();
          }

          final rGeneratedOrderNo = r['generatedOrderNo']?.toString();
          if (rGeneratedOrderNo != null &&
              rGeneratedOrderNo.trim().isNotEmpty &&
              (generatedOrderNo == null || generatedOrderNo.isEmpty)) {
            generatedOrderNo = rGeneratedOrderNo.trim();
          }

          final wmRaw = r['waitingMinutes'];
          if (wmRaw != null && waitingMinutes == null) {
            if (wmRaw is num) {
              waitingMinutes = wmRaw.toInt();
            } else if (wmRaw is String) {
              waitingMinutes = int.tryParse(wmRaw);
            }
          }

          final created = _parseDateTime(r['createdOn']);
          if (created != null) {
            orderTime = orderTime == null
                ? created
                : (created.isBefore(orderTime) ? created : orderTime);
          }

          // Check if any explicit kitchen / KOT note field is populated
          final rKotNote = (r['kotNote'] ??
                  r['kitchenNote'] ??
                  r['specialNotes'] ??
                  r['remarks'] ??
                  r['orderNote'] ??
                  r['note'] ??
                  '')
              .toString()
              .trim();
          if (rKotNote.isNotEmpty &&
              (kitchenNote == null || kitchenNote.isEmpty)) {
            kitchenNote = rKotNote;
          }
        }

        // Filter: If row outlet does not match active effectiveOutletId, skip this group
        // so tickets from other outlets are not incorrectly shown in the active outlet.
        if (rowOutletId != null && rowOutletId != effectiveOutletId) {
          continue;
        }

        // Step 2: Fallback to Hive for kitchen note using all known identifiers
        final resolvedKotNo = kotNo.trim().isNotEmpty ? kotNo.trim() : '';
        if ((kitchenNote == null || kitchenNote.isEmpty) && resolvedKotNo.isNotEmpty) {
          kitchenNote = HiveService.getKotNote(resolvedKotNo);
        }
        if ((kitchenNote == null || kitchenNote.isEmpty) &&
            kotHeadId != null &&
            kotHeadId.isNotEmpty) {
          kitchenNote = HiveService.getKotNote(kotHeadId);
        }
        if ((kitchenNote == null || kitchenNote.isEmpty) &&
            orderIdentifier != null &&
            orderIdentifier.isNotEmpty) {
          kitchenNote = HiveService.getKotNote(orderIdentifier);
        }
        if ((kitchenNote == null || kitchenNote.isEmpty) &&
            generatedOrderNo != null &&
            generatedOrderNo.isNotEmpty) {
          kitchenNote = HiveService.getKotNote(generatedOrderNo);
        }

        // Step 3: Heuristic extraction of kitchen note from row instructions
        final rawInstructions = rows
            .map((r) => r is Map ? (r['instruction'] ?? '').toString().trim() : '')
            .where((s) => s.isNotEmpty)
            .toList();

        if (kitchenNote == null || kitchenNote.isEmpty) {
          final distinctInstructions = rawInstructions.toSet();
          if (distinctInstructions.length == 1) {
            // All rows share the exact same instruction -> it's the whole-KOT kitchen note!
            kitchenNote = distinctInstructions.first;
          } else if (rawInstructions.isNotEmpty) {
            // Instructions differ, but backend may have concatenated: "$itemNote, $kitchenNote"
            String? candidateKitchenNote;
            for (final inst in rawInstructions) {
              final commaIdx = inst.lastIndexOf(',');
              if (commaIdx != -1) {
                final candidate = inst.substring(commaIdx + 1).trim();
                if (candidate.isNotEmpty) {
                  // Verify that all instructions either end with this candidate or equal it
                  final candLower = candidate.toLowerCase();
                  final allMatch = rawInstructions.every((other) {
                    final o = other.trim().toLowerCase();
                    return o == candLower ||
                        o == ', $candLower' ||
                        o.endsWith(', $candLower');
                  });
                  if (allMatch) {
                    candidateKitchenNote = candidate;
                    break;
                  }
                }
              }
            }
            if (candidateKitchenNote != null && candidateKitchenNote.isNotEmpty) {
              kitchenNote = candidateKitchenNote;
            }
          }

          // If found via heuristic, persist to Hive so subsequent lookups are fast
          if (kitchenNote != null && kitchenNote.isNotEmpty && resolvedKotNo.isNotEmpty) {
            HiveService.saveKotNote(resolvedKotNo, kitchenNote);
          }
        }

        // Step 4: Parse items and extract true item-specific notes
        for (final r in rows) {
          if (r is! Map) continue;

          final productName = r['productName']?.toString() ?? 'Item';
          final qtyRaw = r['productQty'];
          int qty = 0;
          if (qtyRaw is num) {
            qty = qtyRaw.toInt();
          } else if (qtyRaw is String) {
            qty = double.tryParse(qtyRaw)?.toInt() ?? int.tryParse(qtyRaw) ?? 0;
          }

          final statusId =
              (r['kotStatusId'] is num)
                  ? (r['kotStatusId'] as num).toInt()
                  : int.tryParse(r['kotStatusId']?.toString() ?? '') ?? 1;

          if (statusId == 4) hasRejected = true;
          if (statusId == 5) hasServed = true;
          if (statusId == 3) hasReady = true;
          if (statusId == 2) hasInProgress = true;

          // Crucial fix: an instruction is an item note ONLY if it is not the whole-KOT kitchen note
          final rawInstruction = (r['instruction'] ?? '').toString().trim();
          String? itemNote;
          if (rawInstruction.isNotEmpty) {
            if (kitchenNote != null && kitchenNote.isNotEmpty) {
              final kLower = kitchenNote.toLowerCase();
              final iLower = rawInstruction.toLowerCase();

              if (iLower == kLower || iLower == ', $kLower') {
                // The instruction was purely the kitchen note
                itemNote = null;
              } else if (iLower.endsWith(', $kLower')) {
                // Suffix was ", <kitchenNote>" -> strip it cleanly
                final cutLen = rawInstruction.length - (kitchenNote.length + 2);
                final remaining = rawInstruction.substring(0, cutLen).trim();
                itemNote = remaining.isNotEmpty ? remaining : null;
              } else if (iLower.endsWith(kLower)) {
                final cutLen = rawInstruction.length - kitchenNote.length;
                String remaining = rawInstruction.substring(0, cutLen).trim();
                if (remaining.endsWith(',')) {
                  remaining = remaining.substring(0, remaining.length - 1).trim();
                }
                itemNote = remaining.isNotEmpty ? remaining : null;
              } else {
                itemNote = rawInstruction;
              }
            } else {
              itemNote = rawInstruction;
            }
          }

          final itemKotId = (r['kotId'] ?? '').toString();
          items.add(
            ChefOrderItem(
              id: itemKotId.isNotEmpty ? itemKotId : groupKey,
              name: productName,
              quantity: qty > 0 ? qty : 1,
              price: 0.0,
              specialInstructions: itemNote,
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

        final primaryId = (kotHeadId != null && kotHeadId.isNotEmpty)
            ? kotHeadId
            : (kotNo.isNotEmpty ? kotNo : groupKey);

        orders.add(
          ChefOrder(
            id: primaryId,
            kotNo: displayKotNo,
            kotHeadId: kotHeadId,
            kitchenNote: kitchenNote,
            orderIdentifier: orderIdentifier,
            channelName: channelName,
            generatedOrderNo:
                (generatedOrderNo != null && generatedOrderNo.trim().isNotEmpty)
                    ? generatedOrderNo.trim()
                    : null,
            waitingMinutes: waitingMinutes,
            outletId: rowOutletId ?? effectiveOutletId,
            outletName: rowOutletName,
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
