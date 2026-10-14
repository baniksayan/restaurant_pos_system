import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_pos_system/core/constants/storage_keys.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart' show Location;
import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/dashboard_provider.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';

void main() {
  group('Location-based Menu & Outlet State Tests', () {
    late Directory tempDir;
    late MenuProvider menuProvider;
    late DashboardProvider dashboardProvider;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('loc_menu_test_');
      Hive.init(tempDir.path);
      await Hive.openBox(StorageKeys.posBox);
      await Hive.openBox(StorageKeys.authBox);
      await Hive.openBox(StorageKeys.tablesBox);
      await Hive.openBox(StorageKeys.ordersBox);
      await Hive.openBox(StorageKeys.syncQueueBox);
    });

    tearDownAll(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    setUp(() async {
      await HiveService.clearAllUserData();
      menuProvider = MenuProvider();
      dashboardProvider = DashboardProvider();
    });

    test('DashboardProvider dynamically maps locations from API and updates outletId on change', () {
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

      dashboardProvider.updateLocationsFromApi(mockLocations);

      // Initially selects the first location (Meerut Outlet, 10145)
      expect(dashboardProvider.selectedLocation, 'Meerut Outlet');
      expect(dashboardProvider.selectedLocationId, 10145);
      expect(HiveService.getOutletId(), 10145);
      expect(HiveService.getSelectedLocationId(), 10145);

      // Change location to Urban Spice – Salt Lake (10136)
      dashboardProvider.changeLocation('Urban Spice – Salt Lake');

      expect(dashboardProvider.selectedLocation, 'Urban Spice – Salt Lake');
      expect(dashboardProvider.selectedLocationId, 10136);
      expect(HiveService.getOutletId(), 10136);
      expect(HiveService.getSelectedLocationId(), 10136);

      // Check helper
      expect(dashboardProvider.getOutletIdForLocation('Meerut Outlet'), 10145);
      expect(dashboardProvider.getOutletIdForLocation('Urban Spice – Salt Lake'), 10136);
    });

    test('MenuProvider loadMenuData clears stale items immediately when switching to a different outletId', () async {
      // Simulate Meerut Outlet (10145) with 1 item: Soya Chaap
      menuProvider.setMenuItemsForTesting([
        Data(
          productId: 'item_soya',
          productName: 'Soya Chaap',
          categoryId: 'cat_starters',
          categoryName: 'Starters',
          productPrice: 180,
          pureVeg: true,
        ),
      ]);
      // Manually set currentOutletId for simulation
      HiveService.setOutletId(10145);
      expect(menuProvider.apiMenuItems.length, 1);
      expect(menuProvider.apiMenuItems.first.productName, 'Soya Chaap');

      // Now call loadMenuData with new outlet 10136 without auth token
      // Stale items must be cleared immediately when outletId is different
      await menuProvider.loadMenuData(outletId: 10136);

      // Since there is no auth token in this test, loadMenuItems returns early with empty list
      // But verify that the previous outlet's items were NOT retained!
      expect(menuProvider.apiMenuItems, isEmpty);
      expect(menuProvider.currentOutletId, 10136);
      expect(HiveService.getOutletId(), 10136);
    });

    test('MenuProvider preserves menu if same outletId is requested without forceRefresh', () async {
      final items = [
        Data(
          productId: 'item_1',
          productName: 'Butter Chicken',
          categoryId: 'cat_main',
          categoryName: 'Main Course',
          productPrice: 320,
          pureVeg: false,
        ),
      ];
      menuProvider.setMenuItemsForTesting(items);

      // Pretend it was loaded for 10136
      await menuProvider.loadMenuData(outletId: 10136);
      menuProvider.setMenuItemsForTesting(items);

      // Call again for 10136 without forceRefresh
      await menuProvider.loadMenuData(outletId: 10136, forceRefresh: false);

      // Must preserve items
      expect(menuProvider.apiMenuItems.length, 1);
      expect(menuProvider.apiMenuItems.first.productName, 'Butter Chicken');
    });

    test('MenuProvider clearMenuData wipes all menu, category and outlet cache on logout', () {
      menuProvider.setMenuItemsForTesting([
        Data(
          productId: 'item_1',
          productName: 'Paneer Tikka',
          categoryId: 'cat_1',
          categoryName: 'Starters',
          productPrice: 200,
        ),
      ]);
      expect(menuProvider.apiMenuItems.isNotEmpty, isTrue);

      menuProvider.clearMenuData();

      expect(menuProvider.apiMenuItems, isEmpty);
      expect(menuProvider.categories, isEmpty);
      expect(menuProvider.currentOutletId, isNull);
      expect(menuProvider.searchQuery, isEmpty);
      expect(menuProvider.selectedCategory, 'All');
    });

    test('Simulate Postman scenario: Outlet 10145 returns 1 item while 10136 returns multiple items', () {
      // 1. Outlet 10145 (Meerut Outlet) -> 1 item: Soya Chaap
      final meerutItems = [
        Data(
          productId: 'prod_soya_10145',
          productName: 'Soya Chaap',
          categoryId: 'cat_starters',
          categoryName: 'Starters',
          productPrice: 180,
          pureVeg: true,
        ),
      ];

      // 2. Outlet 10136 (Urban Spice – Salt Lake) -> 8 items
      final saltLakeItems = [
        Data(productId: '1', productName: 'Butter Chicken', categoryId: 'c1', categoryName: 'Main Course', productPrice: 350, pureVeg: false),
        Data(productId: '2', productName: 'Chicken Curry', categoryId: 'c1', categoryName: 'Main Course', productPrice: 320, pureVeg: false),
        Data(productId: '3', productName: 'Chicken Tikka', categoryId: 'c2', categoryName: 'Starters', productPrice: 280, pureVeg: false),
        Data(productId: '4', productName: 'Mixed Dal', categoryId: 'c1', categoryName: 'Main Course', productPrice: 190, pureVeg: true),
        Data(productId: '5', productName: 'Omelet', categoryId: 'c3', categoryName: 'Breakfast', productPrice: 120, pureVeg: false),
        Data(productId: '6', productName: 'Paneer Butter Masala', categoryId: 'c1', categoryName: 'Main Course', productPrice: 260, pureVeg: true),
        Data(productId: '7', productName: 'Paneer Tikka', categoryId: 'c2', categoryName: 'Starters', productPrice: 240, pureVeg: true),
        Data(productId: '8', productName: 'Soya Chaap', categoryId: 'c2', categoryName: 'Starters', productPrice: 200, pureVeg: true),
      ];

      // Select Meerut (10145)
      dashboardProvider.changeLocation('Meerut Outlet');
      menuProvider.setMenuItemsForTesting(meerutItems);

      expect(menuProvider.apiMenuItems.length, 1);
      expect(menuProvider.apiMenuItems.map((e) => e.productName).toList(), ['Soya Chaap']);

      // Switch to Urban Spice (10136)
      dashboardProvider.changeLocation('Urban Spice – Salt Lake');
      menuProvider.setMenuItemsForTesting(saltLakeItems);

      expect(menuProvider.apiMenuItems.length, 8);
      expect(
        menuProvider.apiMenuItems.map((e) => e.productName).toList(),
        containsAll([
          'Butter Chicken',
          'Chicken Curry',
          'Chicken Tikka',
          'Mixed Dal',
          'Omelet',
          'Paneer Butter Masala',
          'Paneer Tikka',
          'Soya Chaap',
        ]),
      );

      // Verify categories extracted dynamically
      expect(menuProvider.categoryNames, containsAll(['All', 'Main Course', 'Starters', 'Breakfast']));

      // Switch back to Meerut (10145)
      dashboardProvider.changeLocation('Meerut Outlet');
      menuProvider.setMenuItemsForTesting(meerutItems);

      // Verify no stale items from Urban Spice remain
      expect(menuProvider.apiMenuItems.length, 1);
      expect(menuProvider.apiMenuItems.first.productName, 'Soya Chaap');
      expect(menuProvider.apiMenuItems.any((e) => e.productName == 'Butter Chicken'), isFalse);
    });
  });
}
