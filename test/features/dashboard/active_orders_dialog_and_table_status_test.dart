import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/currency_constants.dart';
import 'package:restaurant_pos_system/data/models/bill_details_response.dart';
import 'package:restaurant_pos_system/data/models/pending_bill.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/navigation_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/providers/table_provider.dart';
import 'package:restaurant_pos_system/features/dashboard/widgets/multi_order_management_dialog.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/shimmer_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Active Orders Dialog and Table Status Tests', () {
    late TableProvider tableProvider;
    late AnimatedCartProvider cartProvider;
    late NavigationProvider navProvider;

    setUpAll(() {
      CurrencyConstants.setSymbol('₹');
    });

    setUp(() {
      tableProvider = TableProvider();
      cartProvider = AnimatedCartProvider();
      navProvider = NavigationProvider();
    });

    test('OrderDynamicInfo properties correctly identify payment status', () {
      const paidInFullOrder = OrderDynamicInfo(
        orderId: 'order-1',
        orderNumber: 'ORD/001',
        customerName: 'Rahul',
        totalGuests: 2,
        itemCount: 3,
        totalAmount: 500.0,
        paidAmount: 500.0,
        balanceAmount: 0.0,
        isBilled: true,
        paymentStatus: OrderPaymentStatus.paidInFull,
        kitchenStatus: OrderKitchenStatus.delivered,
        kitchenStatusText: 'Delivered / Served',
        isLoaded: true,
      );

      const partiallyPaidOrder = OrderDynamicInfo(
        orderId: 'order-2',
        orderNumber: 'ORD/002',
        customerName: 'Amit',
        totalGuests: 4,
        itemCount: 5,
        totalAmount: 1000.0,
        paidAmount: 400.0,
        balanceAmount: 600.0,
        isBilled: true,
        paymentStatus: OrderPaymentStatus.partiallyPaid,
        kitchenStatus: OrderKitchenStatus.readyForDelivery,
        kitchenStatusText: 'Ready for Delivery',
        isLoaded: true,
      );

      const pendingOrder = OrderDynamicInfo(
        orderId: 'order-3',
        orderNumber: 'ORD/003',
        customerName: 'Guest',
        totalGuests: 1,
        itemCount: 2,
        totalAmount: 300.0,
        paidAmount: 0.0,
        balanceAmount: 300.0,
        isBilled: false,
        paymentStatus: OrderPaymentStatus.pending,
        kitchenStatus: OrderKitchenStatus.orderPlaced,
        kitchenStatusText: 'Order Placed',
        isLoaded: true,
      );

      // Verify Delete Button rules:
      // Paid in full -> Delete button MUST be displayed
      expect(paidInFullOrder.isPaidInFull, isTrue);
      final showDeletePaid = paidInFullOrder.isPaidInFull;
      expect(showDeletePaid, isTrue);

      // Partially paid -> Delete button must NOT be displayed
      expect(partiallyPaidOrder.isPartiallyPaid, isTrue);
      final showDeletePartial = partiallyPaidOrder.isPaidInFull;
      expect(showDeletePartial, isFalse);

      // Pending / Unpaid -> Delete button must NOT be displayed
      expect(pendingOrder.isPending, isTrue);
      final showDeletePending = pendingOrder.isPaidInFull;
      expect(showDeletePending, isFalse);
    });

    test('Table status update to available resets active orders', () {
      const tableId = 'test-table-1';
      const table = RestaurantTable(
        id: tableId,
        name: 'Table 7',
        capacity: 4,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.billGenerated,
        kotGenerated: true,
        billGenerated: true,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-1',
            generatedOrderNo: 'ORD/001',
            orderStatus: 'Bill Generated',
            isBilled: true,
          ),
        ],
      );

      // Inject table into provider
      tableProvider.tables.add(table);

      // Setting status to available should vacate the table
      tableProvider.updateTableStatus(tableId, 'available');

      final updatedTable = tableProvider.tables.firstWhere((t) => t.id == tableId);
      expect(updatedTable.status, equals(TableStatus.available));
      expect(updatedTable.activeOrders.isEmpty, isTrue);
      expect(updatedTable.kotGenerated, isFalse);
      expect(updatedTable.billGenerated, isFalse);
    });

    test('ActiveOrder hasKotGenerated accurately reflects kitchen progression', () {
      const orderPlaced = ActiveOrder(
        orderId: 'o-1',
        generatedOrderNo: 'ORD/1',
        orderStatus: 'Order Placed',
        isBilled: false,
      );
      expect(orderPlaced.hasKotGenerated, isFalse);

      const kotGen = ActiveOrder(
        orderId: 'o-2',
        generatedOrderNo: 'ORD/2',
        orderStatus: 'KOT Generated',
        isBilled: false,
      );
      expect(kotGen.hasKotGenerated, isTrue);

      const inKitchen = ActiveOrder(
        orderId: 'o-3',
        generatedOrderNo: 'ORD/3',
        orderStatus: 'In Kitchen',
        isBilled: false,
      );
      expect(inKitchen.hasKotGenerated, isTrue);

      const preparing = ActiveOrder(
        orderId: 'o-4',
        generatedOrderNo: 'ORD/4',
        orderStatus: 'Preparing',
        isBilled: false,
      );
      expect(preparing.hasKotGenerated, isTrue);

      const ready = ActiveOrder(
        orderId: 'o-5',
        generatedOrderNo: 'ORD/5',
        orderStatus: 'Ready for Delivery',
        isBilled: false,
      );
      expect(ready.hasKotGenerated, isTrue);

      const inProgress = ActiveOrder(
        orderId: 'o-6',
        generatedOrderNo: 'ORD/6',
        orderStatus: 'In Progress',
        isBilled: false,
      );
      expect(inProgress.hasKotGenerated, isTrue);
    });

    test('removeOrderFromTable and clearTable do not pretend local success when offline', () async {
      const tableId = 'test-table-2';
      const table = RestaurantTable(
        id: tableId,
        name: 'Table 2',
        capacity: 4,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-fail-1',
            generatedOrderNo: 'ORD/FAIL/1',
            orderStatus: 'Active',
            isBilled: false,
          ),
        ],
      );

      tableProvider.tables.add(table);

      // Attempting removal without internet should fail safely without local mutation
      final removeSuccess = await tableProvider.removeOrderFromTable(tableId, 'order-fail-1');
      expect(removeSuccess, isFalse);
      expect(tableProvider.error, isNotNull);

      // Table must retain its active order and not pretend it is available
      final intactTable = tableProvider.tables.firstWhere((t) => t.id == tableId);
      expect(intactTable.activeOrders.length, equals(1));
      expect(intactTable.status, equals(TableStatus.occupied));

      // Attempting clearTable without internet should also fail safely
      final clearSuccess = await tableProvider.clearTable(tableId);
      expect(clearSuccess, isFalse);
      expect(tableProvider.error, isNotNull);
      expect(intactTable.activeOrders.length, equals(1));
    });

    testWidgets('MultiOrderManagementDialog renders dynamic order badges and header', (WidgetTester tester) async {
      const table = RestaurantTable(
        id: 'table-7',
        name: 'Table 7',
        capacity: 4,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-101',
            generatedOrderNo: 'ORD/101',
            orderStatus: 'Order Placed',
            isBilled: false,
          ),
        ],
      );

      tableProvider.tables.add(table);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: table,
                enableDynamicFetch: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Header elements
      expect(find.text('Active Orders'), findsOneWidget);
      expect(find.text('Table 7'), findsNWidgets(2)); // Header pill + Awaiting Order card
      expect(find.byIcon(Icons.tune_rounded), findsNothing); // Filter button removed
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.text('Add New Order'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget); // Delete icon on card
    });

    test('Shared table clearing: vacating one order leaves remaining orders; vacating all sets table to available', () async {
      const sharedTableId = 'table-shared-8';
      const orderA = ActiveOrder(
        orderId: 'order-a',
        generatedOrderNo: 'ORD/A',
        orderStatus: 'Bill Generated',
        isBilled: true,
      );
      const orderB = ActiveOrder(
        orderId: 'order-b',
        generatedOrderNo: 'ORD/B',
        orderStatus: 'KOT Generated',
        isBilled: false,
      );

      const sharedTable = RestaurantTable(
        id: sharedTableId,
        name: 'Table 8',
        capacity: 6,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.billGenerated,
        kotGenerated: true,
        billGenerated: true,
        activeOrders: [orderA, orderB],
      );

      tableProvider.tables.add(sharedTable);

      // Verify initial state
      expect(tableProvider.tables.firstWhere((t) => t.id == sharedTableId).activeOrders.length, equals(2));

      // Settle Order A (paid in full / deleted from table)
      await tableProvider.markOrderSettled('order-a');

      final tableAfterA = tableProvider.tables.firstWhere((t) => t.id == sharedTableId);
      expect(tableAfterA.activeOrders.length, equals(1));
      expect(tableAfterA.activeOrders.first.orderId, equals('order-b'));
      // Table should still be active because Order B is still running
      expect(tableAfterA.status, equals(TableStatus.kotGenerated));
      expect(tableProvider.isOrderSettled('order-a'), isTrue);

      // Now settle Order B (paid in full / vacated)
      await tableProvider.markOrderSettled('order-b');

      final tableAfterB = tableProvider.tables.firstWhere((t) => t.id == sharedTableId);
      expect(tableAfterB.activeOrders.isEmpty, isTrue);
      expect(tableAfterB.status, equals(TableStatus.available));
      expect(tableProvider.isOrderSettled('order-b'), isTrue);
    });

    test('Reproducible test case: Table 2 with billAmountInclTax: 0 and billAmountExclTax: 600.0 resolves effective payable amount of 600.0', () {
      final billDetailsJson = {
        'data': {
          'companyDt': {'companyName': 'Urban Spice Restaurant'},
          'billHeadDt': {
            'billNo': 'BL/ME/26-27/00034',
            'billDate': '16/11/2026',
            'billCreatedBy': 'Kaushik Operator',
            'discountPerc': 0.0,
            'discountAmnt': 0.0,
            'specDisPer': 0.0,
            'specDisAmt': 0.0,
            'amountAfterDisc': 600.0,
            'billAmountExclTax': 600.0,
            'billAmountInclTax': 0,
            'customerName': '',
            'custMobNo': '',
            'returnToCustomer': 0,
            'outletAddress': 'Begum Bridge',
          },
          'orderChanelDt': [
            {'channelType': 'Table', 'channelName': 'Table 2'}
          ],
          'taxInf': [],
          'billOrderDt': [
            {
              'orderId': '66668efb-94e1-f111-8f4e-f0d7471a4ee1',
              'orderNo': 'OD/ME/161126/0014',
              'itemName': 'Soya Chaap',
              'orderQty': 1.0,
              'itemPrice': 400.0,
              'totalItemPrice': 400.0,
            },
            {
              'orderId': '66668efb-94e1-f111-8f4e-f0d7471a4ee1',
              'orderNo': 'OD/ME/161126/0014',
              'itemName': 'Paneer Tikka',
              'orderQty': 1.0,
              'itemPrice': 200.0,
              'totalItemPrice': 200.0,
            },
          ],
          'paymentDetail': [
            {
              'paymentMode': 'Cash',
              'paymentAmount': 600.0,
              'returnAmt': 0.0,
            }
          ],
        },
        'message': 'Data Fetched successful',
        'isSuccess': true,
        'statusCode': 200,
      };

      final dataMap = billDetailsJson['data'] as Map<String, dynamic>;
      final parsed = BillHeadDetails.fromJson(dataMap['billHeadDt'] as Map<String, dynamic>);
      expect(parsed.effectivePayableAmount, equals(600.0));

      final billData = BillDetailsData.fromJson(dataMap);
      expect(billData.totalPaidAmount, equals(600.0));
      expect(billData.isPaidInFull, isTrue);
    });

    test('PendingBill parses billAmountExclTax as total amount when billAmountInclTax is 0', () {
      final reprintBillJson = {
        'billId': '9b5cb97d-95e1-f111-8f4e-f0d7471a4ee1',
        'billNo': 'BL/ME/26-27/00034',
        'orderNo': 'OD/ME/161126/0014',
        'customerName': '',
        'billAmountExclTax': 600.0,
        'discountAmnt': 0.0,
        'specDisAmt': 0.0,
        'totalTax': 0,
        'billAmountInclTax': 0,
        'itemCount': 2,
        'paidAmount': 600.0,
        'isPaid': 2,
        'paymentStatus': 'Paid',
      };

      final pendingBill = PendingBill.fromJson(reprintBillJson);
      expect(pendingBill.amount, equals(600.0));
      expect(pendingBill.totalAmount, equals(600.0));
      expect(pendingBill.isFullyPaid, isTrue);
    });

    test('ActiveOrder handles newly created KOT with isKotCreated', () {
      const orderWithKot = ActiveOrder(
        orderId: '66668efb-94e1-f111-8f4e-f0d7471a4ee1',
        generatedOrderNo: 'OD/ME/161126/0014',
        orderStatus: 'Order Placed',
        isBilled: false,
        isKotCreated: true,
        kotNumber: 'KT/ME/161126/0010',
      );

      expect(orderWithKot.hasKotGenerated, isTrue);
      expect(orderWithKot.kotNumber, equals('KT/ME/161126/0010'));
    });

    testWidgets('Scenario 1: KOT Generated order renders KOT Generated badge, kitchen status, and Open Cart', (WidgetTester tester) async {
      const kotTable = RestaurantTable(
        id: 'table-kot-1',
        name: 'Table 1',
        capacity: 2,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-kot-1',
            generatedOrderNo: 'OD/UR/181125/0001',
            orderStatus: 'In Progress',
            isBilled: false,
            totalAdult: 1,
          ),
        ],
      );

      tableProvider.tables.add(kotTable);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: kotTable,
                enableDynamicFetch: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('OD/UR/181125/0001'), findsOneWidget);
      expect(find.text('KOT Generated'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('1 Guest'), findsOneWidget);
      expect(find.text('Open Cart'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      // Ensure no View KOT, View Bill, or generic Pending payment badge
      expect(find.text('View KOT'), findsNothing);
      expect(find.text('View Bill'), findsNothing);
      expect(find.text('Collect Payment'), findsNothing);
    });

    testWidgets('Scenario 2: Table Reserved – No Order Placed displays Reserved badge and Open Menu', (WidgetTester tester) async {
      final reservedTable = RestaurantTable(
        id: 'table-res-1',
        name: 'Table 1',
        capacity: 4,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.reserved,
        kotGenerated: false,
        billGenerated: false,
        reservationInfo: ReservationInfo(
          guestCount: 4,
          reservationDate: DateTime(2026, 11, 18),
          startTime: '1:58 PM',
          endTime: '3:00 PM',
          occasion: 'Dinner',
          totalAmount: 0.0,
          customerName: 'Sayan',
        ),
        activeOrders: const [],
      );

      tableProvider.tables.add(reservedTable);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: reservedTable,
                enableDynamicFetch: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Table 1'), findsNWidgets(2)); // Header badge + Card title
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Awaiting Order'), findsOneWidget);
      expect(find.text('4 Guests'), findsOneWidget);
      expect(find.text('Reserved At: 18 Nov, 1:58 PM'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Open Menu'), findsOneWidget);
      // Ensure no order id or item count
      expect(find.text('OD/'), findsNothing);
      expect(find.text('Open Cart'), findsNothing);
      expect(find.text('Collect Payment'), findsNothing);
    });

    testWidgets('Scenario 3: Bill Generated – Unpaid renders Bill Generated badge, Unpaid badge, 3-column summary and Collect Payment', (WidgetTester tester) async {
      const unpaidTable = RestaurantTable(
        id: 'table-unpaid-3',
        name: 'Table 3',
        capacity: 2,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.billGenerated,
        kotGenerated: true,
        billGenerated: true,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-unpaid-3',
            generatedOrderNo: 'OD/UR/181126/0003',
            orderStatus: 'Bill Generated',
            isBilled: true,
            totalAdult: 1,
          ),
        ],
      );

      tableProvider.tables.add(unpaidTable);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: unpaidTable,
                enableDynamicFetch: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('OD/UR/181126/0003'), findsOneWidget);
      expect(find.text('Bill Generated'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(find.text('Bill Amount'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
      expect(find.text('Collect Payment'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('View Bill'), findsNothing);
      expect(find.text('Delete Order'), findsNothing);
    });

    testWidgets('Scenario 4: Bill Generated – Partially Paid renders Partially Paid badge, 3-column breakdown, reminder banner and dynamic Collect CTA', (WidgetTester tester) async {
      const partialTable = RestaurantTable(
        id: 'table-partial-4',
        name: 'Table 4',
        capacity: 2,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.billGenerated,
        kotGenerated: true,
        billGenerated: true,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-partial-4',
            generatedOrderNo: 'OD/UR/181126/0004',
            orderStatus: 'Bill Generated',
            isBilled: true,
            totalAdult: 2,
          ),
        ],
      );

      tableProvider.tables.add(partialTable);

      const dynamicInfo = OrderDynamicInfo(
        orderId: 'order-partial-4',
        orderNumber: 'OD/UR/181126/0004',
        customerName: 'Guest',
        totalGuests: 2,
        itemCount: 3,
        totalAmount: 1200.0,
        paidAmount: 500.0,
        balanceAmount: 700.0,
        isBilled: true,
        paymentStatus: OrderPaymentStatus.partiallyPaid,
        kitchenStatus: OrderKitchenStatus.orderPlaced,
        kitchenStatusText: 'Bill Generated',
        isLoaded: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: partialTable,
                enableDynamicFetch: false,
                initialDynamicData: {
                  'order-partial-4': dynamicInfo,
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('OD/UR/181126/0004'), findsOneWidget);
      expect(find.text('Bill Generated'), findsOneWidget);
      expect(find.text('Partially Paid'), findsOneWidget);
      expect(find.text('Bill Amount'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      // Payment reminder banner
      expect(find.text('Please pay ₹700.00 to complete the bill.'), findsOneWidget);
      // Dynamic primary action button
      expect(find.text('Collect ₹700.00'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      // Verify secondary buttons do not exist
      expect(find.text('View Bill'), findsNothing);
      expect(find.text('Delete Order'), findsNothing);
    });

    testWidgets('Scenario 5: Bill Fully Paid renders Paid badge, Remaining, and Delete Order button', (WidgetTester tester) async {
      const paidTable = RestaurantTable(
        id: 'table-paid-5',
        name: 'Table 5',
        capacity: 2,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.billGenerated,
        kotGenerated: true,
        billGenerated: true,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-paid-5',
            generatedOrderNo: 'OD/UR/181126/0005',
            orderStatus: 'Bill Generated',
            isBilled: true,
            totalAdult: 2,
          ),
        ],
      );

      const paidDynamicInfo = OrderDynamicInfo(
        orderId: 'order-paid-5',
        orderNumber: 'OD/UR/181126/0005',
        customerName: 'Guest',
        totalGuests: 2,
        itemCount: 2,
        totalAmount: 600.0,
        paidAmount: 600.0,
        balanceAmount: 0.0,
        isBilled: true,
        paymentStatus: OrderPaymentStatus.paidInFull,
        kitchenStatus: OrderKitchenStatus.delivered,
        kitchenStatusText: 'Delivered',
        isLoaded: true,
      );

      tableProvider.tables.add(paidTable);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: paidTable,
                enableDynamicFetch: false,
                initialDynamicData: {
                  'order-paid-5': paidDynamicInfo,
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('OD/UR/181126/0005'), findsOneWidget);
      expect(find.text('Bill Generated'), findsOneWidget);
      expect(find.text('Paid'), findsNWidgets(2)); // Paid status badge + 3-col 'Paid' header
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Delete Order'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      // Verify payment collection buttons and reminder are NOT present
      expect(find.text('Collect Payment'), findsNothing);
      expect(find.text('View Bill'), findsNothing);
    });

    testWidgets('Newly created order on table renders as Awaiting Order with Open Menu, Reserved badge, and Delete action', (WidgetTester tester) async {
      const awaitingTable = RestaurantTable(
        id: 'table-new-6',
        name: 'Table 6',
        capacity: 4,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.occupied,
        kotGenerated: false,
        billGenerated: false,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-new-6',
            generatedOrderNo: 'OD/UR/181126/0006',
            orderStatus: 'Order Placed',
            isBilled: false,
            totalAdult: 4,
          ),
        ],
      );

      tableProvider.tables.add(awaitingTable);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: awaitingTable,
                enableDynamicFetch: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Table name on badge and card
      expect(find.text('Table 6'), findsNWidgets(2));
      expect(find.text('Reserved'), findsOneWidget);
      expect(find.text('Awaiting Order'), findsOneWidget);
      expect(find.text('4 Guests'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Open Menu'), findsOneWidget);
      // Delete icon button is present
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      // No KOT or Open Cart or 0.00
      expect(find.text('Open Cart'), findsNothing);
      expect(find.text('₹0.00'), findsNothing);

      // Tap delete icon to trigger confirmation dialog
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('Delete Order'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete order "OD/UR/181126/0006" from Table 6?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    test('markOrderDeleted dynamically removes order from in-memory table and marks table available when empty', () async {
      const tableId = 'table-del-9';
      const orderId = 'cf810bad-0b31-41c0-b3db-77ca97c0a774';
      const testTable = RestaurantTable(
        id: tableId,
        name: 'Table 9',
        capacity: 4,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.occupied,
        kotGenerated: false,
        billGenerated: false,
        activeOrders: [
          ActiveOrder(
            orderId: orderId,
            generatedOrderNo: 'OD/999',
            orderStatus: 'Order Placed',
            isBilled: false,
          ),
        ],
      );

      tableProvider.tables.add(testTable);
      expect(tableProvider.isOrderDeleted(orderId), isFalse);

      // Delete order using uppercase GUID to verify case-insensitivity
      await tableProvider.markOrderDeleted(orderId.toUpperCase());

      expect(tableProvider.isOrderDeleted(orderId), isTrue);
      expect(tableProvider.isOrderDeleted(orderId.toUpperCase()), isTrue);

      final updated = tableProvider.tables.firstWhere((t) => t.id == tableId);
      expect(updated.activeOrders.isEmpty, isTrue);
      expect(updated.status, equals(TableStatus.available));
      expect(updated.hasActiveOrders, isFalse);
    });

    testWidgets('MultiOrderManagementDialog displays skeleton with shimmer effect when dynamic loading is in progress', (WidgetTester tester) async {
      const testTable = RestaurantTable(
        id: 'table-shimmer-1',
        name: 'Table 1',
        capacity: 5,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-1',
            generatedOrderNo: 'OD/UR/261126/0001',
            orderStatus: 'In Progress',
            isBilled: false,
          ),
          ActiveOrder(
            orderId: 'order-2',
            generatedOrderNo: 'OD/UR/261126/0002',
            orderStatus: 'Bill Generated',
            isBilled: true,
          ),
        ],
      );

      tableProvider.tables.add(testTable);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: testTable,
                isLoading: true,
                enableDynamicFetch: false,
                enableShimmerAnimation: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Shimmer and ShimmerBone skeleton elements are actively rendered
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsWidgets);
      expect(find.byType(ShimmerBone), findsWidgets);

      // Real order text should not be rendered yet while in skeleton loading state
      expect(find.text('OD/UR/261126/0001'), findsNothing);
      expect(find.text('OD/UR/261126/0002'), findsNothing);
      expect(find.text('Open Cart'), findsNothing);
    });

    testWidgets('MultiOrderManagementDialog smoothly reveals real order cards once dynamic data finishes loading', (WidgetTester tester) async {
      const testTable = RestaurantTable(
        id: 'table-shimmer-2',
        name: 'Table 1',
        capacity: 5,
        location: 'Urban Spice - Salt Lake',
        status: TableStatus.occupied,
        kotGenerated: true,
        billGenerated: false,
        activeOrders: [
          ActiveOrder(
            orderId: 'order-1',
            generatedOrderNo: 'OD/UR/261126/0001',
            orderStatus: 'In Progress',
            isBilled: false,
          ),
        ],
      );

      tableProvider.tables.add(testTable);

      // Initially loading is true
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: testTable,
                isLoading: true,
                enableDynamicFetch: false,
                enableShimmerAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.text('OD/UR/261126/0001'), findsNothing);

      // Now dynamic data arrives: re-render with isLoading: false and loaded dynamic data
      const dynamicInfo = OrderDynamicInfo(
        orderId: 'order-1',
        orderNumber: 'OD/UR/261126/0001',
        customerName: 'Guest',
        totalGuests: 2,
        itemCount: 2,
        totalAmount: 749.50,
        paidAmount: 0.0,
        balanceAmount: 749.50,
        isBilled: false,
        paymentStatus: OrderPaymentStatus.pending,
        kitchenStatus: OrderKitchenStatus.inKitchen,
        kitchenStatusText: 'In Progress',
        isLoaded: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: tableProvider),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MultiOrderManagementDialog(
                table: testTable,
                isLoading: false,
                enableDynamicFetch: false,
                enableShimmerAnimation: false,
                initialDynamicData: {
                  'order-1': dynamicInfo,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Skeleton shimmer is gone, real order card and actions are rendered
      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('OD/UR/261126/0001'), findsOneWidget);
      expect(find.text('KOT Generated'), findsOneWidget);
      expect(find.text('Open Cart'), findsOneWidget);
      expect(find.text('₹749.50'), findsOneWidget);
    });

    test('Two-device sync: removeOrderFromTable never masks un-deleted server orders locally', () async {
      final serverOrders = <ActiveOrder>[
        const ActiveOrder(
          orderId: 'order-a-1',
          generatedOrderNo: 'OD/SYNC/0001',
          orderStatus: 'Ready For Delivery',
          isBilled: true,
        ),
        const ActiveOrder(
          orderId: 'order-b-2',
          generatedOrderNo: 'OD/SYNC/0002',
          orderStatus: 'In Progress',
          isBilled: false,
        ),
      ];

      Future<List<RestaurantTable>> sharedFetchTables({
        required String token,
        required int outletId,
        String? locationName,
      }) async {
        return [
          RestaurantTable(
            id: 'table-sync-1',
            name: 'Table 1',
            capacity: 6,
            location: 'Outlet',
            status: serverOrders.isEmpty
                ? TableStatus.available
                : TableStatus.occupied,
            kotGenerated: serverOrders.isNotEmpty,
            billGenerated: serverOrders.any((o) => o.isBilled),
            activeOrders: List<ActiveOrder>.from(serverOrders),
          ),
        ];
      }

      // Simulate the backend returning HTTP 200 isSuccess: true without actually removing the order
      final recordedStatusIds = <int>[];
      Future<Map<String, dynamic>?> brokenBackendUpdate({
        String? token,
        required String orderHeadId,
        required int statusId,
        String? orderId,
        String? status,
        String? tableId,
      }) async {
        recordedStatusIds.add(statusId);
        return {'isSuccess': true, 'statusCode': 200, 'data': 'Ok'};
      }

      final mobileA = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: sharedFetchTables,
        updateOrderHeadStatusApi: brokenBackendUpdate,
        updateOrderChannelStatusApi: ({
          String? token,
          required String orderChannelId,
          required int channelStatusId,
          required String status,
        }) async =>
            {'isSuccess': true, 'statusCode': 200},
        authTokenGetter: () => 'token-shared',
        outletIdGetter: () => 10145,
        skipPaymentReconciliation: true,
      );
      final mobileB = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: sharedFetchTables,
        updateOrderHeadStatusApi: brokenBackendUpdate,
        updateOrderChannelStatusApi: ({
          String? token,
          required String orderChannelId,
          required int channelStatusId,
          required String status,
        }) async =>
            {'isSuccess': true, 'statusCode': 200},
        authTokenGetter: () => 'token-shared',
        outletIdGetter: () => 10145,
        skipPaymentReconciliation: true,
      );
      addTearDown(() {
        mobileA.stopPolling();
        mobileB.stopPolling();
      });

      await mobileA.initializeTables();
      await mobileB.initializeTables();

      final deleted = await mobileA.removeOrderFromTable(
        'table-sync-1',
        'order-a-1',
        isPaidInFull: true,
      );

      // Must fail cleanly and keep both devices consistent with server truth
      expect(deleted, isFalse);
      expect(recordedStatusIds, equals([6, 7, 4]));
      expect(mobileA.tables.first.activeOrders.length, equals(2));
      expect(mobileB.tables.first.activeOrders.length, equals(2));
      expect(mobileA.isOrderDeleted('order-a-1'), isFalse);
    });

    test('Two-device sync: delete persists on backend and syncs across Mobile A and Mobile B', () async {
      final serverOrders = <ActiveOrder>[
        const ActiveOrder(
          orderId: 'order-a-1',
          generatedOrderNo: 'OD/SYNC/0001',
          orderStatus: 'In Progress',
          isBilled: true,
        ),
        const ActiveOrder(
          orderId: 'order-b-2',
          generatedOrderNo: 'OD/SYNC/0002',
          orderStatus: 'Order Placed',
          isBilled: false,
        ),
      ];
      int? vacatedChannelStatusId;
      final recordedStatusCalls = <int>[];

      Future<List<RestaurantTable>> sharedFetchTables({
        required String token,
        required int outletId,
        String? locationName,
      }) async {
        return [
          RestaurantTable(
            id: 'table-sync-2',
            name: 'Table 2',
            capacity: 4,
            location: 'Outlet',
            status: serverOrders.isEmpty
                ? TableStatus.available
                : TableStatus.occupied,
            kotGenerated: serverOrders.isNotEmpty,
            billGenerated: serverOrders.any((o) => o.isBilled),
            activeOrders: List<ActiveOrder>.from(serverOrders),
          ),
        ];
      }

      // First order cancels on statusId 7 fallback (when statusId 6 is rejected);
      // second order cancels cleanly on primary statusId 6 (`CANCELLED`).
      Future<Map<String, dynamic>?> sharedUpdateOrderHeadStatus({
        String? token,
        required String orderHeadId,
        required int statusId,
        String? orderId,
        String? status,
        String? tableId,
      }) async {
        recordedStatusCalls.add(statusId);
        if (orderHeadId == 'order-a-1' && statusId == 6) {
          return {'isSuccess': false, 'statusCode': 400, 'message': 'Try 7'};
        }
        serverOrders.removeWhere((o) => o.orderId == orderHeadId);
        return {'isSuccess': true, 'statusCode': 200};
      }

      Future<Map<String, dynamic>?> sharedVacateChannel({
        String? token,
        required String orderChannelId,
        required int channelStatusId,
        required String status,
      }) async {
        vacatedChannelStatusId = channelStatusId;
        return {'isSuccess': true, 'statusCode': 200};
      }

      final mobileA = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: sharedFetchTables,
        updateOrderHeadStatusApi: sharedUpdateOrderHeadStatus,
        updateOrderChannelStatusApi: sharedVacateChannel,
        authTokenGetter: () => 'token-shared',
        outletIdGetter: () => 10145,
        skipPaymentReconciliation: true,
      );
      final mobileB = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: sharedFetchTables,
        updateOrderHeadStatusApi: sharedUpdateOrderHeadStatus,
        updateOrderChannelStatusApi: sharedVacateChannel,
        authTokenGetter: () => 'token-shared',
        outletIdGetter: () => 10145,
        skipPaymentReconciliation: true,
      );
      addTearDown(() {
        mobileA.stopPolling();
        mobileB.stopPolling();
      });

      await mobileA.initializeTables();
      await mobileB.initializeTables();

      // Mobile A deletes order 1
      final deletedFirst = await mobileA.removeOrderFromTable(
        'table-sync-2',
        'order-a-1',
        isPaidInFull: true,
      );
      expect(deletedFirst, isTrue);
      expect(recordedStatusCalls, equals([6, 7]));
      expect(mobileA.tables.first.activeOrders.map((o) => o.orderId).toList(),
          equals(['order-b-2']));

      // Mobile B refreshes and immediately drops deleted order 1
      await mobileB.refreshTables(silent: true);
      expect(mobileB.tables.first.activeOrders.map((o) => o.orderId).toList(),
          equals(['order-b-2']));

      // Mobile B deletes the remaining order 2
      final deletedSecond = await mobileB.removeOrderFromTable(
        'table-sync-2',
        'order-b-2',
      );
      expect(deletedSecond, isTrue);
      expect(vacatedChannelStatusId, equals(0));
      expect(mobileB.tables.first.hasActiveOrders, isFalse);
      expect(mobileB.tables.first.status, equals(TableStatus.available));

      // Mobile A refreshes and sees table 2 empty & available
      await mobileA.refreshTables(silent: true);
      expect(mobileA.tables.first.hasActiveOrders, isFalse);
      expect(mobileA.tables.first.status, equals(TableStatus.available));
    });

    testWidgets('Open MultiOrderManagementDialog on Mobile B reflects remote deletion on Mobile A and auto-closes when empty', (WidgetTester tester) async {
      final serverOrders = <ActiveOrder>[
        const ActiveOrder(
          orderId: 'order-1',
          generatedOrderNo: 'OD/SYNC/0001',
          orderStatus: 'In Progress',
          isBilled: false,
          kotNumber: 'KOT-1',
        ),
        const ActiveOrder(
          orderId: 'order-2',
          generatedOrderNo: 'OD/SYNC/0002',
          orderStatus: 'In Progress',
          isBilled: false,
          kotNumber: 'KOT-2',
        ),
      ];

      Future<List<RestaurantTable>> sharedFetchTables({
        required String token,
        required int outletId,
        String? locationName,
      }) async {
        return [
          RestaurantTable(
            id: 'table-widget-sync',
            name: 'Table 1',
            capacity: 5,
            location: 'Outlet',
            status: serverOrders.isEmpty
                ? TableStatus.available
                : TableStatus.kotGenerated,
            kotGenerated: serverOrders.isNotEmpty,
            billGenerated: false,
            activeOrders: List<ActiveOrder>.from(serverOrders),
          ),
        ];
      }

      Future<Map<String, dynamic>?> sharedUpdateOrderHeadStatus({
        String? token,
        required String orderHeadId,
        required int statusId,
        String? orderId,
        String? status,
        String? tableId,
      }) async {
        serverOrders.removeWhere((o) => o.orderId == orderHeadId);
        return {'isSuccess': true, 'statusCode': 200};
      }

      final mobileA = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: sharedFetchTables,
        updateOrderHeadStatusApi: sharedUpdateOrderHeadStatus,
        updateOrderChannelStatusApi: ({
          String? token,
          required String orderChannelId,
          required int channelStatusId,
          required String status,
        }) async =>
            {'isSuccess': true, 'statusCode': 200},
        authTokenGetter: () => 'token-shared',
        outletIdGetter: () => 10145,
        skipPaymentReconciliation: true,
      );
      final mobileB = TableProvider(
        checkInternet: () async => true,
        fetchTablesApi: sharedFetchTables,
        updateOrderHeadStatusApi: sharedUpdateOrderHeadStatus,
        updateOrderChannelStatusApi: ({
          String? token,
          required String orderChannelId,
          required int channelStatusId,
          required String status,
        }) async =>
            {'isSuccess': true, 'statusCode': 200},
        authTokenGetter: () => 'token-shared',
        outletIdGetter: () => 10145,
        skipPaymentReconciliation: true,
      );
      addTearDown(() {
        mobileA.stopPolling();
        mobileB.stopPolling();
      });

      await mobileA.initializeTables();
      await mobileB.initializeTables();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TableProvider>.value(value: mobileB),
            ChangeNotifierProvider<AnimatedCartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<NavigationProvider>.value(value: navProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => MultiOrderManagementDialog(
                        table: mobileB.tables.first,
                        enableDynamicFetch: false,
                        isLoading: false,
                        enableShimmerAnimation: false,
                        initialDynamicData: const {
                          'order-1': OrderDynamicInfo(
                            orderId: 'order-1',
                            orderNumber: 'OD/SYNC/0001',
                            customerName: 'Guest 1',
                            totalGuests: 2,
                            itemCount: 1,
                            totalAmount: 250,
                            paidAmount: 0,
                            balanceAmount: 250,
                            isBilled: false,
                            paymentStatus: OrderPaymentStatus.pending,
                            kitchenStatus: OrderKitchenStatus.inKitchen,
                            kitchenStatusText: 'In Progress',
                            isLoaded: true,
                          ),
                          'order-2': OrderDynamicInfo(
                            orderId: 'order-2',
                            orderNumber: 'OD/SYNC/0002',
                            customerName: 'Guest 2',
                            totalGuests: 2,
                            itemCount: 1,
                            totalAmount: 300,
                            paidAmount: 0,
                            balanceAmount: 300,
                            isBilled: false,
                            paymentStatus: OrderPaymentStatus.pending,
                            kitchenStatus: OrderKitchenStatus.inKitchen,
                            kitchenStatusText: 'In Progress',
                            isLoaded: true,
                          ),
                        },
                      ),
                    );
                  },
                  child: const Text('Open Popup'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Popup'));
      await tester.pumpAndSettle();

      expect(find.text('OD/SYNC/0001'), findsOneWidget);
      expect(find.text('OD/SYNC/0002'), findsOneWidget);

      // Mobile A deletes order-1 via backend API
      expect(await mobileA.removeOrderFromTable('table-widget-sync', 'order-1'), isTrue);
      await mobileB.refreshTables(silent: true);
      await tester.pump();

      expect(find.text('OD/SYNC/0001'), findsNothing);
      expect(find.text('OD/SYNC/0002'), findsOneWidget);

      // Mobile A deletes the last remaining order-2 via backend API
      expect(await mobileA.removeOrderFromTable('table-widget-sync', 'order-2'), isTrue);
      await mobileB.refreshTables(silent: true);
      await tester.pumpAndSettle();

      expect(find.byType(MultiOrderManagementDialog), findsNothing);

      mobileA.stopPolling();
      mobileB.stopPolling();
    });
  });
}
