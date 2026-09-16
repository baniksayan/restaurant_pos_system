import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/features/auth/providers/auth_provider.dart';

/// Read-only — nothing here is editable. The app has no "update profile"
/// endpoint, so an edit control would only ever change what's shown
/// locally without saving anywhere, which is worse than no edit at all.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // The login response (User/authenticate) already carries the real
        // profile — first/last name, phone, email — cached in Hive. Prefer
        // that over guessing a name from the login email's local part.
        final userDetails = HiveService.getAuthData()?.data?.userDetails;
        final realName =
            [
              userDetails?.firstName,
              userDetails?.lastName,
            ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');

        String displayName = 'Manager';
        if (realName.isNotEmpty) {
          displayName = realName;
        } else if (authProvider.currentUser != null) {
          final email = authProvider.currentUser!;
          if (email.contains('@')) {
            // Extract name part before @ and capitalize
            displayName = email.split('@')[0];
            displayName = displayName
                .split('.')
                .map(
                  (part) =>
                      part.isNotEmpty
                          ? part.toUpperCase() + part.substring(1)
                          : part,
                )
                .join(' ');
          } else {
            displayName = authProvider.currentUser!;
          }
        }

        final email = userDetails?.email ?? authProvider.currentUser ?? '';
        final phone = userDetails?.phone ?? '';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.userRole ?? 'Restaurant Manager',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailLine(icon: Icons.mail_outline_rounded, text: email),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      _DetailLine(icon: Icons.phone_outlined, text: phone),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
