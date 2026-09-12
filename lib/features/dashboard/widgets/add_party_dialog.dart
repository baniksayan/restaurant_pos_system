import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

/// What a new party on a table is opened with.
///
/// A table seats several groups at once, each running its own order and its
/// own bill. The guest count is what tells them apart in the order list, and
/// what makes "3 of 8 seated" possible on the table card.
class PartyDetails {
  final int adults;
  final int children;
  final String customerName;

  const PartyDetails({
    required this.adults,
    this.children = 0,
    this.customerName = '',
  });

  int get totalGuests => adults + children;
}

/// Asks for party size (and optionally a name) before opening a new order.
class AddPartyDialog extends StatefulWidget {
  final String tableName;

  /// Seats the table has, when known, so the sheet can warn about overbooking
  /// rather than block it. Zero means "unknown", and no warning is shown.
  final int capacity;

  /// Guests already seated across the existing parties, when known.
  final int seatedGuests;

  const AddPartyDialog({
    super.key,
    required this.tableName,
    this.capacity = 0,
    this.seatedGuests = 0,
  });

  static Future<PartyDetails?> show(
    BuildContext context, {
    required String tableName,
    int capacity = 0,
    int seatedGuests = 0,
  }) {
    return showDialog<PartyDetails>(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => AddPartyDialog(
            tableName: tableName,
            capacity: capacity,
            seatedGuests: seatedGuests,
          ),
    );
  }

  @override
  State<AddPartyDialog> createState() => _AddPartyDialogState();
}

class _AddPartyDialogState extends State<AddPartyDialog> {
  int _adults = 1;
  int _children = 0;
  final TextEditingController _nameController = TextEditingController();

  /// Seats left once this party is added, or null when capacity is unknown.
  int? get _remainingSeats {
    if (widget.capacity <= 0) return null;
    return widget.capacity - widget.seatedGuests - (_adults + _children);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remainingSeats;
    final overCapacity = remaining != null && remaining < 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Party',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  widget.tableName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCounterRow(
            label: 'Adults',
            value: _adults,
            min: 1,
            onChanged: (v) => setState(() => _adults = v),
          ),
          const SizedBox(height: 8),
          _buildCounterRow(
            label: 'Children',
            value: _children,
            min: 0,
            onChanged: (v) => setState(() => _children = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Customer name (optional)',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (remaining != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  overCapacity
                      ? Icons.warning_amber_rounded
                      : Icons.event_seat_rounded,
                  size: 15,
                  color: overCapacity ? AppColors.warning : AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    overCapacity
                        ? '${widget.seatedGuests + _adults + _children} on a '
                            '${widget.capacity}-seat table — over by '
                            '${-remaining}'
                        : widget.seatedGuests > 0
                        ? '${widget.seatedGuests} already seated · '
                            '$remaining ${remaining == 1 ? 'seat' : 'seats'} '
                            'left after this party'
                        : '$remaining ${remaining == 1 ? 'seat' : 'seats'} '
                            'left after this party',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color:
                          overCapacity ? AppColors.warning : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await HapticHelper.triggerFeedback();
            if (!context.mounted) return;
            Navigator.of(context).pop(
              PartyDetails(
                adults: _adults,
                children: _children,
                customerName: _nameController.text.trim(),
              ),
            );
          },
          child: const Text('Start Order'),
        ),
      ],
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int value,
    required int min,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed:
                  value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            SizedBox(
              width: 28,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
