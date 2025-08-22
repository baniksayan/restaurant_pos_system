import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/navigation_provider.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/printer_settings_dialog.dart';
import '../widgets/cash_management_dialog.dart';

class ProfileDialogService {
  static void showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EditProfileDialog(),
    );
  }

  static void showPrinterSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PrinterSettingsDialog(),
    );
  }

  static void showCashManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CashManagementDialog(),
    );
  }

  static void showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  static void showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('About WiZARD POS'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WiZARD Restaurant Management System'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 2025.08.21'),
            SizedBox(height: 16),
            Text(
              'A comprehensive restaurant management solution for modern dining experiences.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text('© 2025 WiZARD Solutions'),
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

  static void navigateToReports(BuildContext context) {
    final navProvider = context.read<NavigationProvider>();
    navProvider.navigateToIndex(4); // Navigate to Reports tab
  }

  static void navigateToPage(BuildContext context, String pageName) {
    switch (pageName) {
      case 'restaurant_details':
        showComingSoonDialog(context, 'Restaurant Details');
        break;
      case 'staff_management':
        showComingSoonDialog(context, 'Staff Management');
        break;
      case 'table_config':
        showComingSoonDialog(context, 'Table Configuration');
        break;
      case 'menu_management':
        showComingSoonDialog(context, 'Menu Management');
        break;
      case 'performance':
        showComingSoonDialog(context, 'Performance Metrics');
        break;
      case 'inventory_reports':
        showComingSoonDialog(context, 'Inventory Reports');
        break;
      case 'customer_analytics':
        showComingSoonDialog(context, 'Customer Analytics');
        break;
      case 'expenses':
        showComingSoonDialog(context, 'Expense Tracking');
        break;
      case 'profit_loss':
        showComingSoonDialog(context, 'Profit & Loss');
        break;
      case 'tax_reports':
        showComingSoonDialog(context, 'Tax Reports');
        break;
      case 'payment_settings':
        showComingSoonDialog(context, 'Payment Settings');
        break;
      case 'tax_config':
        showComingSoonDialog(context, 'Tax Configuration');
        break;
      case 'backup':
        showComingSoonDialog(context, 'Data Backup');
        break;
      case 'user_manual':
        showComingSoonDialog(context, 'User Manual');
        break;
      case 'support':
        showComingSoonDialog(context, 'Technical Support');
        break;
      case 'updates':
        showComingSoonDialog(context, 'App Updates');
        break;
      case 'about':
        showAboutDialog(context);
        break;
    }
  }
}
