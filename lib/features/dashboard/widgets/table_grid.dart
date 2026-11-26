import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';

import 'enhanced_table_card.dart';

class TableGrid extends StatelessWidget {
  final List<RestaurantTable> tables;
  final Function(RestaurantTable) onTableTap;
  final Function(RestaurantTable) onTableLongPress;
  final Function(RestaurantTable)? onAddParty;

  const TableGrid({
    super.key,
    required this.tables,
    required this.onTableTap,
    required this.onTableLongPress,
    this.onAddParty,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.25,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return EnhancedTableCard(
          table: table,
          onAddParty:
              onAddParty == null ? null : () => onAddParty!(table),
          onTap: () => onTableTap(table),
          onLongPress: () {
            // Restrict cleaning request trigger to Reserved/Occupied only
            if (table.status == TableStatus.reserved ||
                table.status == TableStatus.occupied) {
              onTableLongPress(table);
            }
          },
        );
      },
    );
  }
}
