import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/waiter_profile.dart';
import 'package:restaurant_pos_system/presentation/views/profile/services/profile_dialog_service.dart';
import 'package:restaurant_pos_system/presentation/views/profile/widgets/profile_menu_section.dart';


class ProfileProvider extends ChangeNotifier {
  WaiterProfile? _currentWaiter;
  List _activeTableAssignments = [];
  List _recentOrders = [];
  List _achievements = [];
  bool _isOnBreak = false;
  DateTime? _breakStartTime;

  WaiterProfile? get currentWaiter => _currentWaiter;
  List get activeTableAssignments => _activeTableAssignments;
  List get recentOrders => _recentOrders;
  List get achievements => _achievements;
  bool get isOnBreak => _isOnBreak;
  DateTime? get breakStartTime => _breakStartTime;

  // Initialize waiter profile
  void initializeProfile() {
    _currentWaiter = _getSampleWaiterProfile();
    _loadActiveAssignments();
    _loadRecentOrders();
    _loadAchievements();
    notifyListeners();
  }

  // Toggle break status
  void toggleBreakStatus() {
    _isOnBreak = !_isOnBreak;
    _breakStartTime = _isOnBreak ? DateTime.now() : null;
    notifyListeners();
  }

  // Update waiter stats
  void updateStats({
    int? tablesServed,
    int? ordersTaken,
    double? salesAmount,
    int? customersServed,
  }) {
    if (_currentWaiter != null) {
      // Update stats logic here
      notifyListeners();
    }
  }

  // Restaurant Management Menu Items
  List<ProfileMenuItem> getRestaurantMenuItems(BuildContext context) {
    return [
      ProfileMenuItem(
        icon: Icons.store,
        title: 'Restaurant Details',
        subtitle: 'Edit restaurant information',
        onTap: () => ProfileDialogService.navigateToPage(context, 'restaurant_details'),
      ),
      ProfileMenuItem(
        icon: Icons.people,
        title: 'Staff Management', 
        subtitle: 'Manage staff and permissions',
        onTap: () => ProfileDialogService.navigateToPage(context, 'staff_management'),
      ),
      ProfileMenuItem(
        icon: Icons.table_restaurant,
        title: 'Table Configuration',
        subtitle: 'Manage tables and seating',
        onTap: () => ProfileDialogService.navigateToPage(context, 'table_config'),
      ),
      ProfileMenuItem(
        icon: Icons.restaurant_menu,
        title: 'Menu Management',
        subtitle: 'Update menu items and prices',
        onTap: () => ProfileDialogService.navigateToPage(context, 'menu_management'),
      ),
    ];
  }

  // Analytics Menu Items
  List<ProfileMenuItem> getAnalyticsMenuItems(BuildContext context) {
    return [
      ProfileMenuItem(
        icon: Icons.bar_chart,
        title: 'Sales Reports',
        subtitle: 'Daily, weekly, monthly reports',
        onTap: () => ProfileDialogService.navigateToReports(context),
      ),
      ProfileMenuItem(
        icon: Icons.trending_up,
        title: 'Performance Metrics',
        subtitle: 'Popular items and peak hours',
        onTap: () => ProfileDialogService.navigateToPage(context, 'performance'),
      ),
      ProfileMenuItem(
        icon: Icons.inventory,
        title: 'Inventory Reports',
        subtitle: 'Stock levels and alerts',
        onTap: () => ProfileDialogService.navigateToPage(context, 'inventory_reports'),
      ),
      ProfileMenuItem(
        icon: Icons.group,
        title: 'Customer Analytics',
        subtitle: 'Customer behavior insights',
        onTap: () => ProfileDialogService.navigateToPage(context, 'customer_analytics'),
      ),
    ];
  }

  // Financial Menu Items
  List<ProfileMenuItem> getFinancialMenuItems(BuildContext context) {
    return [
      ProfileMenuItem(
        icon: Icons.receipt_long,
        title: 'Daily Cash Management',
        subtitle: 'Opening, closing balance',
        onTap: () => ProfileDialogService.showCashManagementDialog(context),
      ),
      ProfileMenuItem(
        icon: Icons.money_off,
        title: 'Expense Tracking',
        subtitle: 'Record daily expenses',
        onTap: () => ProfileDialogService.navigateToPage(context, 'expenses'),
      ),
      ProfileMenuItem(
        icon: Icons.assessment,
        title: 'Profit & Loss',
        subtitle: 'Financial performance',
        onTap: () => ProfileDialogService.navigateToPage(context, 'profit_loss'),
      ),
      ProfileMenuItem(
        icon: Icons.file_copy,
        title: 'Tax Reports',
        subtitle: 'GST and tax calculations',
        onTap: () => ProfileDialogService.navigateToPage(context, 'tax_reports'),
      ),
    ];
  }

