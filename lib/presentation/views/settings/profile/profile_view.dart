// lib/presentation/views/settings/profile_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/profile_provider.dart';
import '../../../view_models/providers/auth_provider.dart';
import '../../auth/login/login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().initializeProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            final waiter = profileProvider.currentWaiter;
            
            if (waiter == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildProfileHeader(waiter, profileProvider),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(waiter, profileProvider),
                      _buildPerformanceTab(waiter),
                      _buildAssignmentsTab(profileProvider),
                      _buildSettingsTab(waiter),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(waiter, ProfileProvider profileProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Header row with logout
          Row(
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Profile info
          Row(
            children: [
              // Profile picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: waiter.profileImage != null
                    ? ClipOval(
                        child: Image.network(
                          waiter.profileImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          waiter.name.split(' ').map((n) => n[0]).take(2).join(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(width: 20),
              
              // Profile details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      waiter.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${waiter.position} • ${waiter.employeeId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${waiter.rating}/5.0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Break/Status toggle
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: profileProvider.isOnBreak ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profileProvider.isOnBreak ? 'On Break' : 'Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => profileProvider.toggleBreakStatus(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        profileProvider.isOnBreak ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Performance'),
          Tab(text: 'Assignments'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(waiter, ProfileProvider profileProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current shift info
          _buildShiftCard(waiter.currentShift),
          
          const SizedBox(height: 16),
          
          // Quick stats
          _buildQuickStats(waiter.stats),
          
          const SizedBox(height: 16),
          
          // Recent orders
          _buildRecentOrdersCard(profileProvider.recentOrders),
          
          const SizedBox(height: 16),
          
          // Achievements
          _buildAchievementsCard(profileProvider.achievements),
        ],
      ),
    );
  }

  Widget _buildShiftCard(currentShift) {
    final shiftDuration = DateTime.now().difference(currentShift.shiftStart);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Current Shift',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentShift.shiftType,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildShiftStat(
                  'Duration',
                  '${shiftDuration.inHours}h ${shiftDuration.inMinutes % 60}m',
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildShiftStat(
                  'Orders',
                  '${currentShift.ordersCompleted}',
                  Icons.receipt,
                ),
              ),
              Expanded(
                child: _buildShiftStat(
                  'Sales',
                  '₹${currentShift.shiftSales.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tables Served',
                  '${stats.totalTablesServed}',
                  Icons.table_restaurant,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  '${stats.totalOrdersTaken}',
                  Icons.restaurant_menu,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Sales',
                  '₹${(stats.totalSalesAmount / 1000).toStringAsFixed(0)}K',
                  Icons.monetization_on,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Order',
                  '₹${stats.averageOrderValue.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard(List<OrderHistory> orders) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to all orders
                },
                child: const Text('View All'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ...orders.take(3).map((order) => _buildOrderItem(order)).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderHistory order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: _getStatusColor(order.status),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.tableNumber} • ${order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${order.items} items • ₹${order.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(order.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(List<Achievement> achievements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...achievements.take(3).map((achievement) => _buildAchievementItem(achievement)).toList(),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              achievement.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            _formatDate(achievement.earnedDate),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(waiter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance metrics
          _buildPerformanceMetrics(waiter.stats),
          
          const SizedBox(height: 16),
          
          // Weekly performance chart
          _buildPerformanceChart(),
          
          const SizedBox(height: 16),
          
          // Comparison with team
          _buildTeamComparison(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Customer Satisfaction',
                  '${((stats.complimentCount / (stats.complimentCount + stats.complaintCount)) * 100).toStringAsFixed(1)}%',
                  Icons.sentiment_very_satisfied,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Service Rating',
                  '${stats.complimentCount - stats.complaintCount}',
                  Icons.star_rate,
                  Colors.amber,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Orders/Day',
                  '${(stats.totalOrdersTaken / 30).toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Revenue/Day',
                  '₹${(stats.totalSalesAmount / 30).toStringAsFixed(0)}',
                  Icons.monetization_on,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Chart will be implemented with fl_chart\nShowing weekly sales, orders, ratings',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Ranking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildRankingItem('You', 2, '₹12,450', true),
          _buildRankingItem('Priya Sharma', 1, '₹14,230', false),
          _buildRankingItem('Ahmed Khan', 3, '₹11,890', false),
          _buildRankingItem('Sneha Patel', 4, '₹9,670', false),
        ],
      ),
    );
  }

  Widget _buildRankingItem(String name, int rank, String sales, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                color: isCurrentUser ? AppColors.primary : Colors.black,
              ),
            ),
          ),
          
          Text(
            sales,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? AppColors.primary : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab(ProfileProvider profileProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current table assignments
          _buildCurrentAssignments(profileProvider.activeTableAssignments),
          
          const SizedBox(height: 16),
          
          // Shift schedule
          _buildShiftSchedule(),
          
          const SizedBox(height: 16),
          
          // Assigned sections
          _buildAssignedSections(),
        ],
      ),
    );
  }

  Widget _buildCurrentAssignments(List<String> assignments) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Table Assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ...assignments.map((assignment) => _buildAssignmentItem(assignment)).toList(),
        ],
      ),
    );
  }

  Widget _buildAssignmentItem(String assignment) {
    final parts = assignment.split(' - ');
    final tableName = parts[0];
    final status = parts.length > 1 ? parts[1] : 'Available';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTableStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.table_restaurant,
              color: _getTableStatusColor(status),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tableName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: _getTableStatusColor(status),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week\'s Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sample schedule - replace with real data
          _buildScheduleDay('Today', 'Evening Shift', '2:00 PM - 10:00 PM', true),
          _buildScheduleDay('Tomorrow', 'Morning Shift', '6:00 AM - 2:00 PM', false),
          _buildScheduleDay('Thursday', 'Evening Shift', '2:00 PM - 10:00 PM', false),
          _buildScheduleDay('Friday', 'Night Shift', '10:00 PM - 6:00 AM', false),
        ],
      ),
    );
  }

  Widget _buildScheduleDay(String day, String shift, String time, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday ? AppColors.primary : Colors.black,
                  ),
                ),
                Text(
                  shift,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isToday ? AppColors.primary : Colors.grey[700],
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedSections() {
    final sections = ['Main Hall', 'Terrace'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned Sections',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sections.map((section) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                section,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(waiter) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Personal info
          _buildPersonalInfoCard(waiter),
          
          const SizedBox(height: 16),
          
          // App settings
          _buildAppSettingsCard(),
          
          const SizedBox(height: 16),
          
          // Account actions
          _buildAccountActionsCard(),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(waiter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Edit profile
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoRow('Employee ID', waiter.employeeId),
          _buildInfoRow('Email', waiter.email),
          _buildInfoRow('Phone', waiter.phone),
          _buildInfoRow('Department', waiter.department),
          _buildInfoRow('Join Date', _formatDate(waiter.joinDate)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsTile(
            'Notifications',
            'Manage notification preferences',
            Icons.notifications,
            () {},
          ),
          _buildSettingsTile(
            'Language',
            'English',
            Icons.language,
            () {},
          ),
          _buildSettingsTile(
            'Theme',
            'Light Mode',
            Icons.palette,
            () {},
          ),
          _buildSettingsTile(
            'Privacy',
            'Privacy and security settings',
            Icons.privacy_tip,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsTile(
            'Help & Support',
            'Get help and contact support',
            Icons.help,
            () {},
          ),
          _buildSettingsTile(
            'About',
            'App version and information',
            Icons.info,
            () {},
          ),
          _buildSettingsTile(
            'Logout',
            'Sign out of your account',
            Icons.logout,
            () => _showLogoutDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout and end your shift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileProvider>().logout();
              context.read<AuthProvider>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in kitchen':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in kitchen':
        return Icons.restaurant;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  Color _getTableStatusColor(String status) {
    if (status.contains('Occupied')) return Colors.red;
    if (status.contains('Reserved')) return Colors.orange;
    if (status.contains('Cleaning')) return Colors.blue;
    return Colors.green;
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }
}
