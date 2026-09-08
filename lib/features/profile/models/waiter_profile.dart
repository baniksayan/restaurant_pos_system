class WaiterProfile {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String position; // Waiter, Senior Waiter, Floor Manager, etc.
  final String department; // Floor Service, VIP Section, etc.
  final DateTime joinDate;
  final DateTime? lastLogin;
  final bool isActive;
  final double rating; // Performance rating
  final WaiterStats stats;
  final List<String> assignedSections; // Main Hall, VIP, Terrace, etc.
  final WaiterShift currentShift;
  final List<String> permissions; // Can access VIP, Can handle cash, etc.

  WaiterProfile({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.position,
    required this.department,
    required this.joinDate,
    this.lastLogin,
    required this.isActive,
    required this.rating,
    required this.stats,
    required this.assignedSections,
    required this.currentShift,
    required this.permissions,
  });
}

class WaiterStats {
  final int totalTablesServed;
  final int totalOrdersTaken;
  final double totalSalesAmount;
  final int customersServed;
  final double averageOrderValue;
  final int complaintCount;
  final int complimentCount;
  final DateTime lastUpdated;

  WaiterStats({
    required this.totalTablesServed,
    required this.totalOrdersTaken,
    required this.totalSalesAmount,
    required this.customersServed,
    required this.averageOrderValue,
    required this.complaintCount,
    required this.complimentCount,
    required this.lastUpdated,
  });
}

class WaiterShift {
  final String shiftId;
  final DateTime shiftStart;
  final DateTime? shiftEnd;
  final String shiftType; // Morning, Evening, Night
  final List<String> assignedTables;
  final double shiftSales;
  final int ordersCompleted;

  WaiterShift({
    required this.shiftId,
    required this.shiftStart,
    this.shiftEnd,
    required this.shiftType,
    required this.assignedTables,
    required this.shiftSales,
    required this.ordersCompleted,
  });
}
