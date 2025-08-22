// lib/presentation/views/reports/reports_view.dart

import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';

import 'widgets/tabs/overview_tab.dart';

// import 'widgets/tabs/sales_tab.dart';

// import 'widgets/tabs/performance_tab.dart';

// import 'widgets/tabs/customer_tab.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _selectedTimeFrame = 'Last 7 Days';

  final List<String> _timeFrames = [
    'Today',

    'Last 7 Days',

    'Last 30 Days',

    'This Month',

    'Last 3 Months',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 1,
      vsync: this,
    ); // Changed from 4 to 1
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildTabBar(),

            Expanded(
              child: TabBarView(
                controller: _tabController,

                children: [
                  OverviewTab(selectedTimeFrame: _selectedTimeFrame),

                  // SalesTab(selectedTimeFrame: _selectedTimeFrame),

                  // PerformanceTab(selectedTimeFrame: _selectedTimeFrame),

                  // CustomerTab(selectedTimeFrame: _selectedTimeFrame),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),

            blurRadius: 8,

            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],

                    begin: Alignment.topLeft,

                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.analytics,

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
                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                        color: AppColors.textPrimary,
                      ),
                    ),

                    Text(
                      'Business Performance Dashboard',

                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),

            decoration: BoxDecoration(
              color: Colors.grey[100],

              borderRadius: BorderRadius.circular(12),
            ),

            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeFrame,

                isExpanded: true,

                icon: const Icon(Icons.keyboard_arrow_down),

                items:
                    _timeFrames.map((String timeFrame) {
                      return DropdownMenuItem<String>(
                        value: timeFrame,

                        child: Padding(
                          padding: const EdgeInsets.all(8.0),

                          child: Text(timeFrame),
                        ),
                      );
                    }).toList(),

                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeFrame = newValue!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,

      child: TabBar(
        controller: _tabController,

        indicatorColor: AppColors.primary,

        labelColor: AppColors.primary,

        unselectedLabelColor: Colors.grey[600],

        indicatorWeight: 3,

        tabs: const [
          Tab(text: 'Overview'),

          // Tab(text: 'Sales'),     // Commented out

          // Tab(text: 'Performance'), // Commented out

          // Tab(text: 'Customers'),   // Commented out
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }
}
