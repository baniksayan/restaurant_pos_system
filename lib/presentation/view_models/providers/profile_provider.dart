// lib/presentation/view_models/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../../../data/models/waiter_profile.dart';

class ProfileProvider extends ChangeNotifier {
  WaiterProfile? _currentWaiter;
  List<String> _activeTableAssignments = [];
  List<OrderHistory> _recentOrders = [];
  List<Achievement> _achievements = [];
  bool _isOnBreak = false;
  DateTime? _breakStartTime;

  WaiterProfile? get currentWaiter => _currentWaiter;
  List<String> get activeTableAssignments => _activeTableAssignments;
  List<OrderHistory> get recentOrders => _recentOrders;
  List<Achievement> get achievements => _achievements;
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
      'Table 1 - Occupied (Smith Family)',
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
