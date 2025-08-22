import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'enhanced_table_card.dart';

class TableGrid extends StatelessWidget {
  final List<RestaurantTable> tables;
  final Function(RestaurantTable) onTableTap;
  final Function(RestaurantTable) onTableLongPress;

  const TableGrid({
    super.key,
    required this.tables,
    required this.onTableTap,
    required this.onTableLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return EnhancedTableCard(
          table: table,
          onTap: () => onTableTap(table),
          onLongPress: () => onTableLongPress(table),
        );
      },
    );
  }
}
