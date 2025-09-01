import 'package:flutter/material.dart';
import '../cards/kpi_card.dart';
import '../cards/stat_card.dart';
import '../charts/revenue_chart.dart';

class OverviewTab extends StatelessWidget {
  final String selectedTimeFrame;

  const OverviewTab({
    super.key,
    required this.selectedTimeFrame,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPICards(),
          const SizedBox(height: 20),
          RevenueChart(timeFrame: selectedTimeFrame),
          const SizedBox(height: 20),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: KPICard(
            title: 'Total Revenue',
            value: '₹4,52,847',
            change: '+12.5%',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KPICard(
            title: 'Orders Today',
            value: '127',
            change: '+8.2%',
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Avg Order Value',
            value: '₹347',
            icon: Icons.receipt_long,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Peak Hour',
            value: '7:30 PM',
            icon: Icons.access_time,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Table Turnover',
            value: '3.2x',
            icon: Icons.table_restaurant,
          ),
        ),
      ],
    );
  }
}
