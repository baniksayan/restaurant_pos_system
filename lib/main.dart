import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/network_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/profile_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/reservation_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/tax_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/billing_provider.dart';
import 'package:restaurant_pos_system/presentation/views/auth/login/login_view.dart';
import 'package:restaurant_pos_system/presentation/views/main_navigation.dart';
import 'package:restaurant_pos_system/presentation/views/auth/splash/splash_view.dart';
import 'core/themes/app_theme.dart';
import 'data/local/hive_service.dart';
import 'presentation/view_models/providers/auth_provider.dart';
import 'presentation/view_models/providers/order_provider.dart';
import 'presentation/view_models/providers/menu_provider.dart';
import 'presentation/view_models/providers/table_provider.dart';
import 'presentation/view_models/providers/cart_provider.dart';
import 'services/sync_service.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/navigation_provider.dart';
import 'package:flutter/foundation.dart';

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
        
        // Modified TableProvider initialization - no immediate API call
        ChangeNotifierProvider(
          create: (_) {
            final provider = TableProvider();
            // Don't call initializeTables() here - will be called later
            return provider;
          },
        ),
        
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
            title: 'WiZARD Restaurant POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            
            // Always start with splash screen first
            initialRoute: '/',
            
            // Set up proper routing
            routes: {
              '/': (context) => const SplashScreen(), // Checks auth and routes accordingly
              '/login': (context) => const LoginView(),
              '/dashboard': (context) => const MainNavigation(),
            },
            
            // Handle unknown routes
            onUnknownRoute: (settings) {
              return MaterialPageRoute(builder: (context) => const LoginView());
            },
            
            // Global navigation key for programmatic navigation
            navigatorKey: GlobalKey<NavigatorState>(),
          );
        },
      ),
    );
  }
}

// Enhanced SplashScreen with proper initialization sequence
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = true;
  String _initializationStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Show splash screen for minimum time for animation completion
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        setState(() {
          _initializationStatus = 'Loading configurations...';
        });
      }

      // Initialize providers in sequence to avoid API overload
      await _initializeProviders();
      
      // Additional delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        // Check authentication state using AuthProvider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuthenticated = await authProvider.checkAuthState();
        
        if (isAuthenticated) {
          // User is logged in, go to main navigation using named route
          if (kDebugMode) {
            debugPrint('User authenticated - navigating to dashboard');
          }
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          // User is not logged in, go to login page using named route
          if (kDebugMode) {
            debugPrint('User not authenticated - navigating to login');
          }
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          debugPrint('App initialization error: $e');
        }

        // Even if initialization fails, continue to app
        // Check local storage directly as fallback
        final authToken = HiveService.getAuthToken();
        final targetRoute = (authToken != null && authToken.isNotEmpty) 
            ? '/dashboard' 
            : '/login';
        
        Navigator.of(context).pushReplacementNamed(targetRoute);
      }
    }
  }

  // Updated _initializeProviders method
  Future<void> _initializeProviders() async {
    try {
      if (mounted) {
        setState(() {
          _initializationStatus = 'Loading configurations...';
        });
      }

      // Initialize tax provider first
      final taxProvider = Provider.of<TaxProvider>(context, listen: false);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Try table initialization but DON'T block app launch if it fails
      if (mounted) {
        setState(() {
          _initializationStatus = 'Loading table data...';
        });
      }

      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      // Try once, but don't block the app if it fails
      try {
        await tableProvider.fetchTables();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Table initialization failed during splash: $e');
          debugPrint('Will retry after app loads...');
        }
        // Continue with app launch - tables will retry later
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _initializationStatus = 'Ready to go...';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Provider initialization error: $e');
      }
      // Don't throw error, let app continue
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashView(); // Animated splash screen
  }
}

// Global route generator for more complex routing needs
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _createRoute(const SplashScreen());
      case '/login':
        return _createRoute(const LoginView());
      case '/dashboard':
        return _createRoute(const MainNavigation());
      default:
        // Handle unknown routes - redirect to login
        return _createRoute(
          const Scaffold(
            body: Center(
              child: Text('Page not found')
            )
          ),
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

        return SlideTransition(
          position: animation.drive(tween), 
          child: child
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
}

// Extension for easy navigation throughout the app
extension NavigationExtension on BuildContext {
  Future<void> navigateToLogin() async {
    await Navigator.of(this).pushNamedAndRemoveUntil(
      '/login', 
      (Route<dynamic> route) => false
    );
  }

  Future<void> navigateToDashboard() async {
    await Navigator.of(this).pushNamedAndRemoveUntil(
      '/dashboard', 
      (Route<dynamic> route) => false
    );
  }

  Future<void> navigateToSplash() async {
    await Navigator.of(this).pushNamedAndRemoveUntil(
      '/', 
      (Route<dynamic> route) => false
    );
  }
}
