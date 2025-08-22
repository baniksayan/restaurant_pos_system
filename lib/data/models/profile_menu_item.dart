import 'package:flutter/material.dart';

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });
}
