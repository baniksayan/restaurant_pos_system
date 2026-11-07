import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos_system/features/order_taking/widgets/kot_pdf_viewer_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({required Uint8List dummyPdf}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  KOTPDFViewerDialog.show(
                    context,
                    pdfBytes: dummyPdf,
                    kotNumber: '101',
                    fileName: 'KOT_101.pdf',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets(
    'KOTPDFViewerDialog displays header, action buttons (Done, Share, Print KOT), and closes on Done',
    (tester) async {
      // Minimal valid dummy PDF header
      final dummyPdf = Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits);

      await tester.pumpWidget(buildTestWidget(dummyPdf: dummyPdf));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('KOT Print Preview'), findsOneWidget);
      expect(find.text('KOT #101'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Print KOT'), findsOneWidget);

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('KOT Print Preview'), findsNothing);
    },
  );
}
