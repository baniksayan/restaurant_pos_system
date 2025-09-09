import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_colors.dart';
import 'package:restaurant_pos_system/presentation/views/reports/services/reports_csv_service.dart';
import 'package:restaurant_pos_system/presentation/views/reports/services/reports_pdf_service.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView>
    with TickerProviderStateMixin {
  String _selectedTimeFrame = 'Last 7 Days';
  String _revenueViewType = 'Daily';
  int _selectedDayIndex = -1;

  final List<String> _timeFrames = [
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last 3 Months',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildKPICards(),
                const SizedBox(height: 16),
                _buildSecondRowKPICards(),
                const SizedBox(height: 20),
                _buildRevenueChart(),
                const SizedBox(height: 20),
                _buildInsightsSection(),
                const SizedBox(height: 20),
                _buildOrderCustomerStats(),
                const SizedBox(height: 20),
                _buildOrderChannels(),
                const SizedBox(height: 20),
                _buildExportSection(),
                const SizedBox(height: 100), // Extra space for navigation bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics & Reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Business Performance Dashboard',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.white),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeFrame,
                  isExpanded: true,
                  hint: const Text('Select Time Period'),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  items:
                      _timeFrames.map((String timeFrame) {
                        return DropdownMenuItem<String>(
                          value: timeFrame,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              timeFrame,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTimeFrame = newValue;
                        _selectedDayIndex = -1; // Reset day selection
                      });
                      _animateDataChange();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    final data = _getKPIData();
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            title: 'Total Revenue',
            value: data['revenue']!,
            change: data['revenueChange']!,
            changeColor:
                data['revenueChange']!.contains('+')
                    ? Colors.green
                    : Colors.red,
            icon: Icons.trending_up_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            title: 'Total Orders',
            value: data['orders']!,
            change: data['ordersChange']!,
            changeColor:
                data['ordersChange']!.contains('+') ? Colors.green : Colors.red,
            icon: Icons.shopping_cart_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondRowKPICards() {
    final data = _getKPIData();
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            title: 'Avg Order Value',
            value: data['avgOrder']!,
            change: data['avgOrderChange']!,
            changeColor:
                data['avgOrderChange']!.contains('+')
                    ? Colors.green
                    : Colors.red,
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            title: 'Table Turnover Rate',
            value: data['turnover']!,
            change: data['turnoverChange']!,
            changeColor:
                data['turnoverChange']!.contains('+')
                    ? Colors.green
                    : Colors.red,
            icon: Icons.table_restaurant_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: changeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final chartData = _getChartData();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRevenueViewButton('Daily'),
                const SizedBox(width: 8),
                _buildRevenueViewButton('Weekly'),
                const SizedBox(width: 8),
                _buildRevenueViewButton('Monthly'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revenue vs Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chartData['totalRevenue']!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedTimeFrame} ${chartData['change']!}',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      chartData['change']!.contains('+')
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: LineChart(_buildLineChartData())),
        ],
      ),
    );
  }

  Widget _buildRevenueViewButton(String title) {
    final isSelected = _revenueViewType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _revenueViewType = title;
        });
        _animateDataChange();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = _getRevenueSpots();
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getChartInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final labels = _getChartLabels();
              if (value.toInt() >= 0 && value.toInt() < labels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[value.toInt()],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      maxY: _getMaxY(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 5,
                color: AppColors.primary,
                strokeWidth: 3,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.primary.withOpacity(0.05),
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
          getTooltipColor: (touchedSpot) => AppColors.primary.withOpacity(0.9),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                '₹${NumberFormat('#,##,###').format(barSpot.y.toInt())}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/analytics/food/grilled-burger-french-fries-food-generative-ai.jpg',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[200]!, Colors.grey[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fastfood_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Food Analytics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCustomerStats() {
    final orderData = _getOrderStatsData();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order & Customer Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Orders',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                orderData['dailyOrders']!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedTimeFrame} ${orderData['change']!}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      orderData['change']!.contains('+')
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final heights = _getDayHeights();
                    final days = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    final isSelected = _selectedDayIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = isSelected ? -1 : index;
                          });
                          _animateDataChange();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: heights[index],
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors:
                                        isSelected
                                            ? [
                                              AppColors.primary,
                                              AppColors.primary.withOpacity(
                                                0.7,
                                              ),
                                            ]
                                            : [
                                              AppColors.primary.withOpacity(
                                                0.3,
                                              ),
                                              AppColors.primary.withOpacity(
                                                0.1,
                                              ),
                                            ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                days[index],
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderChannels() {
    final channelData = _getChannelData();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Channels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                channelData['percentage']!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This Month ${channelData['change']!}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      channelData['change']!.contains('+')
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildChannelItem(
                'Dine-in',
                channelData['dineIn']!,
                AppColors.primary,
              ),
              const SizedBox(height: 12),
              _buildChannelItem(
                'Phone Order',
                channelData['phone']!,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildChannelItem(
                'Takeaway',
                channelData['takeaway']!,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelItem(String title, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _showExportDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Export Report (PDF/CSV)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Data Methods
  Map<String, String> _getKPIData() {
    switch (_selectedTimeFrame) {
      case 'Today':
        return {
          'revenue': '₹3,245',
          'revenueChange': '+5%',
          'orders': '47',
          'ordersChange': '+12%',
          'avgOrder': '₹69.04',
          'avgOrderChange': '+3%',
          'turnover': '1.8x',
          'turnoverChange': '+8%',
        };
      case 'Last 7 Days':
        return {
          'revenue': '₹12,450',
          'revenueChange': '+12%',
          'orders': '320',
          'ordersChange': '-5%',
          'avgOrder': '₹38.91',
          'avgOrderChange': '+8%',
          'turnover': '2.1x',
          'turnoverChange': '+15%',
        };
      case 'Last 30 Days':
        return {
          'revenue': '₹54,780',
          'revenueChange': '+18%',
          'orders': '1,245',
          'ordersChange': '+22%',
          'avgOrder': '₹44.02',
          'avgOrderChange': '+15%',
          'turnover': '2.4x',
          'turnoverChange': '+25%',
        };
      case 'This Month':
        return {
          'revenue': '₹48,920',
          'revenueChange': '+14%',
          'orders': '1,089',
          'ordersChange': '+8%',
          'avgOrder': '₹44.93',
          'avgOrderChange': '+12%',
          'turnover': '2.3x',
          'turnoverChange': '+18%',
        };
      case 'Last 3 Months':
        return {
          'revenue': '₹1,84,350',
          'revenueChange': '+28%',
          'orders': '4,567',
          'ordersChange': '+35%',
          'avgOrder': '₹40.38',
          'avgOrderChange': '+18%',
          'turnover': '2.6x',
          'turnoverChange': '+32%',
        };
      default:
        return {
          'revenue': '₹12,450',
          'revenueChange': '+12%',
          'orders': '320',
          'ordersChange': '-5%',
          'avgOrder': '₹38.91',
          'avgOrderChange': '+8%',
          'turnover': '2.1x',
          'turnoverChange': '+15%',
        };
    }
  }

  Map<String, String> _getChartData() {
    switch (_selectedTimeFrame) {
      case 'Today':
        return {'totalRevenue': '₹3,245', 'change': '+5%'};
      case 'Last 7 Days':
        return {'totalRevenue': '₹12,450', 'change': '+12%'};
      case 'Last 30 Days':
        return {'totalRevenue': '₹54,780', 'change': '+18%'};
      case 'This Month':
        return {'totalRevenue': '₹48,920', 'change': '+14%'};
      case 'Last 3 Months':
        return {'totalRevenue': '₹1,84,350', 'change': '+28%'};
      default:
        return {'totalRevenue': '₹12,450', 'change': '+12%'};
    }
  }

  List<FlSpot> _getRevenueSpots() {
    switch (_revenueViewType) {
      case 'Daily':
        return const [
          FlSpot(0, 3500),
          FlSpot(1, 2800),
          FlSpot(2, 1200),
          FlSpot(3, 9200),
          FlSpot(4, 1800),
          FlSpot(5, 700),
          FlSpot(6, 4200),
        ];
      case 'Weekly':
        return const [
          FlSpot(0, 15000),
          FlSpot(1, 18500),
          FlSpot(2, 12300),
          FlSpot(3, 22100),
        ];
      case 'Monthly':
        return const [
          FlSpot(0, 45000),
          FlSpot(1, 52000),
          FlSpot(2, 48000),
          FlSpot(3, 58000),
          FlSpot(4, 51000),
          FlSpot(5, 54000),
        ];
      default:
        return const [
          FlSpot(0, 3500),
          FlSpot(1, 2800),
          FlSpot(2, 1200),
          FlSpot(3, 9200),
          FlSpot(4, 1800),
          FlSpot(5, 700),
          FlSpot(6, 4200),
        ];
    }
  }

  List<String> _getChartLabels() {
    switch (_revenueViewType) {
      case 'Daily':
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case 'Weekly':
        return ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      case 'Monthly':
        return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
  }

  double _getMaxY() {
    switch (_revenueViewType) {
      case 'Daily':
        return 10000;
      case 'Weekly':
        return 25000;
      case 'Monthly':
        return 60000;
      default:
        return 10000;
    }
  }

  double _getChartInterval() {
    switch (_revenueViewType) {
      case 'Daily':
        return 2000;
      case 'Weekly':
        return 5000;
      case 'Monthly':
        return 10000;
      default:
        return 2000;
    }
  }

  Map<String, String> _getOrderStatsData() {
    if (_selectedDayIndex >= 0) {
      final dayData = [
        {'dailyOrders': '45', 'change': '+8%'},
        {'dailyOrders': '52', 'change': '+15%'},
        {'dailyOrders': '38', 'change': '-2%'},
        {'dailyOrders': '67', 'change': '+22%'},
        {'dailyOrders': '41', 'change': '+5%'},
        {'dailyOrders': '29', 'change': '-8%'},
        {'dailyOrders': '48', 'change': '+12%'},
      ];
      return dayData[_selectedDayIndex];
    }

    switch (_selectedTimeFrame) {
      case 'Today':
        return {'dailyOrders': '47', 'change': '+12%'};
      case 'Last 7 Days':
        return {'dailyOrders': '320', 'change': '-5%'};
      case 'Last 30 Days':
        return {'dailyOrders': '1,245', 'change': '+22%'};
      case 'This Month':
        return {'dailyOrders': '1,089', 'change': '+8%'};
      case 'Last 3 Months':
        return {'dailyOrders': '4,567', 'change': '+35%'};
      default:
        return {'dailyOrders': '320', 'change': '-5%'};
    }
  }

  List<double> _getDayHeights() {
    switch (_selectedTimeFrame) {
      case 'Today':
        return [85.0, 90.0, 75.0, 95.0, 80.0, 70.0, 88.0];
      case 'Last 7 Days':
        return [60.0, 80.0, 45.0, 95.0, 70.0, 55.0, 85.0];
      case 'Last 30 Days':
        return [75.0, 85.0, 65.0, 90.0, 80.0, 70.0, 88.0];
      case 'This Month':
        return [70.0, 85.0, 60.0, 88.0, 75.0, 65.0, 80.0];
      case 'Last 3 Months':
        return [80.0, 90.0, 70.0, 95.0, 85.0, 75.0, 90.0];
      default:
        return [60.0, 80.0, 45.0, 95.0, 70.0, 55.0, 85.0];
    }
  }

  Map<String, dynamic> _getChannelData() {
    switch (_selectedTimeFrame) {
      case 'Today':
        return {
          'percentage': '95%',
          'change': '+8%',
          'dineIn': 95.0,
          'phone': 3.0,
          'takeaway': 2.0,
        };
      case 'Last 7 Days':
        return {
          'percentage': '100%',
          'change': '+10%',
          'dineIn': 85.0,
          'phone': 8.0,
          'takeaway': 7.0,
        };
      case 'Last 30 Days':
        return {
          'percentage': '98%',
          'change': '+15%',
          'dineIn': 78.0,
          'phone': 12.0,
          'takeaway': 10.0,
        };
      case 'This Month':
        return {
          'percentage': '97%',
          'change': '+12%',
          'dineIn': 82.0,
          'phone': 10.0,
          'takeaway': 8.0,
        };
      case 'Last 3 Months':
        return {
          'percentage': '99%',
          'change': '+25%',
          'dineIn': 75.0,
          'phone': 15.0,
          'takeaway': 10.0,
        };
      default:
        return {
          'percentage': '100%',
          'change': '+10%',
          'dineIn': 85.0,
          'phone': 8.0,
          'takeaway': 7.0,
        };
    }
  }

  void _animateDataChange() {
    _animationController.reset();
    _animationController.forward();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.file_download_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Export Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your preferred export format:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exportReport('PDF');
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _exportReport('CSV');
                        },
                        icon: const Icon(Icons.table_chart),
                        label: const Text('CSV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // void _exportReport(String format) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Row(
  //         children: [
  //           Icon(Icons.check_circle_outline, color: Colors.white),
  //           const SizedBox(width: 12),
  //           Expanded(child: Text('Report exported as $format successfully!')),
  //         ],
  //       ),
  //       backgroundColor: Colors.green,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //     ),
  //   );
  // }
  void _exportReport(String format) async {
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Dialog(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating report...'),
          ],
        ),
      ),
    ),
  );

  try {
    final kpiData = _getKPIData();
    final chartData = _getChartData();
    final orderStats = _getOrderStatsData();
    final channelData = _getChannelData();

    File? file;
    if (format == 'PDF') {
      file = await ReportsPdfService.generateAnalyticsReport(
        timeFrame: _selectedTimeFrame,
        kpiData: kpiData,
        chartData: chartData,
        orderStats: orderStats,
        channelData: channelData,
      );
    } else if (format == 'CSV') {
      file = await ReportsCsvService.generateAnalyticsReport(
        timeFrame: _selectedTimeFrame,
        kpiData: kpiData,
        chartData: chartData,
        orderStats: orderStats,
        channelData: channelData,
      );
    }

    Navigator.of(context).pop(); // Close loading dialog

    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$format report generated successfully!'),
                    Text(
                      'Saved to: ${file.path}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text('Failed to generate $format report'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  } catch (e) {
    Navigator.of(context).pop(); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

}
