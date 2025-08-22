// lib/presentation/views/reports/widgets/charts/revenue_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/themes/app_colors.dart';

class RevenueChart extends StatelessWidget {
  final String timeFrame;

  const RevenueChart({super.key, required this.timeFrame});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Last 14 Days',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        final date = DateTime.now().subtract(
                          Duration(days: (13 - value.toInt())),
                        );
                        return Text('${date.day}/${date.month}', style: style);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20000,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 13,
                minY: 0,
                maxY: 60000,
                lineBarsData: [
                  LineChartBarData(
                    spots: _getRevenueSpots(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary.withOpacity(0.3),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor:
                        (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        return LineTooltipItem(
                          '₹${NumberFormat('#,##,###').format(flSpot.y.toInt())}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getRevenueSpots() {
    return [
      const FlSpot(0, 38898),
      const FlSpot(1, 34700),
      const FlSpot(2, 32007),
      const FlSpot(3, 14261),
      const FlSpot(4, 38623),
      const FlSpot(5, 16381),
      const FlSpot(6, 45665),
      const FlSpot(7, 31205),
      const FlSpot(8, 14277),
      const FlSpot(9, 32085),
      const FlSpot(10, 29571),
      const FlSpot(11, 36412),
      const FlSpot(12, 16166),
      const FlSpot(13, 38057),
    ];
  }
}
