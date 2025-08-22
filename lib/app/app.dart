import 'package:flutter/material.dart';
import '../presentation/views/auth/login/login_view.dart';
import '../presentation/views/auth/splash/splash_view.dart';

class POSApp extends StatefulWidget {
  const POSApp({super.key});

  @override
  State<POSApp> createState() => _POSAppState();
}

class _POSAppState extends State<POSApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashView();
    } else {
      return const LoginView();
    }
  }
}
