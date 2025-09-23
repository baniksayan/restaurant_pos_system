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

    // Set page size for 57mm thermal printer (width: 57mm, print width: 48mm)
    final kotPageFormat = PdfPageFormat(57 * PdfPageFormat.mm, PdfPageFormat.a4.height, marginAll: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: kotPageFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Restaurant Title Centered
                pw.Center(
                  child: pw.Text(
                    restaurantName,
                    style: pw.TextStyle(
                      fontSize: 13, // slightly smaller for better UI
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Divider(thickness: 1, color: PdfColors.black),

                // Header Info, each line centered, not bold
                pw.Center(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        "Order No: $orderNumber",
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "KOT No: $kotNo",
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "Table: $tableName",
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "Waiter: $waiterName",
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.black),

                // Items Header
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        "Item Name",
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        "Qty",
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        "Remarks",
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.black),

                // Items List
                ...items.map((item) {
                  final itemNameLines = _splitText(item.name, 22);
                  final remarksText = (item.specialNotes != null && item.specialNotes!.trim().isNotEmpty)
                      ? item.specialNotes!.trim()
                      : '---';
                  final remarksLines = _splitText(remarksText, 18);
                  final maxLines = itemNameLines.length > remarksLines.length ? itemNameLines.length : remarksLines.length;

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < maxLines; i++)
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              flex: 4,
                              child: pw.Text(
                                i < itemNameLines.length ? itemNameLines[i] : '',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                i == 0 ? "${item.quantity}" : '',
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                i < remarksLines.length ? remarksLines[i] : '',
                                style: pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      pw.SizedBox(height: 4),
                    ],
                  );
                }).toList(),
                pw.Divider(thickness: 1, color: PdfColors.black),

                // Special Notes for entire order
                if (specialNotes != null && specialNotes.trim().isNotEmpty) ...[
                  pw.Text(
                    "Special Instructions:",
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  ..._splitText(specialNotes.trim(), 32).map((line) => pw.Text(line, style: pw.TextStyle(fontSize: 8))),
                  pw.SizedBox(height: 2),
                ],

                // Footer: Date and Time right-aligned, smaller font
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Date: ${_formatDate(orderTime)} | Time: ${_formatTime(orderTime)}",
                      style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
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
}
