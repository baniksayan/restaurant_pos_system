import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/profile_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/reservation_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/tax_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/billing_provider.dart';
import 'package:restaurant_pos_system/presentation/views/auth/login/login_view.dart';
import 'package:restaurant_pos_system/presentation/views/main_navigation.dart';
import 'app/app.dart';
import 'core/themes/app_theme.dart';
import 'data/local/hive_service.dart';
import 'presentation/view_models/providers/auth_provider.dart';
import 'presentation/view_models/providers/order_provider.dart';
import 'presentation/view_models/providers/menu_provider.dart';
import 'presentation/view_models/providers/table_provider.dart';
import 'presentation/view_models/providers/cart_provider.dart';
import 'services/sync_service.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/navigation_provider.dart';

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
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = TableProvider();
            provider.initializeTables(); // Initialize tables on app start
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AnimatedCartProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => TaxProvider()),
        ChangeNotifierProvider(
          create: (_) => BillingProvider(),
        ), // Added BillingProvider
      ],
      child: Builder(
        builder: (context) {
          // Initialize tax data after providers are available
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final taxProvider = Provider.of<TaxProvider>(
              context,
              listen: false,
            );
            // await taxProvider.initializeTaxData(
            //   48,
            // ); // Replacing 48 which is actual companyId
          });

          return MaterialApp(
            title: 'WiZARD Restaurant POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home:
                HiveService.getAuthToken() != ""
                    ? MainNavigation()
                    : const LoginView(),
          );
        },
      ),
    );
  }
}
