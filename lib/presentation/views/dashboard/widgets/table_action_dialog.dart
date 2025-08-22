import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';

class TableActionDialog extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onOccupy;
  final VoidCallback onReserve;

  const TableActionDialog({
    super.key,
    required this.table,
    required this.onOccupy,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${table.name} - Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('What would you like to do with this table?'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Capacity: ${table.capacity} persons',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onReserve();
          },
          icon: const Icon(Icons.schedule, size: 18),
          label: const Text('Reserve Table'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onOccupy();
          },
          icon: const Icon(Icons.restaurant_menu, size: 18),
          label: const Text('Occupy & Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB),
          ),
        ),
      ],
    );
  }
}
