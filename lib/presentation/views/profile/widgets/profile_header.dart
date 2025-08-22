// lib/presentation/views/profile/widgets/profile_header.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/auth_provider.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback? onEditPressed;
  
  const ProfileHeader({super.key, this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Extract name from email or use fallback
        String displayName = 'Manager';
        if (authProvider.currentUser != null) {
          final email = authProvider.currentUser!;
          if (email.contains('@')) {
            // Extract name part before @ and capitalize
            displayName = email.split('@')[0];
            displayName = displayName.split('.').map((part) => 
              part.isNotEmpty ? part.toUpperCase() + part.substring(1) : part
            ).join(' ');
          } else {
            displayName = authProvider.currentUser!;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
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
                      color: Colors.black.withOpacity(0.1),
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: onEditPressed,
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Edit Profile',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
