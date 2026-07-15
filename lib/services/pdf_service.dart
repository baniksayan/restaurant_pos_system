// lib/services/pdf_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../presentation/view_models/providers/animated_cart_provider.dart';
import '../core/constants/currency_constants.dart';

class PDFService {
  static const String restaurantName = "WiZARD Restaurant";
  static const String restaurantAddress =
      "123 Food Street, Gourmet City, State 12345";
  static const String restaurantPhone = "+91 98765 43210";
  static const String restaurantEmail = "orders@wizardrestaurant.com";
  static const String gstNumber = "22AAAAA0000A1Z5";

  // Use centralized currency symbol
  static const String rupeeSymbol = CurrencyConstants.symbol; // kept name for backward-compat in-file

  static const double _kotPageWidth = 320;
  static const double _kotMargin = 18;
  static double get _kotContentWidth => _kotPageWidth - _kotMargin * 2;

  // Generate KOT (Kitchen Order Ticket) for Chef - Updated with Special Notes
  static Future<Uint8List> generateKOT({
    required List<CartItem> items,
    required String tableId,
    required String tableName,
    required String orderNumber,
    required DateTime orderTime,
    required String kotNo,
    required String waiterName,
    String? specialNotes,
  }) async {
    final pdf = pw.Document();

    final dateStr = _formatDate(orderTime);
    final timeStr = _formatTime(orderTime);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _kotPageWidth,
          double.infinity,
          marginAll: _kotMargin,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _kotDashedLine(),
              pw.SizedBox(height: 10),
              _kotHeader(),
              pw.SizedBox(height: 10),
              _kotDashedLine(),
              pw.SizedBox(height: 18),
              _kotOrderBox(kotNo, orderNumber),
              pw.SizedBox(height: 16),
              _kotInfoCard(tableName, waiterName),
              pw.SizedBox(height: 22),
              _kotSectionHeading('ORDER ITEMS (${items.length})'),
              pw.SizedBox(height: 14),
              for (final item in items)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: _kotItemCard(item),
                ),
              pw.SizedBox(height: 4),
              // Special Notes for entire order
              if (specialNotes != null && specialNotes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _kotLetterSpace("SPECIAL INSTRUCTIONS"),
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        specialNotes.trim(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
              _kotDashedLine(),
              pw.SizedBox(height: 14),
              pw.Center(
                child: pw.Text(
                  '$dateStr   |   $timeStr',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Column(
                  children: [
                    _kotChefHatIcon(size: 20),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      _kotLetterSpace('END OF ORDER'),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              _kotTearLine(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Generate Customer Bill with GST and Special Notes
  static Future<Uint8List> generateCustomerBill({
    required List<dynamic> items,
    required String tableId,
    required String tableName,
    required String orderNumber,
    required DateTime orderTime,
    required double subtotal,
    required double gstAmount,
    required double total,
    String? specialNotes, // |  ADD this parameter
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Restaurant Details
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      restaurantName,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      restaurantAddress,
                      style: const pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text("Phone: $restaurantPhone  |  "),
                        pw.Text("Email: $restaurantEmail"),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "GST No: $gstNumber",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Invoice Title
              pw.Center(
                child: pw.Text(
                  "INVOICE",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Order Information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Bill To:",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "$tableName Customer",
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        "Table Number: ${tableName.split(' ').last}",
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        "Order #: $orderNumber",
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Invoice Date:",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _formatDate(orderTime),
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        "Time: ${_formatTime(orderTime)}",
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        "Waiter ID: W001",
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Items Table Header
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        "ITEM",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        "QTY",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        "PRICE",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        "TOTAL",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Items List with special notes
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemTotal = item.price * item.quantity;

                return pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: index % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.name,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Container(
                              margin: const pw.EdgeInsets.only(top: 2),
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                color:
                                    _isVeg(item.name)
                                        ? PdfColors.green100
                                        : PdfColors.red100,
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Text(
                                _isVeg(item.name) ? "VEG" : "NON-VEG",
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color:
                                      _isVeg(item.name)
                                          ? PdfColors.green
                                          : PdfColors.red,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            // |  ADD special notes for each item
                            if (item.specialNotes != null &&
                                item.specialNotes!.isNotEmpty)
                              pw.Text(
                                "Note: ${item.specialNotes}",
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.blue,
                                ),
                              ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          "${item.quantity}",
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "${CurrencyConstants.symbol}${item.price.toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "${CurrencyConstants.symbol}${itemTotal.toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              pw.SizedBox(height: 20),

              // |  ADD Special Notes section for entire order
              if (specialNotes != null && specialNotes.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.yellow50,
                    border: pw.Border.all(color: PdfColors.orange200),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Special Instructions:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        specialNotes,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Totals Section
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    _buildTotalRow(
                      "Subtotal:",
                      "${CurrencyConstants.symbol}${subtotal.toStringAsFixed(2)}",
                    ),
                    pw.SizedBox(height: 8),
                    _buildTotalRow(
                      "GST (18%):",
                      "${CurrencyConstants.symbol}${gstAmount.toStringAsFixed(2)}",
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 2),
                    pw.SizedBox(height: 8),
                    _buildTotalRow(
                      "TOTAL AMOUNT:",
                      "${CurrencyConstants.symbol}${total.toStringAsFixed(2)}",
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Payment Info
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Payment Method: Cash",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "Status: Paid",
                            style: const pw.TextStyle(color: PdfColors.green),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            "Thank you for dining with us!",
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "Visit again!",
                            style: const pw.TextStyle(color: PdfColors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      "This is a computer generated invoice. No signature required.",
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "For any queries, please contact: $restaurantPhone",
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // 🚀 NEW: WhatsApp Share Implementation
  static Future<void> sharePDFOnWhatsApp(
    Uint8List pdfBytes, {
    required String fileName,
    required String phoneNumber,
  }) async {
    try {
      // Save PDF to temporary file first
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhoneNumber = phoneNumber.replaceAll(
        RegExp(r'[\s\-\(\)\+]'),
        '',
      );

      final whatsappUrl =
          "https://wa.me/$cleanPhoneNumber?text=Please find your bill attached.";

      // WhatsApp does not support sending files directly via url_launcher,
      // but after sending the message, user can easily attach PDF in chat.
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw "Could not open WhatsApp. Please ensure WhatsApp is installed.";
      }
    } catch (e) {
      throw "Error sharing PDF on WhatsApp: $e";
    }
  }

  // Helper methods
  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: pw.FontWeight.bold,
            color: isTotal ? PdfColors.blue800 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  static String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  static bool _isVeg(String itemName) {
    // Simple logic - in real app, this would come from item data
    final vegItems = ['paneer', 'dosa', 'tikka', 'dal', 'rice', 'naan'];
    return vegItems.any((veg) => itemName.toLowerCase().contains(veg));
  }

  /// Splits a string into lines of max [maxLen] characters, breaking at spaces.
  static List<String> _splitText(String text, int maxLen) {
    final words = text.split(' ');
    List<String> lines = [];
    String current = '';
    for (final word in words) {
      if ((current + (current.isEmpty ? '' : ' ') + word).length > maxLen) {
        if (current.isNotEmpty) lines.add(current);
        current = word;
      } else {
        current += (current.isEmpty ? '' : ' ') + word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  // Generate unique order number
  static String generateOrderNumber() {
    final now = DateTime.now();
    return "ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
  }

  // Save and Share PDF
  static Future<void> savePDF(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
  }

  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
  }

  static Future<void> printPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  static String _kotLetterSpace(String text) {
    return text.split('').map((c) => c == ' ' ? '   ' : c).join(' ');
  }

  static pw.Widget _kotDashedLine({
    double? width,
    double dash = 3.5,
    double gap = 2.5,
    double thickness = 1,
    PdfColor color = PdfColors.black,
  }) {
    final w = width ?? _kotContentWidth;
    final count = (w / (dash + gap)).floor().clamp(1, 200);
    return pw.Wrap(
      spacing: gap,
      children: List.generate(
        count,
        (_) => pw.Container(width: dash, height: thickness, color: color),
      ),
    );
  }

  static pw.Widget _kotVerticalDashedLine({
    double height = 40,
    double dash = 3,
    double gap = 2.5,
    double thickness = 1,
    PdfColor color = PdfColors.black,
  }) {
    final count = (height / (dash + gap)).floor().clamp(1, 100);
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: List.generate(
        count,
        (i) => pw.Container(
          margin: pw.EdgeInsets.only(bottom: i == count - 1 ? 0 : gap),
          width: thickness,
          height: dash,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _kotChefHatIcon({double size = 17}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final c = ctx
          ..setColor(PdfColors.black)
          ..setLineWidth(0.9);
        c.drawEllipse(sz.x * 0.30, sz.y * 0.72, sz.x * 0.15, sz.y * 0.15);
        c.strokePath();
        c.drawEllipse(sz.x * 0.50, sz.y * 0.78, sz.x * 0.17, sz.y * 0.17);
        c.strokePath();
        c.drawEllipse(sz.x * 0.70, sz.y * 0.72, sz.x * 0.15, sz.y * 0.15);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.28, sz.y * 0.60)
          ..lineTo(sz.x * 0.72, sz.y * 0.60)
          ..lineTo(sz.x * 0.66, sz.y * 0.88)
          ..lineTo(sz.x * 0.34, sz.y * 0.88)
          ..lineTo(sz.x * 0.28, sz.y * 0.60);
        c.strokePath();
      },
    );
  }

  static pw.Widget _kotTableIcon({double size = 16}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final c = ctx
          ..setColor(PdfColors.black)
          ..setLineWidth(0.9);
        c.drawRect(sz.x * 0.08, sz.y * 0.60, sz.x * 0.84, sz.y * 0.14);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.22, sz.y * 0.60)
          ..lineTo(sz.x * 0.18, sz.y * 0.12);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.78, sz.y * 0.60)
          ..lineTo(sz.x * 0.82, sz.y * 0.12);
        c.strokePath();
      },
    );
  }

  static pw.Widget _kotPersonIcon({double size = 16}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final c = ctx
          ..setColor(PdfColors.black)
          ..setLineWidth(0.9);
        c.drawEllipse(sz.x * 0.5, sz.y * 0.68, sz.x * 0.17, sz.y * 0.17);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.18, sz.y * 0.14)
          ..curveTo(sz.x * 0.18, sz.y * 0.46, sz.x * 0.82, sz.y * 0.46, sz.x * 0.82, sz.y * 0.14);
        c.strokePath();
      },
    );
  }

  static pw.Widget _kotClockIcon({double size = 16}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final c = ctx
          ..setColor(PdfColors.black)
          ..setLineWidth(0.9);
        c.drawEllipse(sz.x * 0.5, sz.y * 0.5, sz.x * 0.4, sz.y * 0.4);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.5, sz.y * 0.5)
          ..lineTo(sz.x * 0.5, sz.y * 0.74);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.5, sz.y * 0.5)
          ..lineTo(sz.x * 0.66, sz.y * 0.5);
        c.strokePath();
      },
    );
  }

  static pw.Widget _kotCalendarIcon({double size = 16}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final c = ctx
          ..setColor(PdfColors.black)
          ..setLineWidth(0.9);
        c.drawRect(sz.x * 0.14, sz.y * 0.16, sz.x * 0.72, sz.y * 0.66);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.14, sz.y * 0.36)
          ..lineTo(sz.x * 0.86, sz.y * 0.36);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.30, sz.y * 0.08)
          ..lineTo(sz.x * 0.30, sz.y * 0.24);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.70, sz.y * 0.08)
          ..lineTo(sz.x * 0.70, sz.y * 0.24);
        c.strokePath();
      },
    );
  }

  static pw.Widget _kotScissorsIcon({double size = 13}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final c = ctx
          ..setColor(PdfColors.black)
          ..setLineWidth(0.9);
        c.drawEllipse(sz.x * 0.25, sz.y * 0.25, sz.x * 0.12, sz.y * 0.12);
        c.strokePath();
        c.drawEllipse(sz.x * 0.25, sz.y * 0.75, sz.x * 0.12, sz.y * 0.12);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.35, sz.y * 0.32)
          ..lineTo(sz.x * 0.92, sz.y * 0.85);
        c.strokePath();
        c
          ..moveTo(sz.x * 0.35, sz.y * 0.68)
          ..lineTo(sz.x * 0.92, sz.y * 0.15);
        c.strokePath();
      },
    );
  }

  static pw.Widget _kotHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _kotChefHatIcon(),
        pw.SizedBox(width: 10),
        pw.Text(
          _kotLetterSpace('KITCHEN ORDER TICKET'),
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 10),
        _kotChefHatIcon(),
      ],
    );
  }

  static pw.Widget _kotOrderBox(String kotNo, String orderNo) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _kotLabel('KOT NO.'),
                pw.SizedBox(height: 4),
                pw.Text(
                  kotNo,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          _kotVerticalDashedLine(height: 38),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _kotLabel('ORDER NO.'),
                pw.SizedBox(height: 4),
                pw.Text(
                  orderNo,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kotInfoCard(String tableName, String waiterName) {
    return pw.Column(
      children: [
        _kotDashedLine(),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: _kotInfoTile(_kotTableIcon(), 'TABLE', tableName),
              ),
              _kotVerticalDashedLine(height: 36),
              pw.Expanded(
                child: _kotInfoTile(_kotPersonIcon(), 'WAITER', waiterName),
              ),
            ],
          ),
        ),
        _kotDashedLine(),
      ],
    );
  }

  static pw.Widget _kotInfoTile(pw.Widget icon, String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            icon,
            pw.SizedBox(width: 5),
            _kotLabel(label),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _kotSectionHeading(String text) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _kotDashedLine(width: 70, thickness: 1),
        pw.SizedBox(width: 10),
        pw.Text(
          _kotLetterSpace(text),
          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 10),
        _kotDashedLine(width: 70, thickness: 1),
      ],
    );
  }

  static pw.Widget _kotItemCard(CartItem item) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _kotDashedLine(),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 34,
                height: 34,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
                child: pw.Text(
                  '${item.quantity}x',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Text(
                  _kotLetterSpace(item.name.toUpperCase()),
                  style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        if (item.specialNotes != null && item.specialNotes!.trim().isNotEmpty) ...[
          _kotDashedLine(dash: 2, gap: 2, thickness: 0.6),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 12),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${_kotLetterSpace('NOTE')}:  ',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                  ),
                  pw.TextSpan(
                    text: item.specialNotes,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ] else
          pw.SizedBox(height: 6),
        _kotDashedLine(),
      ],
    );
  }

  static pw.Widget _kotTearLine() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _kotScissorsIcon(),
        pw.SizedBox(width: 6),
        _kotDashedLine(width: 90),
        pw.SizedBox(width: 8),
        pw.Text(
          _kotLetterSpace('TEAR HERE'),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(width: 8),
        _kotDashedLine(width: 90),
        pw.SizedBox(width: 6),
        _kotScissorsIcon(),
      ],
    );
  }

  static pw.Widget _kotLabel(String text) {
    return pw.Text(
      _kotLetterSpace(text),
      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
    );
  }
}
