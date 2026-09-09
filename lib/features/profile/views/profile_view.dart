import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/printer_settings_dialog.dart';
import '../widgets/cash_management_dialog.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/services/app_version_service.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Future<void> _triggerHapticFeedback() => HapticHelper.triggerFeedback();

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
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () async {
              await _triggerHapticFeedback();
              if (!mounted) return;
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
                color: Colors.black.withValues(alpha: 0.05),
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
          title: AppStrings.profile.restaurantManagement,
          items: [
            _buildMenuItem(
              icon: Icons.store,
              title: AppStrings.profile.restaurantDetails,
              subtitle: AppStrings.profile.restaurantDetailsSubtitle,
              onTap: () => _navigateToPage('restaurant_details'),
            ),
            _buildMenuItem(
              icon: Icons.people,
              title: AppStrings.profile.staffManagement,
              subtitle: AppStrings.profile.staffManagementSubtitle,
              onTap: () => _navigateToPage('staff_management'),
            ),
            _buildMenuItem(
              icon: Icons.table_restaurant,
              title: AppStrings.profile.tableConfiguration,
              subtitle: AppStrings.profile.tableConfigurationSubtitle,
              onTap: () => _navigateToPage('table_config'),
            ),
            _buildMenuItem(
              icon: Icons.restaurant_menu,
              title: AppStrings.profile.menuManagement,
              subtitle: AppStrings.profile.menuManagementSubtitle,
              onTap: () => _navigateToPage('menu_management'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Business Analytics Section
        _buildSimpleMenuSection(
          title: AppStrings.profile.businessAnalytics,
          items: [
            _buildMenuItem(
              icon: Icons.bar_chart,
              title: AppStrings.profile.salesReports,
              subtitle: AppStrings.profile.salesReportsSubtitle,
              onTap: () => _navigateToReports(),
            ),
            _buildMenuItem(
              icon: Icons.trending_up,
              title: AppStrings.profile.performanceMetrics,
              subtitle: AppStrings.profile.performanceMetricsSubtitle,
              onTap: () => _navigateToPage('performance'),
            ),
            _buildMenuItem(
              icon: Icons.inventory,
              title: AppStrings.profile.inventoryReports,
              subtitle: AppStrings.profile.inventoryReportsSubtitle,
              onTap: () => _navigateToPage('inventory_reports'),
            ),
            _buildMenuItem(
              icon: Icons.group,
              title: AppStrings.profile.customerAnalytics,
              subtitle: AppStrings.profile.customerAnalyticsSubtitle,
              onTap: () => _navigateToPage('customer_analytics'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Financial Management Section
        _buildSimpleMenuSection(
          title: AppStrings.profile.financialManagement,
          items: [
            _buildMenuItem(
              icon: Icons.receipt_long,
              title: AppStrings.profile.dailyCashManagement,
              subtitle: AppStrings.profile.dailyCashManagementSubtitle,
              onTap: () => _showCashManagementDialog(),
            ),
            _buildMenuItem(
              icon: Icons.money_off,
              title: AppStrings.profile.expenseTracking,
              subtitle: AppStrings.profile.expenseTrackingSubtitle,
              onTap: () => _navigateToPage('expenses'),
            ),
            _buildMenuItem(
              icon: Icons.assessment,
              title: AppStrings.profile.profitAndLoss,
              subtitle: AppStrings.profile.profitAndLossSubtitle,
              onTap: () => _navigateToPage('profit_loss'),
            ),
            _buildMenuItem(
              icon: Icons.file_copy,
              title: AppStrings.profile.taxReports,
              subtitle: AppStrings.profile.taxReportsSubtitle,
              onTap: () => _navigateToPage('tax_reports'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // System & Settings Section
        _buildSimpleMenuSection(
          title: AppStrings.profile.systemAndSettings,
          items: [
            _buildMenuItem(
              icon: Icons.print,
              title: AppStrings.profile.printerSettings,
              subtitle: AppStrings.profile.printerSettingsSubtitle,
              onTap: () => _showPrinterSettingsDialog(),
            ),
            _buildMenuItem(
              icon: Icons.payment,
              title: AppStrings.profile.paymentMethods,
              subtitle: AppStrings.profile.paymentMethodsSubtitle,
              onTap: () => _navigateToPage('payment_settings'),
            ),
            _buildMenuItem(
              icon: Icons.percent,
              title: AppStrings.profile.taxConfiguration,
              subtitle: AppStrings.profile.taxConfigurationSubtitle,
              onTap: () => _navigateToPage('tax_config'),
            ),
            _buildMenuItem(
              icon: Icons.backup,
              title: AppStrings.profile.dataBackup,
              subtitle: AppStrings.profile.dataBackupSubtitle,
              onTap: () => _navigateToPage('backup'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Help & Support Section
        _buildSimpleMenuSection(
          title: AppStrings.profile.helpAndSupport,
          items: [
            _buildMenuItem(
              icon: Icons.book,
              title: AppStrings.profile.userManual,
              subtitle: AppStrings.profile.userManualSubtitle,
              onTap: () => _navigateToPage('user_manual'),
            ),
            _buildMenuItem(
              icon: Icons.support_agent,
              title: AppStrings.profile.technicalSupport,
              subtitle: AppStrings.profile.technicalSupportSubtitle,
              onTap: () => _navigateToPage('support'),
            ),
            _buildMenuItem(
              icon: Icons.system_update,
              title: AppStrings.profile.appUpdates,
              subtitle: AppStrings.profile.appUpdatesSubtitle,
              onTap: () => _navigateToPage('updates'),
            ),
            _buildMenuItem(
              icon: Icons.info,
              title: AppStrings.profile.aboutApp,
              subtitle: AppStrings.profile.aboutAppSubtitle,
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
            color: Colors.black.withValues(alpha: 0.05),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            AppVersionService.displayVersion,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
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
    if (!mounted) return;
    final navProvider = context.read<NavigationProvider>();
    navProvider.navigateToIndex(4);
  }

  void _showEditProfileDialog() async {
    await _triggerHapticFeedback();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  void _showPrinterSettingsDialog() async {
    await _triggerHapticFeedback();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => const PrinterSettingsDialog(),
    );
  }

  void _showCashManagementDialog() async {
    await _triggerHapticFeedback();
    if (!mounted) return;
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
            title: const Row(
              children: [
                Icon(Icons.logout, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(AppStrings.signOut),
              ],
            ),
            content: const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.cancel),
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
                child: const Text(AppStrings.signOut),
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
            (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppStrings.profile.signingOut),
                ],
              ),
            ),
      );

      // Logout from AuthProvider (this returns Future<void>)
      await context.read<AuthProvider>().logout();

      if (!mounted) return;

      // FIX: ProfileProvider logout returns void, so DON'T use await
      try {
        context.read<ProfileProvider>().logout(); // Remove 'await' here
      } catch (e) {
        // ProfileProvider might not have logout method, continue anyway
        debugPrint('ProfileProvider logout error: $e');
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
        AppSnackBar.showError(
          context,
          'Logout failed: ${e.toString()}',
          duration: const Duration(seconds: 3),
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
                  child: const Text(AppStrings.gotIt),
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
            title: Text(AppStrings.profile.aboutTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.profile.aboutDescription),
                const SizedBox(height: 8),
                Text(AppStrings.profile.version),
                Text(AppStrings.profile.build),
                const SizedBox(height: 16),
                const Text(
                  'A comprehensive restaurant management solution for modern dining experiences.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('© 2026 WhizEats Pro. All rights reserved.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
    );
  }
}
