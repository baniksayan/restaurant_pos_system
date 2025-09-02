import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../view_models/providers/navigation_provider.dart';
import '../../view_models/providers/auth_provider.dart';
import '../../view_models/providers/profile_provider.dart';
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
              const SizedBox(height: 20),
              _buildFooter(),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Back button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () async {
              await _triggerHapticFeedback();
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        // Logout button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () async {
              await _triggerHapticFeedback();
              _showLogoutDialog();
            },
            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSections() {
    return Column(
      children: [
        // Restaurant Management Section
        _buildSimpleMenuSection(
          title: 'Restaurant Management',
          items: [
            _buildMenuItem(
              icon: Icons.store,
              title: 'Restaurant Details',
              subtitle: 'Edit restaurant information',
              onTap: () => _navigateToPage('restaurant_details'),
            ),
            _buildMenuItem(
              icon: Icons.people,
              title: 'Staff Management',
              subtitle: 'Manage staff and permissions',
              onTap: () => _navigateToPage('staff_management'),
            ),
            _buildMenuItem(
              icon: Icons.table_restaurant,
              title: 'Table Configuration',
              subtitle: 'Manage tables and seating',
              onTap: () => _navigateToPage('table_config'),
            ),
            _buildMenuItem(
              icon: Icons.restaurant_menu,
              title: 'Menu Management',
              subtitle: 'Update menu items and prices',
              onTap: () => _navigateToPage('menu_management'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Business Analytics Section
        _buildSimpleMenuSection(
          title: 'Business Analytics',
          items: [
            _buildMenuItem(
              icon: Icons.bar_chart,
              title: 'Sales Reports',
              subtitle: 'Daily, weekly, monthly reports',
              onTap: () => _navigateToReports(),
            ),
            _buildMenuItem(
              icon: Icons.trending_up,
              title: 'Performance Metrics',
              subtitle: 'Popular items and peak hours',
              onTap: () => _navigateToPage('performance'),
            ),
            _buildMenuItem(
              icon: Icons.inventory,
              title: 'Inventory Reports',
              subtitle: 'Stock levels and alerts',
              onTap: () => _navigateToPage('inventory_reports'),
            ),
            _buildMenuItem(
              icon: Icons.group,
              title: 'Customer Analytics',
              subtitle: 'Customer behavior insights',
              onTap: () => _navigateToPage('customer_analytics'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Financial Management Section
        _buildSimpleMenuSection(
          title: 'Financial Management',
          items: [
            _buildMenuItem(
              icon: Icons.receipt_long,
              title: 'Daily Cash Management',
              subtitle: 'Opening, closing balance',
              onTap: () => _showCashManagementDialog(),
            ),
            _buildMenuItem(
              icon: Icons.money_off,
              title: 'Expense Tracking',
              subtitle: 'Record daily expenses',
              onTap: () => _navigateToPage('expenses'),
            ),
            _buildMenuItem(
              icon: Icons.assessment,
              title: 'Profit & Loss',
              subtitle: 'Financial performance',
              onTap: () => _navigateToPage('profit_loss'),
            ),
            _buildMenuItem(
              icon: Icons.file_copy,
              title: 'Tax Reports',
              subtitle: 'GST and tax calculations',
              onTap: () => _navigateToPage('tax_reports'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // System & Settings Section
        _buildSimpleMenuSection(
          title: 'System & Settings',
          items: [
            _buildMenuItem(
              icon: Icons.print,
              title: 'Printer Settings',
              subtitle: 'Configure receipt and kitchen printers',
              onTap: () => _showPrinterSettingsDialog(),
            ),
            _buildMenuItem(
              icon: Icons.payment,
              title: 'Payment Methods',
              subtitle: 'Enable payment options',
              onTap: () => _navigateToPage('payment_settings'),
            ),
            _buildMenuItem(
              icon: Icons.percent,
              title: 'Tax Configuration',
              subtitle: 'GST rates and service charges',
              onTap: () => _navigateToPage('tax_config'),
            ),
            _buildMenuItem(
              icon: Icons.backup,
              title: 'Data Backup',
              subtitle: 'Backup and restore data',
              onTap: () => _navigateToPage('backup'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Help & Support Section
        _buildSimpleMenuSection(
          title: 'Help & Support',
          items: [
            _buildMenuItem(
              icon: Icons.book,
              title: 'User Manual',
              subtitle: 'How to use the app',
              onTap: () => _navigateToPage('user_manual'),
            ),
            _buildMenuItem(
              icon: Icons.support_agent,
              title: 'Technical Support',
              subtitle: 'Contact support team',
              onTap: () => _navigateToPage('support'),
            ),
            _buildMenuItem(
              icon: Icons.system_update,
              title: 'App Updates',
              subtitle: 'Check for updates',
              onTap: () => _navigateToPage('updates'),
            ),
            _buildMenuItem(
              icon: Icons.info,
              title: 'About App',
              subtitle: 'Version and app information',
              onTap: () => _navigateToPage('about'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.grey[600], size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
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
          Icon(Icons.info_outline, color: Colors.grey[400], size: 24),
          const SizedBox(height: 12),
          Text(
            'App Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Build 2025.08.21',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToPage(String pageName) async {
    await _triggerHapticFeedback();
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

  void _navigateToReports() async {
    await _triggerHapticFeedback();
    final navProvider = context.read<NavigationProvider>();
    navProvider.navigateToIndex(4);
  }

  void _showEditProfileDialog() async {
    await _triggerHapticFeedback();
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  void _showPrinterSettingsDialog() async {
    await _triggerHapticFeedback();
    showDialog(
      context: context,
      builder: (context) => const PrinterSettingsDialog(),
    );
  }

  void _showCashManagementDialog() async {
    await _triggerHapticFeedback();
    showDialog(
      context: context,
      builder: (context) => const CashManagementDialog(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text('Sign Out'),
              ],
            ),
            content: const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _performCompleteLogout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  Future<void> _performCompleteLogout() async {
    try {
      // Show loading
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

      // Logout from AuthProvider (this returns Future<void>)
      await context.read<AuthProvider>().logout();

      // FIX: ProfileProvider logout returns void, so DON'T use await
      try {
        context.read<ProfileProvider>().logout(); // Remove 'await' here
      } catch (e) {
        // ProfileProvider might not have logout method, continue anyway
        print('ProfileProvider logout error: $e');
      }

      // Brief delay for UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // COMPLETE RESET: Go back to splash/login
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/', // Should route to splash screen first
          (Route<dynamic> route) => false, // Clear ALL routes
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.construction,
                    color: Colors.grey[600],
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
}
