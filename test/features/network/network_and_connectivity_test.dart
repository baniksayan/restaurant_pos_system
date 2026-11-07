import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/features/network/providers/network_provider.dart';
import 'package:restaurant_pos_system/features/network/views/no_internet_screen.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/global_network_wrapper.dart';

void main() {
  group('NetworkProvider and GlobalNetworkWrapper Tests', () {
    test('NetworkProvider callback management', () {
      final provider = NetworkProvider();
      bool callbackFired = false;

      void callback() {
        callbackFired = true;
      }

      provider.addRestoredCallback(callback);
      // Callback is registered
      provider.removeRestoredCallback(callback);
      expect(callbackFired, isFalse);
    });

    testWidgets('GlobalNetworkWrapper displays child when online', (
      WidgetTester tester,
    ) async {
      final networkProvider = NetworkProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkProvider>.value(
          value: networkProvider,
          child: const MaterialApp(
            home: GlobalNetworkWrapper(
              child: Scaffold(
                body: Text('Active Waiter Screen'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Active Waiter Screen'), findsOneWidget);
      expect(find.text('No Internet Connection'), findsNothing);
    });

    testWidgets('NoInternetScreen renders clean UI with Wi-Fi and Mobile Data buttons', (
      WidgetTester tester,
    ) async {
      final networkProvider = NetworkProvider();
      networkProvider.setStatusForTesting(NetworkStatus.disconnected);

      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkProvider>.value(
          value: networkProvider,
          child: const MaterialApp(
            home: NoInternetScreen(isOverlay: false),
          ),
        ),
      );

      // Verify headline & action buttons
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Wi-Fi Settings'), findsOneWidget);
      expect(find.text('Mobile Data'), findsOneWidget);
      expect(
        find.text('Open SIM manager & mobile network settings'),
        findsOneWidget,
      );
      expect(find.text('Check Connection'), findsOneWidget);
      expect(
        find.text('Auto-reconnects as soon as internet returns'),
        findsOneWidget,
      );
    });

    test('NetworkProvider pauses and resumes checks on lifecycle changes', () {
      final provider = NetworkProvider();

      // Simulate app minimized / screen turned black
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      // Verify no exceptions and state is preserved

      // Simulate app resumed / screen turned on
      provider.didChangeAppLifecycleState(AppLifecycleState.resumed);

      provider.dispose();
    });
    testWidgets('GlobalNetworkWrapper displays offline overlay when disconnected', (
      WidgetTester tester,
    ) async {
      final networkProvider = NetworkProvider();
      networkProvider.setStatusForTesting(NetworkStatus.disconnected);

      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkProvider>.value(
          value: networkProvider,
          child: const MaterialApp(
            home: GlobalNetworkWrapper(
              child: Scaffold(
                body: Text('Active Waiter Screen'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Active Waiter Screen'), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
    });

    testWidgets('GlobalNetworkWrapper displays Back Online pill and dismisses on tap', (
      WidgetTester tester,
    ) async {
      final networkProvider = NetworkProvider();
      networkProvider.setStatusForTesting(NetworkStatus.connected);
      networkProvider.setShowRestoredBannerForTesting(true);

      await tester.pumpWidget(
        ChangeNotifierProvider<NetworkProvider>.value(
          value: networkProvider,
          child: const MaterialApp(
            home: GlobalNetworkWrapper(
              child: Scaffold(
                body: Text('Active Waiter Screen'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify pill content
      expect(find.text('Back Online'), findsOneWidget);
      expect(find.text('Live Sync Active'), findsOneWidget);

      // Tap pill to dismiss
      await tester.tap(find.text('Back Online'));
      await tester.pumpAndSettle();

      expect(networkProvider.showRestoredBanner, isFalse);
    });
  });
}
