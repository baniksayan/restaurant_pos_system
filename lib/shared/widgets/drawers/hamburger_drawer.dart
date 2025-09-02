// lib/shared/widgets/drawers/hamburger_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/app_colors.dart';
import '../../../presentation/view_models/providers/dashboard_provider.dart';
import '../../../presentation/view_models/providers/table_provider.dart';
import '../../../presentation/view_models/providers/auth_provider.dart';
import '../../../presentation/view_models/providers/navigation_provider.dart';
import '../../../presentation/views/profile/profile_view.dart';

class HamburgerDrawer extends StatefulWidget {
  final String selectedLocation;
  final Function(String) onLocationChanged;
  final Function(String) onStatusFilterChanged;
  final String selectedStatusFilter;

  const HamburgerDrawer({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
    required this.onStatusFilterChanged,
    required this.selectedStatusFilter,
  });

  @override
  State<HamburgerDrawer> createState() => _HamburgerDrawerState();
}

class _HamburgerDrawerState extends State<HamburgerDrawer> {
  bool _isProfileExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _buildLocationFilters(), // First: Locations
                    const Divider(thickness: 1, height: 32),
                    _buildTableStatusFilters(), // Second: Table Status
                    const Divider(thickness: 1, height: 32),
                    _buildProfileSection(), // Third: Profile
                    const Divider(thickness: 1, height: 32),
                    // _buildSignOutSection(), // Fourth: Sign Out
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          const Text(
            'WiZARD Restaurant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFilters() {
    return Consumer2<DashboardProvider, TableProvider>(
      builder: (context, dashboardProvider, tableProvider, child) {
        // Get locations that actually have tables
        final availableLocations = _getAvailableLocations(
          dashboardProvider.locations,
          tableProvider.tables,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Locations',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Show only specific locations (removed "All Tables" option)
            ...availableLocations.map(
              (location) => _buildLocationTile(location),
            ),
          ],
        );
      },
    );
  }

  // Helper method to get available locations that have tables
  List _getAvailableLocations(List allLocations, List tables) {
    return allLocations.where((location) {
      return tables.any((table) => table.location == location.name);
    }).toList();
  }

  Widget _buildLocationTile(LocationSection location) {
    final isSelected = widget.selectedLocation == location.name;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? location.color.withOpacity(0.1) : null,
        border:
            isSelected
                ? Border.all(color: location.color.withOpacity(0.3), width: 1)
                : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected ? location.color : location.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: location.color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Icon(
            location.icon,
            color: isSelected ? Colors.white : location.color,
            size: 18,
          ),
        ),
        title: Text(
          location.name,
          style: TextStyle(
            color: isSelected ? location.color : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        trailing:
            isSelected
                ? Icon(Icons.check_circle, color: location.color, size: 16)
                : null,
        onTap: () => widget.onLocationChanged(location.name),
      ),
    );
  }

  Widget _buildTableStatusFilters() {
    final statusFilters = [
      _StatusFilter('All Tables', 'all', Icons.table_restaurant, Colors.grey),
      _StatusFilter(
        'Available',
        'available',
        Icons.check_circle,
        const Color(0xFF10B981),
      ),
      _StatusFilter(
        'Occupied',
        'occupied',
        Icons.people,
        const Color(0xFFEF4444),
      ),
      _StatusFilter(
        'Reserved',
        'reserved',
        Icons.event,
        const Color(0xFFF59E0B),
      ),
      _StatusFilter(
        'KOT Generated',
        'kot_generated',
        Icons.receipt,
        const Color(0xFF8B5CF6),
      ),
      _StatusFilter(
        'Bill Generated',
        'bill_generated',
        Icons.payment,
        const Color(0xFF06B6D4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Table Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...statusFilters.map((filter) => _buildStatusFilterTile(filter)),
      ],
    );
  }

  Widget _buildStatusFilterTile(_StatusFilter filter) {
    final isSelected = widget.selectedStatusFilter == filter.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? filter.color.withOpacity(0.1) : null,
        border:
            isSelected
                ? Border.all(color: filter.color.withOpacity(0.3), width: 1)
                : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? filter.color : filter.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: filter.color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Icon(
            filter.icon,
            color: isSelected ? Colors.white : filter.color,
            size: 18,
          ),
        ),
        title: Text(
          filter.name,
          style: TextStyle(
            color: isSelected ? filter.color : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        trailing:
            isSelected
                ? Icon(Icons.check_circle, color: filter.color, size: 16)
                : null,
        onTap: () => widget.onStatusFilterChanged(filter.value),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color:
                _isProfileExpanded ? AppColors.primary.withOpacity(0.1) : null,
            border:
                _isProfileExpanded
                    ? Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    )
                    : null,
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _isProfileExpanded
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                boxShadow:
                    _isProfileExpanded
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                Icons.person,
                color: _isProfileExpanded ? Colors.white : AppColors.primary,
                size: 18,
              ),
            ),
            title: Text(
              'Profile',
              style: TextStyle(
                color:
                    _isProfileExpanded
                        ? AppColors.primary
                        : AppColors.textPrimary,
                fontWeight:
                    _isProfileExpanded ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              _isProfileExpanded ? Icons.expand_less : Icons.expand_more,
              color: _isProfileExpanded ? AppColors.primary : Colors.grey[400],
              size: 20,
            ),
            onTap: () {
              setState(() {
                _isProfileExpanded = !_isProfileExpanded;
              });
            },
          ),
        ),
        if (_isProfileExpanded) _buildProfileSubMenu(),
      ],
    );
  }

  Widget _buildProfileSubMenu() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 8, top: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildProfileSubItem('View Profile', Icons.person_outline, () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileView()),
            );
          }),
          _buildProfileSubItem('Settings', Icons.settings_outlined, () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings coming soon!')),
            );
          }),
          _buildProfileSubItem('Performance', Icons.analytics_outlined, () {
            Navigator.pop(context);
            // Navigate to Reports tab
            context.read<NavigationProvider>().navigateToReports();
          }),
        ],
      ),
    );
  }

  Widget _buildProfileSubItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      leading: Icon(icon, color: Colors.grey[600], size: 16),
      title: Text(
        title,
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSignOutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 18),
        ),
        
      ),
    );
  }


  Future<void> _performLogout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Signing out...'),
                ],
              ),
            ),
      );

      // Perform logout operations
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout(); // Clear tokens, user data, etc.

   

      // Small delay for UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Close loading dialog first
        Navigator.of(context, rootNavigator: true).pop();

        // COMPLETE RESET: Navigate to splash/login and remove ALL routes
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/', // This should go to your splash screen, then login
          (Route<dynamic> route) => false, // Remove ALL previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog on error
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _StatusFilter {
  final String name;
  final String value;
  final IconData icon;
  final Color color;

  _StatusFilter(this.name, this.value, this.icon, this.color);
}
