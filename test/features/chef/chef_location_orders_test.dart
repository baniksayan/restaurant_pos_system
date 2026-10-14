import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/storage_keys.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart' show Location;
import 'package:restaurant_pos_system/features/chef/models/chef_order_model.dart';
import 'package:restaurant_pos_system/features/chef/providers/chef_provider.dart';
import 'package:restaurant_pos_system/features/chef/widgets/chef_drawer.dart';
import 'package:restaurant_pos_system/features/chef/widgets/chef_location_header.dart';
import 'package:restaurant_pos_system/features/chef/widgets/chef_order_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KDS Location & Incoming Orders Tests', () {
    late Directory tempDir;
    late ChefProvider chefProvider;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('kds_loc_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(StorageKeys.posBox);
      await Hive.openBox(StorageKeys.authBox);
      await Hive.openBox(StorageKeys.tablesBox);
      await Hive.openBox(StorageKeys.ordersBox);
      await Hive.openBox(StorageKeys.syncQueueBox);
    });

    tearDownAll(() async {
      try {
        await Hive.close();
      } catch (_) {}
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    setUp(() async {
      await HiveService.clearAllUserData();
      chefProvider = ChefProvider(
        autoStartPolling: false,
        autoFetch: false,
      );
    });



    test('ChefProvider dynamically loads multiple locations from Hive and sets active outlet', () async {
      final mockLocations = [
        Location(
          locationId: 10145,
          locationName: 'Meerut Outlet',
          locationType: 'Outlet',
          locAddress: 'Begum Bridge',
        ),
        Location(
          locationId: 10136,
          locationName: 'Urban Spice – Salt Lake',
          locationType: 'Outlet',
          locAddress: 'Sector V',
        ),
      ];

      await chefProvider.updateLocationsFromApi(mockLocations);

      expect(chefProvider.locations.length, 2);
      expect(chefProvider.selectedLocation, 'Meerut Outlet');
      expect(chefProvider.selectedLocationId, 10145);
      expect(HiveService.getOutletId(), 10145);
      expect(HiveService.getSelectedLocationName(), 'Meerut Outlet');
    });

    test('ChefProvider.changeLocation switches outletId, updates Hive, and clears previous orders', () async {
      final mockLocations = [
        Location(
          locationId: 10145,
          locationName: 'Meerut Outlet',
          locationType: 'Outlet',
          locAddress: 'Begum Bridge',
        ),
        Location(
          locationId: 10136,
          locationName: 'Urban Spice – Salt Lake',
          locationType: 'Outlet',
          locAddress: 'Sector V',
        ),
      ];

      await chefProvider.updateLocationsFromApi(mockLocations);
      expect(chefProvider.selectedLocation, 'Meerut Outlet');

      // Switch to Urban Spice – Salt Lake
      await chefProvider.changeLocation(
        'Urban Spice – Salt Lake',
        outletId: 10136,
        fetchNewOrders: false,
      );

      expect(chefProvider.selectedLocation, 'Urban Spice – Salt Lake');
      expect(chefProvider.selectedLocationId, 10136);
      expect(HiveService.getOutletId(), 10136);
      expect(HiveService.getSelectedLocationName(), 'Urban Spice – Salt Lake');
    });

    test('ChefOrder model stores outletId and outletName with copyWith integrity', () {
      final order = ChefOrder(
        id: 'kot-101',
        kotNo: 'KOT-001',
        orderNumber: 'ORD-999',
        tableNumber: 'Table 4',
        orderTime: DateTime(2026, 10, 14, 12, 0),
        outletId: 10145,
        outletName: 'Meerut Outlet',
        items: [
          ChefOrderItem(
            id: 'item-1',
            name: 'Soya Chaap',
            quantity: 2,
            price: 180.0,
          ),
        ],
        status: ChefOrderStatus.pending,
      );

      expect(order.outletId, 10145);
      expect(order.outletName, 'Meerut Outlet');

      final copied = order.copyWith(
        outletId: 10136,
        outletName: 'Urban Spice – Salt Lake',
      );

      expect(copied.outletId, 10136);
      expect(copied.outletName, 'Urban Spice – Salt Lake');
      expect(copied.items.length, 1);
      expect(copied.items.first.name, 'Soya Chaap');
    });

    test('ChefProvider.reset() cleans orders, locations and resets filter', () async {
      final mockLocations = [
        Location(
          locationId: 10145,
          locationName: 'Meerut Outlet',
          locationType: 'Outlet',
        ),
      ];
      await chefProvider.updateLocationsFromApi(mockLocations);
      chefProvider.changeStatusFilter('Preparing');

      expect(chefProvider.locations.isNotEmpty, true);
      expect(chefProvider.selectedStatusFilter, 'Preparing');

      chefProvider.reset();

      expect(chefProvider.orders, isEmpty);
      expect(chefProvider.locations, isEmpty);
      expect(chefProvider.selectedLocation, '');
      expect(chefProvider.selectedLocationId, isNull);
      expect(chefProvider.selectedStatusFilter, 'All Statuses');
    });

    testWidgets('ChefLocationHeader displays active outlet name and live stats', (tester) async {
      final mockLocations = [
        Location(
          locationId: 10145,
          locationName: 'Meerut Outlet',
          locationType: 'Outlet',
        ),
        Location(
          locationId: 10136,
          locationName: 'Urban Spice – Salt Lake',
          locationType: 'Outlet',
        ),
      ];

      await tester.runAsync(() async {
        await chefProvider.updateLocationsFromApi(mockLocations);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ChefProvider>.value(
            value: chefProvider,
            child: const Scaffold(
              body: ChefLocationHeader(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Meerut Outlet'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsWidgets);
    });

    testWidgets('ChefOrderCard displays outlet pill when order has outletName', (tester) async {
      final order = ChefOrder(
        id: 'kot-202',
        kotNo: 'KOT-202',
        orderNumber: 'ORD-202',
        tableNumber: 'Table 7',
        orderTime: DateTime.now(),
        outletId: 10136,
        outletName: 'Urban Spice – Salt Lake',
        items: [
          ChefOrderItem(
            id: 'item-2',
            name: 'Butter Chicken',
            quantity: 1,
            price: 320.0,
          ),
        ],
        status: ChefOrderStatus.pending,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ChefProvider>.value(
            value: chefProvider,
            child: Scaffold(
              body: ChefOrderCard(order: order),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TABLE 7'), findsOneWidget);
      expect(find.text('Urban Spice – Salt Lake'), findsOneWidget);
      expect(find.text('Butter Chicken'), findsOneWidget);
      expect(find.text('ACCEPT ORDER'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    test('ChefProvider persists tab index and status filter to Hive and restores on loadFromHive', () async {
      final mockLocations = [
        Location(
          locationId: 10145,
          locationName: 'Meerut Outlet',
          locationType: 'Outlet',
        ),
        Location(
          locationId: 10136,
          locationName: 'Urban Spice – Salt Lake',
          locationType: 'Outlet',
        ),
      ];

      await chefProvider.updateLocationsFromApi(mockLocations);
      await chefProvider.changeLocation('Urban Spice – Salt Lake', outletId: 10136, fetchNewOrders: false);
      chefProvider.changeTabIndex(2);
      chefProvider.changeStatusFilter('Preparing');

      expect(HiveService.getKdsSelectedTabIndex(), 2);
      expect(HiveService.getKdsSelectedStatusFilter(), 'Preparing');
      expect(HiveService.getOutletId(), 10136);
      expect(HiveService.getSelectedLocationName(), 'Urban Spice – Salt Lake');

      // Create a brand new ChefProvider simulating app restart
      final restartedChefProvider = ChefProvider(
        autoStartPolling: false,
        autoFetch: false,
      );

      // Hydrate state from Hive
      restartedChefProvider.loadFromHive();

      expect(restartedChefProvider.currentTabIndex, 2);
      expect(restartedChefProvider.selectedStatusFilter, 'Preparing');
      expect(restartedChefProvider.selectedLocationId, 10136);
      expect(restartedChefProvider.selectedLocation, 'Urban Spice – Salt Lake');
      expect(restartedChefProvider.locations.length, 2);
    });

    testWidgets('ChefDrawer displays all locations and allows switching location dynamically', (tester) async {
      final mockLocations = [
        Location(
          locationId: 10145,
          locationName: 'Meerut Outlet',
          locationType: 'Outlet',
          locAddress: 'Begum Bridge',
        ),
        Location(
          locationId: 10136,
          locationName: 'Urban Spice – Salt Lake',
          locationType: 'Outlet',
          locAddress: 'Sector V',
        ),
      ];

      await tester.runAsync(() async {
        await HiveService.clearAllUserData();
        chefProvider = ChefProvider(
          autoStartPolling: false,
          autoFetch: false,
        );
        await chefProvider.updateLocationsFromApi(mockLocations);
      });

      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ChefProvider>.value(
            value: chefProvider,
            child: Scaffold(
              key: scaffoldKey,
              drawer: const ChefDrawer(),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => scaffoldKey.currentState?.openDrawer(),
                  child: const Text('OPEN DRAWER'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('OPEN DRAWER'));
      await tester.pumpAndSettle();

      // Check that Drawer displays LOCATIONS section header
      expect(find.text('LOCATIONS'), findsOneWidget);
      // Meerut Outlet is active: shows in header + tile
      expect(find.text('Meerut Outlet'), findsNWidgets(2));
      // Urban Spice – Salt Lake is unselected: shows in tile only
      expect(find.text('Urban Spice – Salt Lake'), findsOneWidget);

      // Tap on Urban Spice – Salt Lake tile inside runAsync for real async I/O
      await tester.runAsync(() async {
        await tester.tap(find.text('Urban Spice – Salt Lake'));
        // Allow the async changeLocation future to complete
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      // Verify that provider switched to Urban Spice – Salt Lake
      expect(chefProvider.selectedLocationId, 10136);
      expect(chefProvider.selectedLocation, 'Urban Spice – Salt Lake');
      expect(HiveService.getOutletId(), 10136);
      expect(HiveService.getSelectedLocationName(), 'Urban Spice – Salt Lake');

      await tester.pumpWidget(const SizedBox());
    });

    test('HiveService.clearAllUserData cleans KDS tab index and status filter', () async {
      await HiveService.setKdsSelectedTabIndex(3);
      await HiveService.setKdsSelectedStatusFilter('Ready');

      expect(HiveService.getKdsSelectedTabIndex(), 3);
      expect(HiveService.getKdsSelectedStatusFilter(), 'Ready');

      await HiveService.clearAllUserData();

      expect(HiveService.getKdsSelectedTabIndex(), isNull);
      expect(HiveService.getKdsSelectedStatusFilter(), isNull);
    });
  });
}
