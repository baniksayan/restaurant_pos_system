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
import 'package:restaurant_pos_system/presentation/views/auth/splash/splash_view.dart'; // Adding this import
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
            // 48,
            // ); // Replacing 48 which is actual companyId
          });

          return MaterialApp(
            title: 'WiZARD Restaurant POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            // Always start with SplashScreen - this is the key change
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// Create a new SplashScreen widget that handles navigation logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show splash screen for minimum 3 seconds (for animation completion)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Check if user is already logged in
      final authToken = HiveService.getAuthToken();

      if (authToken != null && authToken.isNotEmpty) {
        // User is logged in, go to main navigation
        Navigator.of(
          context,
        ).pushReplacement(_createRoute(const MainNavigation()));
      } else {
        // User is not logged in, go to login page
        Navigator.of(context).pushReplacement(_createRoute(const LoginView()));
      }
    }
  }

  // Create smooth page transition
  Route _createRoute(Widget page) {
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

  @override
  Widget build(BuildContext context) {
    return const SplashView(); // Your animated splash screen
  }
}