  // System Settings Menu Items
  List<ProfileMenuItem> getSystemMenuItems(BuildContext context) {
    return [
      ProfileMenuItem(
        icon: Icons.print,
        title: 'Printer Settings',
        subtitle: 'Configure receipt and kitchen printers',
        onTap: () => ProfileDialogService.showPrinterSettingsDialog(context),
      ),
      ProfileMenuItem(
        icon: Icons.payment,
        title: 'Payment Methods',
        subtitle: 'Enable payment options',
        onTap: () => ProfileDialogService.navigateToPage(context, 'payment_settings'),
      ),
      ProfileMenuItem(
        icon: Icons.percent,
        title: 'Tax Configuration',
        subtitle: 'GST rates and service charges',
        onTap: () => ProfileDialogService.navigateToPage(context, 'tax_config'),
      ),
      ProfileMenuItem(
        icon: Icons.backup,
        title: 'Data Backup',
        subtitle: 'Backup and restore data',
        onTap: () => ProfileDialogService.navigateToPage(context, 'backup'),
      ),
    ];
  }

  // Help & Support Menu Items
  List<ProfileMenuItem> getHelpMenuItems(BuildContext context) {
    return [
      ProfileMenuItem(
        icon: Icons.book,
        title: 'User Manual',
        subtitle: 'How to use the app',
        onTap: () => ProfileDialogService.navigateToPage(context, 'user_manual'),
      ),
      ProfileMenuItem(
        icon: Icons.support_agent,
        title: 'Technical Support',
        subtitle: 'Contact support team',
        onTap: () => ProfileDialogService.navigateToPage(context, 'support'),
      ),
      ProfileMenuItem(
        icon: Icons.system_update,
        title: 'App Updates',
        subtitle: 'Check for updates',
        onTap: () => ProfileDialogService.navigateToPage(context, 'updates'),
      ),
      ProfileMenuItem(
        icon: Icons.info,
        title: 'About App',
        subtitle: 'Version and app information',
        onTap: () => ProfileDialogService.showAboutDialog(context),
      ),
    ];
  }

  // Sample data (replace with API calls)
  WaiterProfile _getSampleWaiterProfile() {
    return WaiterProfile(
      id: 'W001',
      employeeId: 'EMP2024001',
      name: 'Rajesh Kumar',
      email: 'rajesh.kumar@wizardrestaurant.com',
      phone: '+91 98765 43210',
      profileImage: null,
      position: 'Senior Waiter',
      department: 'Floor Service',
      joinDate: DateTime(2023, 1, 15),
      lastLogin: DateTime.now().subtract(const Duration(minutes: 30)),
      isActive: true,
      rating: 4.7,
      stats: WaiterStats(
        totalTablesServed: 1247,
        totalOrdersTaken: 3521,
        totalSalesAmount: 285670.50,
        customersServed: 2890,
        averageOrderValue: 810.25,
        complaintCount: 5,
        complimentCount: 47,
        lastUpdated: DateTime.now(),
      ),
      assignedSections: ['Main Hall', 'Terrace'],
      currentShift: WaiterShift(
        shiftId: 'SHIFT_${DateTime.now().millisecondsSinceEpoch}',
        shiftStart: DateTime.now().subtract(const Duration(hours: 4)),
        shiftEnd: null,
        shiftType: 'Evening',
        assignedTables: ['Table 1', 'Table 2', 'Table 5', 'Table 8', 'Terrace 1', 'Terrace 2'],
        shiftSales: 12450.75,
        ordersCompleted: 18,
      ),
      permissions: ['VIP_ACCESS', 'CASH_HANDLING', 'DISCOUNT_APPROVAL'],
    );
  }

  void _loadActiveAssignments() {
    _activeTableAssignments = [
      'Table 1 - Occupied (Banik Family)',
      'Table 5 - Reserved (8:30 PM)',
      'Terrace 1 - Occupied (Birthday Party)',
      'Table 8 - Cleaning Required',
    ];
  }

  void _loadRecentOrders() {
    _recentOrders = [
      OrderHistory(
        orderId: 'ORD20241201001',
        tableNumber: 'Table 1',
        amount: 1250.50,
        items: 5,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'Completed',
      ),
      OrderHistory(
        orderId: 'ORD20241201002',
        tableNumber: 'Terrace 1',
        amount: 2340.75,
        items: 8,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        status: 'In Kitchen',
      ),
      // Add more orders...
    ];
  }

  void _loadAchievements() {
    _achievements = [
      Achievement(
        title: 'Top Performer',
        description: 'Highest sales this month',
        icon: Icons.star,
        earnedDate: DateTime.now().subtract(const Duration(days: 2)),
        type: 'Monthly',
      ),
      Achievement(
        title: 'Customer Favorite',
        description: '50+ compliments received',
        icon: Icons.favorite,
        earnedDate: DateTime.now().subtract(const Duration(days: 15)),
        type: 'Milestone',
      ),
      // Add more achievements...
    ];
  }

  void logout() {
    _currentWaiter = null;
    _activeTableAssignments.clear();
    _recentOrders.clear();
    _achievements.clear();
    _isOnBreak = false;
    _breakStartTime = null;
    notifyListeners();
  }
}

class OrderHistory {
  final String orderId;
  final String tableNumber;
  final double amount;
  final int items;
  final DateTime timestamp;
  final String status;

  OrderHistory({
    required this.orderId,
    required this.tableNumber,
    required this.amount,
    required this.items,
    required this.timestamp,
    required this.status,
  });
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final DateTime earnedDate;
  final String type;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.earnedDate,
    required this.type,
  });
}
