import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/core/constants/storage_keys.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/features/billing/providers/billing_provider.dart';
import 'package:restaurant_pos_system/features/billing/providers/tax_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/dashboard_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/views/waiter_dashboard_view.dart';
import 'package:restaurant_pos_system/features/dashboard/widgets/dashboard_states.dart';
import 'package:restaurant_pos_system/features/dashboard/widgets/table_grid.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/orders/providers/ready_to_collect_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Initial Load and Location Switch Shimmer Tests', () {
    late Directory tempDir;
    late TableProvider tableProvider;
    late DashboardProvider dashboardProvider;
    late NavigationProvider navProvider;
    late OrderProvider orderProvider;
    late BillingProvider billingProvider;
    late TaxProvider taxProvider;
    late MenuProvider menuProvider;
    late AnimatedCartProvider animatedCartProvider;
    late ReadyToCollectProvider readyProvider;

    setUpAll(() async {
      CurrencyConstants.setSymbol('₹');
      tempDir = Directory.systemTemp.createTempSync('table_shimmer_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(StorageKeys.posBox);
      await Hive.openBox(StorageKeys.authBox);
      await Hive.openBox(StorageKeys.tablesBox);
      await Hive.openBox(StorageKeys.ordersBox);
      await Hive.openBox(StorageKeys.syncQueueBox);
      HiveService.saveTaxData({
        'companyId': 18,
        'outletId': 10145,
        'isSuccess': true,
        'message': 'Success',
        'data': [
          {'taxId': 1, 'taxName': 'GST', 'taxPercentage': 5.0}
        ],
      });
    });

    setUp(() {
      tableProvider = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: ({required token, required outletId, locationName}) async => [],
        authTokenGetter: () => 'test-token',
        outletIdGetter: () => 10145,
      );
      dashboardProvider = DashboardProvider();
      navProvider = NavigationProvider();
      orderProvider = OrderProvider();
      billingProvider = BillingProvider();
      taxProvider = TaxProvider();
      menuProvider = MenuProvider();
      animatedCartProvider = AnimatedCartProvider();
      readyProvider = ReadyToCollectProvider();
    });

    tearDown(() {
      tableProvider.stopPolling();
    });


    testWidgets('Initial app open shows DashboardLoadingState skeleton, NEVER DashboardEmptyState', (
      WidgetTester tester,
    ) async {
      // Create tableProvider with a pending fetch that does not resolve immediately
      final loadingCompleter = Completer<List<RestaurantTable>>();
      final initialLoadingProvider = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: ({required token, required outletId, locationName}) =>
            loadingCompleter.future,
        authTokenGetter: () => 'test-token',
        outletIdGetter: () => 10145,
      );

      // At creation, tableProvider has no tables and has not completed initial fetch
      expect(initialLoadingProvider.hasCompletedInitialFetch, isFalse);
      expect(initialLoadingProvider.tables.isEmpty, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: initialLoadingProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<BillingProvider>.value(value: billingProvider),
            ChangeNotifierProvider<TaxProvider>.value(value: taxProvider),
            ChangeNotifierProvider<MenuProvider>.value(value: menuProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: animatedCartProvider),
            ChangeNotifierProvider<ReadyToCollectProvider>.value(value: readyProvider),
          ],
          child: const MaterialApp(home: WaiterDashboardView()),
        ),
      );
      await tester.pump();

      // Must show DashboardLoadingState (skeleton shimmer)
      expect(find.byType(DashboardLoadingState), findsOneWidget);
      expect(find.byType(TableGridSkeleton), findsOneWidget);

      // Must NEVER show DashboardEmptyState on initial open!
      expect(find.byType(DashboardEmptyState), findsNothing);
      expect(find.text('No tables found'), findsNothing);

      // Complete fetch to cleanly close pending future
      loadingCompleter.complete([]);
      await tester.pump();
      initialLoadingProvider.stopPolling();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Switching location shows TableGridSkeleton shimmer, NEVER DashboardEmptyState', (
      WidgetTester tester,
    ) async {
      const table1 = RestaurantTable(
        id: 'table-1',
        name: 'Table 1',
        capacity: 4,
        location: 'Location A',
        locationId: 1,
        status: TableStatus.available,
        kotGenerated: false,
        billGenerated: false,
      );

      final locationBCompleter = Completer<List<RestaurantTable>>();
      final switchProvider = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: ({required token, required outletId, locationName}) async {
          if (outletId == 1 || locationName == 'Location A') {
            return [table1];
          }
          return locationBCompleter.future;
        },
        authTokenGetter: () => 'test-token',
        outletIdGetter: () => 1,
      );

      dashboardProvider.changeLocation('Location A');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: switchProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<BillingProvider>.value(value: billingProvider),
            ChangeNotifierProvider<TaxProvider>.value(value: taxProvider),
            ChangeNotifierProvider<MenuProvider>.value(value: menuProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: animatedCartProvider),
            ChangeNotifierProvider<ReadyToCollectProvider>.value(value: readyProvider),
          ],
          child: const MaterialApp(home: WaiterDashboardView()),
        ),
      );
      await tester.pump();

      // Real TableGrid is visible for Location A
      expect(find.byType(TableGrid), findsOneWidget);
      expect(find.text('Table 1'), findsOneWidget);
      expect(find.byType(DashboardEmptyState), findsNothing);
      expect(find.byType(TableGridSkeleton), findsNothing);

      // 2. Now user switches location to Location B
      // switchLocation immediately clears tables and enters isLoading = true
      dashboardProvider.changeLocation('Location B');
      switchProvider.switchLocation(location: 'Location B', outletId: 2);

      await tester.pump();

      // In transit: must show TableGridSkeleton shimmer
      expect(switchProvider.isLoading, isTrue);
      expect(find.byType(TableGridSkeleton), findsOneWidget);

      // Must NEVER show DashboardEmptyState while switching location!
      expect(find.byType(DashboardEmptyState), findsNothing);
      expect(find.text('No tables found'), findsNothing);

      locationBCompleter.complete([]);
      await tester.pump();
      switchProvider.stopPolling();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('DashboardEmptyState ONLY displays when fetch completes and outlet truly has 0 tables', (
      WidgetTester tester,
    ) async {
      // Create tableProvider with mock fetch that returns 0 tables
      final emptyProvider = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: ({required token, required outletId, locationName}) async => [],
        authTokenGetter: () => 'test-token',
        outletIdGetter: () => 999,
      );

      // Perform fetch: returns empty list
      await emptyProvider.fetchTablesWithAuth('test-token', 999, 'Empty Branch', false);

      expect(emptyProvider.isLoading, isFalse);
      expect(emptyProvider.hasCompletedInitialFetch, isTrue);
      expect(emptyProvider.tables.isEmpty, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: emptyProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<BillingProvider>.value(value: billingProvider),
            ChangeNotifierProvider<TaxProvider>.value(value: taxProvider),
            ChangeNotifierProvider<MenuProvider>.value(value: menuProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: animatedCartProvider),
            ChangeNotifierProvider<ReadyToCollectProvider>.value(value: readyProvider),
          ],
          child: const MaterialApp(home: WaiterDashboardView()),
        ),
      );
      await tester.pump();

      // Now and ONLY now that loading is complete with 0 tables: empty state is shown
      expect(find.byType(DashboardEmptyState), findsOneWidget);
      expect(find.byType(TableGridSkeleton), findsNothing);
      emptyProvider.stopPolling();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('TableGridSkeleton fits inside tight constraints without any RenderFlex overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 163.5,
                height: 123.0,
                child: TableGridSkeleton.buildTableCardSkeleton(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify no exceptions were thrown and skeleton renders
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
