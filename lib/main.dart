import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/app_version_service.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive_service.dart';
import 'data/local/sync_service.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_view.dart';
import 'features/billing/providers/billing_provider.dart';
import 'features/billing/providers/tax_provider.dart';
import 'features/chef/providers/chef_provider.dart';
import 'features/chef/views/chef_dashboard_view.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/providers/navigation_provider.dart';
import 'features/dashboard/providers/table_provider.dart';
import 'features/dashboard/views/main_navigation.dart';
import 'features/menu/providers/menu_provider.dart';
import 'features/network/providers/network_provider.dart';
import 'features/order_taking/providers/animated_cart_provider.dart';
import 'features/order_taking/providers/order_provider.dart';
import 'features/orders/providers/orders_management_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/reservations/providers/reservation_provider.dart';
import 'features/splash/views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set global status bar style (app-wide)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive for offline storage
  await HiveService.init();

  // Initialize App Version from pubspec package info
  await AppVersionService.init();

  // Schedule end-of-day sync for offline data
  SyncService.scheduleEndOfDaySync();

  runApp(const RestaurantPOSApp());
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChefProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => OrdersManagementProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AnimatedCartProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => TaxProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()..initialize()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'WhizEats Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashView(),
              '/login': (context) => const LoginView(),
              '/dashboard': (context) => const MainNavigation(),
              '/chef': (context) => const ChefDashboardView(),
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(builder: (context) => const LoginView());
            },
            navigatorKey: GlobalKey<NavigatorState>(),
          );
        },
      ),
    );
  }
}
