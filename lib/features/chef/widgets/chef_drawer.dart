import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_assets.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_gradients.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/features/auth/providers/auth_provider.dart';
import 'package:restaurant_pos_system/features/chef/providers/chef_provider.dart';
import 'package:restaurant_pos_system/features/profile/views/profile_view.dart';
import 'package:restaurant_pos_system/shared/widgets/overlays/hourglass_loading_overlay.dart';
import 'package:restaurant_pos_system/shared/widgets/dialogs/sign_out_confirmation_dialog.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/shared/widgets/feedback/app_version_label.dart';

class ChefDrawer extends StatelessWidget {
  const ChefDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final chefProvider = context.watch<ChefProvider>();
    final locations = chefProvider.locations.isNotEmpty
        ? chefProvider.locations
        : ChefProvider.mapApiLocationsToSections(HiveService.getLocations());

    if (chefProvider.locations.isEmpty && locations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<ChefProvider>().loadLocationsFromHive();
        }
      });
    }

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 300,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Glassmorphic Drawer Header with active location
                  _buildDrawerHeader(chefProvider),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Locations
                          if (locations.isNotEmpty) ...[
                            _buildSectionHeader(
                              'LOCATIONS',
                              Icons.storefront_rounded,
                            ),
                            const SizedBox(height: 8),
                            ...locations.map((loc) {
                              final isSelected =
                                  chefProvider.selectedLocation == loc.name;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _buildLocationNavTile(
                                  title: loc.name,
                                  subtitle: (loc.address != null &&
                                          loc.address!.trim().isNotEmpty)
                                      ? loc.address!.trim()
                                      : (loc.type ?? 'Outlet'),
                                  icon: loc.icon,
                                  color: loc.color,
                                  isSelected: isSelected,
                                  onTap: () async {
                                    if (!isSelected) {
                                      HapticHelper.triggerFeedback();
                                      await chefProvider.changeLocation(
                                        loc.name,
                                        outletId: loc.id,
                                      );
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],

                          // Section: Navigation & Account
                          _buildSectionHeader(
                            'KITCHEN MENU',
                            Icons.grid_view_rounded,
                          ),
                          const SizedBox(height: 8),

                          // Option: Chef Profile
                          _buildCleanNavTile(
                            title: AppStrings.chef.chefProfile,
                            subtitle: AppStrings.chef.chefProfileSubtitle,
                            icon: Icons.person_outline_rounded,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileView(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // App Version Label (Just Above Sign Out Button)
                  const AppVersionLabel(),
                  const SizedBox(height: 6),

                  // Dedicated Sign Out Button Fixed at Bottom
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(ChefProvider chefProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppAssets.logoTransparent,
                fit: BoxFit.contain,
                errorBuilder:
                    (ctx, err, stack) => const Icon(
                      Icons.soup_kitchen_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'WhizEats KDS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  chefProvider.selectedLocation.isNotEmpty
                      ? chefProvider.selectedLocation
                      : 'Kitchen Display System',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 18,
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _confirmLogout(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                      Text(
                        'Exit Kitchen Display System',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    SignOutConfirmationDialog.show(
      context,
      message: AppStrings.signOutKdsConfirm,
      onConfirm: () => _performLogout(context),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => const HourglassLoadingOverlay(
        message: AppStrings.signingOutOfKds,
      ),
    );

    try {
      context.read<ChefProvider>().reset();
      await authProvider.logout();
      await HiveService.clearChefSession();
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Logout error in chef drawer: $e');
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      rootNavigator.pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }
}

