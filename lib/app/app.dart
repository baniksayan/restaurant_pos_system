import 'package:flutter/material.dart';
import '../presentation/views/auth/splash/splash_view.dart';

class POSApp extends StatefulWidget {
  const POSApp({super.key});

  @override
  State<POSApp> createState() => _POSAppState();
}

class _POSAppState extends State<POSApp> {
  // This file is now optional since we handle splash in main.dart
  // You can keep it for future modular app structures
  
  @override
  Widget build(BuildContext context) {
    return const SplashView(); // Simply return splash view
  }
}
