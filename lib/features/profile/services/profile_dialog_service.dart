import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/printer_settings_dialog.dart';
import '../widgets/cash_management_dialog.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

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
                    color: Colors.blue.withValues(alpha: 0.1),
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
                  child: const Text(AppStrings.gotIt),
                ),
              ],
            ),
          ),
    );
  }

  static void showAboutDialog(BuildContext context) {
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
