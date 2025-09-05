import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/presentation/views/auth/login/login_view.dart';
import 'package:restaurant_pos_system/presentation/views/auth/splash/splash_view.dart';
import 'package:restaurant_pos_system/presentation/views/main_navigation.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _createRoute(const SplashView());
      case '/login':
        return _createRoute(const LoginView());
      case '/dashboard':
        return _createRoute(const MainNavigation());
      default:
        // Handle unknown routes - redirect to login
        return _createRoute(
          const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }

  // Create smooth page transition
  static Route<dynamic> _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
}
