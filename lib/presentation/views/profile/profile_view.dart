import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../view_models/providers/navigation_provider.dart';
import '../../view_models/providers/auth_provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_section.dart';
import 'widgets/quick_stats_card.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/printer_settings_dialog.dart';
import 'widgets/cash_management_dialog.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Future<void> _triggerHapticFeedback() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              ProfileHeader(onEditPressed: _showEditProfileDialog),
              const SizedBox(height: 20),
              const QuickStatsCard(),
              const SizedBox(height: 24),
              _buildMenuSections(),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Spacer(),
        // Removed settings button as requested
      ],
    );
  }

  Widget _buildMenuSections() {
    return Column(
      children: [
        // Restaurant Management Section
        ProfileMenuSection(
          title: 'Restaurant Management',
          icon: Icons.restaurant,
          color: Colors.orange,
          items: [
            ProfileMenuItem(
              icon: Icons.store,
              title: 'Restaurant Details',
              subtitle: 'Edit restaurant information',
              onTap: () => _navigateToPage('restaurant_details'),
            ),
            ProfileMenuItem(
              icon: Icons.people,
              title: 'Staff Management',
              subtitle: 'Manage staff and permissions',
              onTap: () => _navigateToPage('staff_management'),
            ),
            ProfileMenuItem(
              icon: Icons.table_restaurant,
              title: 'Table Configuration',
              subtitle: 'Manage tables and seating',
              onTap: () => _navigateToPage('table_config'),
            ),
            ProfileMenuItem(
              icon: Icons.restaurant_menu,
              title: 'Menu Management',
              subtitle: 'Update menu items and prices',
              onTap: () => _navigateToPage('menu_management'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Business Analytics Section
        ProfileMenuSection(
          title: 'Business Analytics',
          icon: Icons.analytics,
          color: Colors.blue,
          items: [
            ProfileMenuItem(
              icon: Icons.bar_chart,
              title: 'Sales Reports',
              subtitle: 'Daily, weekly, monthly reports',
              onTap:
                  () =>
                      _navigateToReports(), // Changed to navigate to reports tab
            ),
            ProfileMenuItem(
              icon: Icons.trending_up,
              title: 'Performance Metrics',
              subtitle: 'Popular items and peak hours',
              onTap: () => _navigateToPage('performance'),
            ),
            ProfileMenuItem(
              icon: Icons.inventory,
              title: 'Inventory Reports',
              subtitle: 'Stock levels and alerts',
              onTap: () => _navigateToPage('inventory_reports'),
            ),
            ProfileMenuItem(
              icon: Icons.group,
              title: 'Customer Analytics',
              subtitle: 'Customer behavior insights',
              onTap: () => _navigateToPage('customer_analytics'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Financial Management Section
        ProfileMenuSection(
          title: 'Financial Management',
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          items: [
            ProfileMenuItem(
              icon: Icons.receipt_long,
              title: 'Daily Cash Management',
              subtitle: 'Opening, closing balance',
              onTap:
                  () =>
                      _showCashManagementDialog(), // Show cash management dialog
            ),
            ProfileMenuItem(
              icon: Icons.money_off,
              title: 'Expense Tracking',
              subtitle: 'Record daily expenses',
              onTap: () => _navigateToPage('expenses'),
            ),
            ProfileMenuItem(
              icon: Icons.assessment,
              title: 'Profit & Loss',
              subtitle: 'Financial performance',
              onTap: () => _navigateToPage('profit_loss'),
            ),
            ProfileMenuItem(
              icon: Icons.file_copy,
              title: 'Tax Reports',
              subtitle: 'GST and tax calculations',
              onTap: () => _navigateToPage('tax_reports'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // System & Settings Section
        ProfileMenuSection(
          title: 'System & Settings',
          icon: Icons.settings,
          color: Colors.purple,
          items: [
            ProfileMenuItem(
              icon: Icons.print,
              title: 'Printer Settings',
              subtitle: 'Configure receipt and kitchen printers',
              onTap:
                  () =>
                      _showPrinterSettingsDialog(), // Show printer settings dialog
            ),
            ProfileMenuItem(
              icon: Icons.payment,
              title: 'Payment Methods',
              subtitle: 'Enable payment options',
              onTap: () => _navigateToPage('payment_settings'),
            ),
            ProfileMenuItem(
              icon: Icons.percent,
              title: 'Tax Configuration',
              subtitle: 'GST rates and service charges',
              onTap: () => _navigateToPage('tax_config'),
            ),
            ProfileMenuItem(
              icon: Icons.backup,
              title: 'Data Backup',
              subtitle: 'Backup and restore data',
              onTap: () => _navigateToPage('backup'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Help & Support Section
        ProfileMenuSection(
          title: 'Help & Support',
          icon: Icons.help,
          color: Colors.teal,
          items: [
            ProfileMenuItem(
              icon: Icons.book,
              title: 'User Manual',
              subtitle: 'How to use the app',
              onTap: () => _navigateToPage('user_manual'),
            ),
            ProfileMenuItem(
              icon: Icons.support_agent,
              title: 'Technical Support',
              subtitle: 'Contact support team',
              onTap: () => _navigateToPage('support'),
            ),
            ProfileMenuItem(
              icon: Icons.system_update,
              title: 'App Updates',
              subtitle: 'Check for updates',
              onTap: () => _navigateToPage('updates'),
            ),
            ProfileMenuItem(
              icon: Icons.info,
              title: 'About App',
              subtitle: 'Version and app information',
              onTap: () => _navigateToPage('about'),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Logout Section
        Container(
          width: double.infinity,
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
            children: [
              ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'App Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToPage(String pageName) async {
    await _triggerHapticFeedback();

    // Navigate to specific pages based on pageName
    switch (pageName) {
      case 'restaurant_details':
        _showComingSoonDialog('Restaurant Details');
        break;
      case 'staff_management':
        _showComingSoonDialog('Staff Management');
        break;
      case 'table_config':
        _showComingSoonDialog('Table Configuration');
        break;
      case 'menu_management':
        _showComingSoonDialog('Menu Management');
        break;
      case 'performance':
        _showComingSoonDialog('Performance Metrics');
        break;
      case 'inventory_reports':
        _showComingSoonDialog('Inventory Reports');
        break;
      case 'customer_analytics':
        _showComingSoonDialog('Customer Analytics');
        break;
      case 'expenses':
        _showComingSoonDialog('Expense Tracking');
        break;
      case 'profit_loss':
        _showComingSoonDialog('Profit & Loss');
        break;
      case 'tax_reports':
        _showComingSoonDialog('Tax Reports');
        break;
      case 'payment_settings':
        _showComingSoonDialog('Payment Settings');
        break;
      case 'tax_config':
        _showComingSoonDialog('Tax Configuration');
        break;
      case 'backup':
        _showComingSoonDialog('Data Backup');
        break;
      case 'user_manual':
        _showComingSoonDialog('User Manual');
        break;
      case 'support':
        _showComingSoonDialog('Technical Support');
        break;
      case 'updates':
        _showComingSoonDialog('App Updates');
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  // Navigate to Reports tab
  void _navigateToReports() async {
    await _triggerHapticFeedback();
    final navProvider = context.read<NavigationProvider>();
    navProvider.navigateToIndex(4); // Navigate to Reports tab (index 4)
  }

  // Show Edit Profile Dialog
  void _showEditProfileDialog() async {
    await _triggerHapticFeedback();
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  // Show Printer Settings Dialog
  void _showPrinterSettingsDialog() async {
    await _triggerHapticFeedback();
    showDialog(
      context: context,
      builder: (context) => const PrinterSettingsDialog(),
    );
  }

  // Show Cash Management Dialog
  void _showCashManagementDialog() async {
    await _triggerHapticFeedback();
    showDialog(
      context: context,
      builder: (context) => const CashManagementDialog(),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.construction,
                    color: Colors.blue,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This feature is coming soon!\nStay tuned for updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('About WiZARD POS'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WiZARD Restaurant Management System'),
                const SizedBox(height: 8),
                const Text('Version: 1.0.0'),
                const Text('Build: 2025.08.21'),
                const SizedBox(height: 16),
                const Text(
                  'A comprehensive restaurant management solution for modern dining experiences.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('© 2025 WiZARD Solutions'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  void _performLogout() async {
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
                  Text('Logging out...'),
                ],
              ),
            ),
      );

      // Perform logout
      await context.read<AuthProvider>().logout();

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
