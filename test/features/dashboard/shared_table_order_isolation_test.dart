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
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/widgets/multi_order_management_dialog.dart';
import 'package:restaurant_pos_system/features/menu/providers/menu_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/order_provider.dart';
import 'package:restaurant_pos_system/features/order_taking/views/cart_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Table Multi-Party Isolation (Team A vs Team B)', () {
    late Directory tempDir;
    late TableProvider tableProvider;
    late AnimatedCartProvider cartProvider;
    late NavigationProvider navProvider;
    late OrderProvider orderProvider;
    late BillingProvider billingProvider;
    late TaxProvider taxProvider;
    late MenuProvider menuProvider;

    const String sharedTableId = 'table-shared-8-uuid';
    const String teamAOrderId = 'aaaa1111-0000-0000-0000-000000000001';
    const String teamBOrderId = 'bbbb2222-0000-0000-0000-000000000002';
    const String teamBBillId = 'bill-bbbb-0000-0000-000000000002';

    setUpAll(() async {
      CurrencyConstants.setSymbol('₹');
      tempDir = Directory.systemTemp.createTempSync('shared_table_isolation_');
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

    setUp(() {
      tableProvider = TableProvider();
      cartProvider = AnimatedCartProvider();
      navProvider = NavigationProvider();
      orderProvider = OrderProvider();
      billingProvider = BillingProvider();
      taxProvider = TaxProvider();
      menuProvider = MenuProvider();
    });

    RestaurantTable buildSharedTable({
      bool teamBBilled = true,
    }) {
      return RestaurantTable(
        id: sharedTableId,
        name: 'Table 8',
        capacity: 8,
        location: 'Urban Spice - Salt Lake',
        // Table-level summary reflects that SOME order on the table (Team B)
        // has a bill generated, even though Team A is still unbilled.
        status: teamBBilled ? TableStatus.billGenerated : TableStatus.kotGenerated,
        kotGenerated: true,
        billGenerated: teamBBilled,
        activeOrders: [
          const ActiveOrder(
            orderId: teamAOrderId,
            generatedOrderNo: 'OD/UR/261126/0001',
            orderStatus: 'In Progress',
            isBilled: false,
            isKotCreated: true,
            kotNumber: 'KT/UR/0001',
            totalAdult: 2,
          ),
          ActiveOrder(
            orderId: teamBOrderId,
            generatedOrderNo: 'OD/UR/261126/0002',
            orderStatus: teamBBilled ? 'Bill Generated' : 'In Progress',
            isBilled: teamBBilled,
            billId: teamBBilled ? teamBBillId : null,
            isKotCreated: true,
            kotNumber: 'KT/UR/0002',
            totalAdult: 3,
          ),
        ],
      );
    }

    Widget wrapWithProviders(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
          ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
          ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ChangeNotifierProvider<BillingProvider>.value(value: billingProvider),
          ChangeNotifierProvider<TaxProvider>.value(value: taxProvider),
          ChangeNotifierProvider<MenuProvider>.value(value: menuProvider),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      'Opening Cart for unbilled Team A while Team B on the same table is partially paid MUST NOT show Bill Generated / Proceed to Payment',
      (WidgetTester tester) async {
        // Seed table with Team A (KOT only) + Team B (Bill Generated, Partially Paid)
        final sharedTable = buildSharedTable(teamBBilled: true);
        tableProvider.tables.add(sharedTable);

        await tester.runAsync(() async {
          await HiveService.clearAllData();
          await HiveService.saveOrderBillId(teamBOrderId, teamBBillId);
          tableProvider.storeBillId(teamBOrderId, teamBBillId);
          cartProvider.markOrderBilled(teamBOrderId);

          // Seed Team B's items (Tea & Coffee) then switch to Team A's items (Butter Chicken)
          cartProvider.importFromOrderCart(
            [
              {
                'productId': 'prod-tea',
                'productName': 'Masala Tea',
                'quantity': 2,
                'price': 250.0,
                'isKotGenerated': true,
                'kotNo': 'KT/UR/0002',
              },
            ],
            orderId: teamBOrderId,
            tableId: sharedTableId,
            tableName: 'Table 8',
            clearExisting: true,
          );

          // Now waiter taps Open Cart on Team A!
          tableProvider.setCurrentOrder(teamAOrderId);
          cartProvider.importFromOrderCart(
            [
              {
                'productId': 'prod-butter-chicken',
                'productName': 'Butter Chicken',
                'quantity': 1,
                'price': 450.0,
                'isKotGenerated': true,
                'kotNo': 'KT/UR/0001',
              },
            ],
            orderId: teamAOrderId,
            tableId: sharedTableId,
            tableName: 'Table 8',
            clearExisting: true,
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        await tester.pumpWidget(
          wrapWithProviders(
            const CartView(
              tableId: sharedTableId,
              tableName: 'Table 8',
              selectedLocation: 'Urban Spice - Salt Lake',
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        // CRITICAL: Team A is NOT billed — must show Team A's item & Generate Bill,
        // NOT "Bill Generated · Payment Pending" / "Proceed to Payment" from Team B!
        expect(find.text('Butter Chicken'), findsOneWidget);
        expect(find.text('Masala Tea'), findsNothing);
        expect(find.text('Bill Generated · Payment Pending'), findsNothing);
        expect(find.text('Bill Generated • Payment Pending'), findsNothing);
        expect(find.text('Proceed to Payment'), findsNothing);
        expect(find.text('Generate Bill'), findsOneWidget);
        expect(find.text('Send to Kitchen'), findsOneWidget);

        // Now switch to Team B on the exact same table (same tableId!) and pump
        tableProvider.setCurrentOrder(teamBOrderId);
        await tester.runAsync(() async {
          cartProvider.switchToOrder(
            teamBOrderId,
            tableId: sharedTableId,
            tableName: 'Table 8',
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
        await tester.pump();

        // Team B IS billed — Team B shows Payment Pending / Proceed to Payment & Masala Tea
        expect(find.text('Masala Tea'), findsOneWidget);
        expect(find.text('Butter Chicken'), findsNothing);
        expect(find.text('Bill Generated · Payment Pending'), findsOneWidget);
        expect(find.text('Bill Generated • Payment Pending'), findsOneWidget);
        expect(find.text('Proceed to Payment'), findsOneWidget);
        expect(find.text('Generate Bill'), findsNothing);

        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await HiveService.clearAllData();
        });
      },
    );

    testWidgets(
      'MultiOrderManagementDialog keeps Team A (KOT Generated) and Team B (Partially Paid ₹200/₹500) independent and opens Cart tab for Team A',
      (WidgetTester tester) async {
        final sharedTable = buildSharedTable(teamBBilled: true);
        tableProvider.tables.add(sharedTable);

        const teamADynamic = OrderDynamicInfo(
          orderId: teamAOrderId,
          orderNumber: 'OD/UR/261126/0001',
          customerName: 'Team A',
          totalGuests: 2,
          itemCount: 2,
          totalAmount: 450.0,
          paidAmount: 0.0,
          balanceAmount: 450.0,
          isBilled: false,
          paymentStatus: OrderPaymentStatus.pending,
          kitchenStatus: OrderKitchenStatus.inKitchen,
          kitchenStatusText: 'In Progress',
          isLoaded: true,
        );

        const teamBDynamic = OrderDynamicInfo(
          orderId: teamBOrderId,
          orderNumber: 'OD/UR/261126/0002',
          customerName: 'Team B',
          totalGuests: 3,
          itemCount: 2,
          totalAmount: 500.0,
          paidAmount: 200.0,
          balanceAmount: 300.0,
          billId: teamBBillId,
          isBilled: true,
          paymentStatus: OrderPaymentStatus.partiallyPaid,
          kitchenStatus: OrderKitchenStatus.delivered,
          kitchenStatusText: 'Bill Generated',
          isLoaded: true,
        );

        await tester.pumpWidget(
          wrapWithProviders(
            Scaffold(
              body: MultiOrderManagementDialog(
                table: sharedTable,
                enableDynamicFetch: false,
                initialDynamicData: const {
                  teamAOrderId: teamADynamic,
                  teamBOrderId: teamBDynamic,
                },
              ),
            ),
          ),
        );
        await tester.pump();

        // Both orders render on their own cards with independent states
        expect(find.text('OD/UR/261126/0001'), findsOneWidget);
        expect(find.text('KOT Generated'), findsOneWidget);
        expect(find.text('Open Cart'), findsOneWidget);

        expect(find.text('OD/UR/261126/0002'), findsOneWidget);
        expect(find.text('Bill Generated'), findsOneWidget);
        expect(find.text('Partially Paid'), findsOneWidget);
        expect(find.text('Please pay ₹300.00 to complete the bill.'), findsOneWidget);
        expect(find.text('Collect ₹300.00'), findsOneWidget);

        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await HiveService.clearAllData();
        });
      },
    );

    test(
      'Adding items to Team A and Team B on the same table keeps carts isolated regardless of order or UUID casing',
      () async {
        await HiveService.clearAllData();

        // Team A adds Butter Chicken
        cartProvider.addItem(
          'prod-1',
          'Butter Chicken',
          350.0,
          sharedTableId,
          'Table 8',
          orderId: teamAOrderId,
        );
        expect(cartProvider.cartItems.length, equals(1));

        // Team B arrives on the same table and adds Tea & Coffee
        cartProvider.addItem(
          'prod-2',
          'Tea',
          100.0,
          sharedTableId,
          'Table 8',
          orderId: teamBOrderId,
        );
        cartProvider.addItem(
          'prod-3',
          'Coffee',
          150.0,
          sharedTableId,
          'Table 8',
          orderId: teamBOrderId,
        );
        expect(cartProvider.cartItems.length, equals(2));
        expect(cartProvider.totalAmount, equals(250.0));

        // Mark Team B billed (upper-case UUID test too)
        cartProvider.markOrderBilled(teamBOrderId.toUpperCase());
        expect(cartProvider.isOrderBilled(teamBOrderId), isTrue);
        expect(cartProvider.isOrderBilled(teamAOrderId), isFalse);

        // Switch back to Team A — Team A's Butter Chicken is intact and unaffected
        cartProvider.switchToOrder(
          teamAOrderId.toUpperCase(),
          tableId: sharedTableId,
          tableName: 'Table 8',
        );
        expect(cartProvider.cartItems.length, equals(1));
        expect(cartProvider.cartItems.values.first.name, equals('Butter Chicken'));
        expect(cartProvider.isOrderBilled(cartProvider.currentOrderId), isFalse);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await HiveService.clearAllData();
      },
    );

    test(
      'TableProvider.markOrderBilled and markOrderSettled only affect the target party and preserve sibling orders on the shared table',
      () async {
        await HiveService.clearAllData();
        final sharedTable = buildSharedTable(teamBBilled: false);
        tableProvider.tables.add(sharedTable);

        // Team B generates bill -> ONLY Team B becomes billed
        tableProvider.markOrderBilled(teamBOrderId, billId: teamBBillId);
        final afterBBilled = tableProvider.tables.first;
        final orderA = afterBBilled.activeOrders
            .firstWhere((o) => o.orderId == teamAOrderId);
        final orderB = afterBBilled.activeOrders
            .firstWhere((o) => o.orderId == teamBOrderId);
        expect(orderA.isBilled, isFalse);
        expect(orderA.billId, isNull);
        expect(orderB.isBilled, isTrue);
        expect(orderB.billId, equals(teamBBillId));

        // Team B finishes paying in full -> ONLY Team B leaves; Team A stays KOT Generated!
        await tableProvider.markOrderSettled(teamBOrderId);
        final afterBSettled = tableProvider.tables.first;
        expect(afterBSettled.activeOrders.length, equals(1));
        expect(afterBSettled.activeOrders.first.orderId, equals(teamAOrderId));
        expect(afterBSettled.status, equals(TableStatus.kotGenerated));
        expect(afterBSettled.billGenerated, isFalse);
      },
    );

    test(
      'NavigationProvider.selectTableAndNavigateToCart jumps directly to Cart tab (index 2)',
      () {
        navProvider.selectTableAndNavigateToCart(
          sharedTableId,
          'Table 8',
          'Urban Spice - Salt Lake',
        );
        expect(navProvider.selectedTableId, equals(sharedTableId));
        expect(navProvider.selectedTableName, equals('Table 8'));
        expect(navProvider.currentIndex, equals(2));
      },
    );

    test(
      'BillingProvider.getBillIdForOrder returns null instead of leaking another order billId',
      () {
        // Without generating a bill for Team A, getBillIdForOrder(teamAOrderId) is null
        expect(billingProvider.getBillIdForOrder(teamAOrderId), isNull);
        expect(billingProvider.getBillIdForOrder(teamBOrderId), isNull);
      },
    );
  });
}
