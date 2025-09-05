import 'package:flutter/material.dart';

extension NavigationExtension on BuildContext {
  Future<void> navigateToLogin() async {
    await Navigator.of(
      this,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  Future<void> navigateToDashboard() async {
    await Navigator.of(
      this,
    ).pushNamedAndRemoveUntil('/dashboard', (Route<dynamic> route) => false);
  }

  Future<void> navigateToSplash() async {
    await Navigator.of(
      this,
    ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }
}
