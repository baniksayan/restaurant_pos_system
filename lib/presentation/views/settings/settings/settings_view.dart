import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey[50],
        child: const Center(
          child: Text(
            'Settings Coming Soon',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}