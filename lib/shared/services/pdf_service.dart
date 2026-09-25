// lib/services/pdf_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:restaurant_pos_system/features/order_taking/providers/animated_cart_provider.dart';
import 'package:restaurant_pos_system/data/models/bill_details_response.dart'
    show PaymentDetail;
import '../../core/constants/currency_constants.dart';

class PDFService {
  /// Fallbacks only — used if a real bill's company details couldn't be
  /// fetched (e.g. the network call in generateCustomerBill's caller
  /// failed). Every normal bill/invoice must pass the tenant's real
  /// companyName/companyAddress/companyGstNo/companyPhone from
  /// Order/getBillDetailByBillId's companyDt instead of relying on these.
  static const String restaurantName = "WhizEats Pro";
  static const String restaurantAddress =
      "123 Food Street, Gourmet City, State 12345";
  static const String restaurantPhone = "+91 98765 43210";
  static const String gstNumber = "Not available";

  // Use centralized currency symbol
    static String get rupeeSymbol {
    final sym = CurrencyConstants.symbol;
    if (sym == '₹') return 'Rs. ';
    return sym;
  }

  static String _formatCurrency(num amount) {
    return '$rupeeSymbol${CurrencyConstants.formatWithoutSymbol(amount, decimalDigits: 2)}';
  }

  static const double _kotPageWidth = 226.77; // hardcoded for KOT width  (80mm)
  static const double _kotMargin = 8;
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
        pageFormat: const PdfPageFormat(
          _kotPageWidth,
          double.infinity,
          marginAll: _kotMargin,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _kotDashedLine(),
              pw.SizedBox(height: 8),
              _kotHeader(),
              pw.SizedBox(height: 8),
              _kotDashedLine(),
              pw.SizedBox(height: 10),
              _kotOrderBox(kotNo, orderNumber, dateStr, timeStr, tableName),
              pw.SizedBox(height: 8),
              _kotSectionHeading('ORDER ITEMS (${items.length})'),
              pw.SizedBox(height: 14),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.SizedBox(width: 18),
                    pw.Container(
                      width: 24,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'QTY',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'ITEM NAME',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'NOTE',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _kotDashedLine(),
              for (int i = 0; i < items.length; i++)
                _kotItemCard(i + 1, items[i]),

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
                        style: const pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        specialNotes.trim(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Generate Customer Bill with GST and Special Notes
  //
  // [companyName]/[companyAddress]/[companyPhone]/[companyGstNo] should be
  // the real tenant details from Order/getBillDetailByBillId's `companyDt`
  // — every caller that has a billId should fetch that first and pass the
  // real values through. They're optional (falling back to the constants
  // above) only so a bill can still print if that fetch fails; a live
  // invoice should never be missing them.
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
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyGstNo,
    String gstLabel = 'GST',
  }) async {
    final resolvedName =
        (companyName != null && companyName.trim().isNotEmpty)
            ? companyName.trim()
            : restaurantName;
    final resolvedAddress =
        (companyAddress != null && companyAddress.trim().isNotEmpty)
            ? companyAddress.trim()
            : restaurantAddress;
    final resolvedPhone =
        (companyPhone != null && companyPhone.trim().isNotEmpty)
            ? companyPhone.trim()
            : restaurantPhone;
    final resolvedGstNo =
        (companyGstNo != null && companyGstNo.trim().isNotEmpty)
            ? companyGstNo.trim()
            : gstNumber;

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
                      resolvedName,
                      style: const pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      resolvedAddress,
                      style: const pw.TextStyle(fontSize: 14),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text("Phone: $resolvedPhone"),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "GST No: $resolvedGstNo",
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Invoice Title
              pw.Center(
                child: pw.Text(
                  "INVOICE",
                  style: const pw.TextStyle(
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
                        style: const pw.TextStyle(
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
                        style: const pw.TextStyle(
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
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        "QTY",
                        style: const pw.TextStyle(
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
                        style: const pw.TextStyle(
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
                        style: const pw.TextStyle(
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
                              style: const pw.TextStyle(
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
                          "$rupeeSymbol${item.price.toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "$rupeeSymbol${itemTotal.toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
                        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
                      "$rupeeSymbol${subtotal.toStringAsFixed(2)}",
                    ),
                    pw.SizedBox(height: 8),
                    _buildTotalRow(
                      "$gstLabel:",
                      "$rupeeSymbol${gstAmount.toStringAsFixed(2)}",
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 2),
                    pw.SizedBox(height: 8),
                    _buildTotalRow(
                      "TOTAL AMOUNT:",
                      "$rupeeSymbol${total.toStringAsFixed(2)}",
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
                            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
                            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
                      "For any queries, please contact: $resolvedPhone",
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

  // Generate a customer bill formatted for an 80mm (3") thermal POS
  // printer — the format this industry actually prints on, not an A4
  // invoice. Mirrors generateKOT's page setup (same _kotPageWidth/_kotMargin,
  // same dashed-line/letter-spacing helpers) and takes the exact same
  // parameters as generateCustomerBill, so every existing caller can switch
  // to this by changing only the method name.
  //
  // Strictly monochrome (PdfColors.black/grey only) — a thermal head has no
  // color to print in the first place.
  static Future<Uint8List> generateThermalBill({
    required List<dynamic> items,
    required String tableId,
    required String tableName,
    required String orderNumber,
    required DateTime orderTime,
    required double subtotal,
    required double gstAmount,
    required double total,
    String? specialNotes,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyGstNo,
    String gstLabel = 'GST',
    // Extra detail a real receipt carries that generateCustomerBill's
    // callers never had a slot for — the bill's own number (distinct from
    // the order number), who it's for, and what discount was applied.
    String? billNo,
    String? customerName,
    String? customerPhone,
    double discountAmount = 0,
    // One row per tender — mode, amount, and change on that tender. Comes
    // straight from Order/getBillDetailByBillId's own paymentDetail
    // resultset when the caller has it; omitted entirely (not padded with
    // zeros) when it doesn't, e.g. printing immediately after createBill
    // before that fetch has happened.
    List<PaymentDetail>? payments,
  }) async {
    final resolvedName =
        (companyName != null && companyName.trim().isNotEmpty)
            ? companyName.trim()
            : restaurantName;
    final resolvedAddress =
        (companyAddress != null && companyAddress.trim().isNotEmpty)
            ? companyAddress.trim()
            : restaurantAddress;
    final resolvedPhone =
        (companyPhone != null && companyPhone.trim().isNotEmpty)
            ? companyPhone.trim()
            : restaurantPhone;
    final resolvedGstNo =
        (companyGstNo != null && companyGstNo.trim().isNotEmpty)
            ? companyGstNo.trim()
            : gstNumber;

    final dateStr = _formatDate(orderTime);
    final timeStr = _formatTime(orderTime);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          _kotPageWidth,
          double.infinity,
          marginAll: _kotMargin,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  resolvedName,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  resolvedAddress,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  'Ph: $resolvedPhone   GSTIN: $resolvedGstNo',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
              ),
              pw.SizedBox(height: 8),
              _kotDashedLine(),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  _kotLetterSpace('TAX INVOICE'),
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              _kotDashedLine(),
              pw.SizedBox(height: 8),

              _thermalRow('Bill No', billNo?.isNotEmpty == true ? billNo! : orderNumber),
              _thermalRow('Order No', orderNumber),
              _thermalRow('Date', '$dateStr  $timeStr'),
              _thermalRow('Table', tableName.isNotEmpty ? tableName : tableId),
              if (customerName != null && customerName.trim().isNotEmpty)
                _thermalRow('Customer', customerName.trim()),
              if (customerPhone != null && customerPhone.trim().isNotEmpty)
                _thermalRow('Phone', customerPhone.trim()),

              pw.SizedBox(height: 8),
              _kotDashedLine(),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      'ITEM',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(
                    width: 22,
                    child: pw.Text(
                      'QTY',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(
                    width: 42,
                    child: pw.Text(
                      'RATE',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(
                    width: 46,
                    child: pw.Text(
                      'AMOUNT',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              _kotDashedLine(),
              for (final item in items) _thermalItemRow(item),
              _kotDashedLine(),
              pw.SizedBox(height: 6),

              if (specialNotes != null && specialNotes.trim().isNotEmpty) ...[
                pw.Text(
                  'Note: ${specialNotes.trim()}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 6),
              ],

              _thermalTotalRow('Subtotal', subtotal),
              if (discountAmount > 0)
                _thermalTotalRow('Discount', -discountAmount),
              _thermalTotalRow(gstLabel, gstAmount),
              pw.SizedBox(height: 4),
              _kotDashedLine(),
              pw.SizedBox(height: 4),
              _thermalTotalRow('TOTAL', total, emphasize: true),

              if (payments != null && payments.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _kotDashedLine(),
                pw.SizedBox(height: 4),
                for (final p in payments) ...[
                  _thermalRow(
                    p.paymentMode.isNotEmpty ? p.paymentMode : 'Paid',
                    _formatCurrency(p.paymentAmount),
                  ),
                  if (p.returnAmt > 0)
                    _thermalRow('Change', _formatCurrency(p.returnAmt)),
                ],
              ],

              pw.SizedBox(height: 10),
              _kotDashedLine(),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'THANK YOU, VISIT AGAIN!',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Center(
                child: pw.Text(
                  'Computer generated invoice — no signature required',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
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

  // Splits a string into lines of max [maxLen] characters, breaking at spaces.

  // static List<String> _splitText(String text, int maxLen) {
  //   final words = text.split(' ');
  //   List<String> lines = [];
  //   String current = '';
  //   for (final word in words) {
  //     if ((current + (current.isEmpty ? '' : ' ') + word).length > maxLen) {
  //       if (current.isNotEmpty) lines.add(current);
  //       current = word;
  //     } else {
  //       current += (current.isEmpty ? '' : ' ') + word;
  //     }
  //   }
  //   if (current.isNotEmpty) lines.add(current);
  //   return lines;
  // }

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
    final name = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: name);
    } catch (e) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$name');
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(file.path)], subject: name);
      } catch (err) {
        rethrow;
      }
    }
  }

  static Future<void> printPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      format: PdfPageFormat.roll80, // 80mm thermal printer format
      name: 'KOT_Order',
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  static String _kotLetterSpace(String text) {
    return text.replaceAll(' ', '   ');
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

  static pw.Widget _kotChefHatIcon({double size = 17}) {
    // custom chef hat icon for KOT
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final double w = sz.x;
        final double h = sz.y;

        final c =
            ctx
              ..setColor(PdfColors.black)
              ..setLineWidth(size * 0.04)
              ..setLineCap(PdfLineCap.round)
              ..setLineJoin(PdfLineJoin.round);

        double leftX = w * 0.21;
        double rightX = w * 0.79;
        double topY = h * 0.40;
        double bottomY = h * 0.05;

        c.moveTo(leftX, topY);

        c.lineTo(leftX + (w * 0.05), bottomY);
        c.lineTo(rightX - (w * 0.05), bottomY);
        c.lineTo(rightX, topY);

        c.curveTo(w * 1.05, h * 0.55, w * 0.88, h * 0.75, w * 0.70, h * 0.70);

        c.curveTo(w * 0.60, h * 0.90, w * 0.52, h * 0.90, w * 0.50, h * 0.75);

        c.curveTo(w * 0.48, h * 0.90, w * 0.40, h * 0.90, w * 0.30, h * 0.70);

        c.curveTo(w * 0.12, h * 0.75, w * -0.05, h * 0.55, leftX, topY);

        c.strokePath();

        c.moveTo(w * 0.42, h * 0.32);
        c.lineTo(w * 0.42, h * 0.12);
        c.strokePath();

        c.moveTo(w * 0.58, h * 0.32);
        c.lineTo(w * 0.58, h * 0.12);
        c.strokePath();
      },
    );
  }

  static pw.Widget _kotTableIcon({double size = 16}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (ctx, sz) {
        final c =
            ctx
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

  static pw.Widget _kotHeader() {
    return pw.FittedBox(
      fit: pw.BoxFit.scaleDown,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _kotChefHatIcon(),
          pw.SizedBox(width: 20),
          pw.Text(
            _kotLetterSpace('KITCHEN ORDER TICKET'),
            style: const pw.TextStyle(fontSize: 13),
          ),
          pw.SizedBox(width: 20),
          _kotChefHatIcon(),
        ],
      ),
    );
  }

  static pw.Widget _kotOrderBox(
    String kotNo,
    String orderNo,
    String dateStr,
    String timeStr,
    String tableName,
  ) {
    final cleanKotNo = kotNo.trim().isNotEmpty ? kotNo.trim() : 'KOT';
    final cleanOrderNo =
        orderNo.trim().isNotEmpty ? orderNo.trim() : cleanKotNo;
    final cleanTableName =
        tableName.trim().isNotEmpty ? tableName.trim() : 'Table';
    final cleanDateStr = dateStr.trim().isNotEmpty ? dateStr.trim() : '-';
    final cleanTimeStr = timeStr.trim().isNotEmpty ? timeStr.trim() : '-';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    "KOT NO.",
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Text(
                      cleanKotNo,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Container(
                    height: 1,
                    width: double.infinity,
                    color: PdfColors.grey400,
                  ),
                  pw.SizedBox(height: 6),

                  pw.Container(
                    width: double.infinity,
                    alignment: pw.Alignment.center,
                    child: pw.FittedBox(
                      fit: pw.BoxFit.scaleDown,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          _kotTableIcon(size: 11),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            cleanTableName,
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    "ORDER NO.",
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Text(
                      cleanOrderNo,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Container(
                    height: 1,
                    width: double.infinity,
                    color: PdfColors.grey400,
                  ),
                  pw.SizedBox(height: 6),

                  pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          cleanDateStr,
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                          child: pw.Text(
                            '|',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        ),
                        pw.Text(
                          cleanTimeStr,
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _kotSectionHeading(String text) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(child: pw.Container(height: 1, color: PdfColors.grey700)),
        pw.SizedBox(width: 10),
        pw.Text(
          _kotLetterSpace(text),
          style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(child: pw.Container(height: 1, color: PdfColors.grey700)),
      ],
    );
  }

  // ── Thermal-bill-only helpers (generateThermalBill) ──────────────────

  static pw.Widget _thermalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
          pw.Flexible(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _thermalTotalRow(
    String label,
    double amount, {
    bool emphasize = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: emphasize ? 10.5 : 9,
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _formatCurrency(amount),
            style: pw.TextStyle(
              fontSize: emphasize ? 11 : 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// One item line — duck-typed like generateCustomerBill's own item loop
  /// (works on CartItem or anything else exposing name/quantity/price).
  static pw.Widget _thermalItemRow(dynamic item) {
    final double price = item.price;
    final int quantity = item.quantity;
    final double amount = price * quantity;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Text(
                  (item.name as String),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
              pw.SizedBox(
                width: 22,
                child: pw.Text(
                  '$quantity',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
              pw.SizedBox(
                width: 42,
                child: pw.Text(
                  price.toStringAsFixed(2),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ),
              pw.SizedBox(
                width: 46,
                child: pw.Text(
                  amount.toStringAsFixed(2),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (item.specialNotes != null &&
              (item.specialNotes as String).trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 1),
              child: pw.Text(
                'Note: ${(item.specialNotes as String).trim()}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _kotItemCard(int index, CartItem item) {
    String noteText = '-';
    if (item.specialNotes != null && item.specialNotes!.trim().isNotEmpty) {
      String rawNote = item.specialNotes!.trim();
      noteText = rawNote
          .split(' ')
          .map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');
      if (noteText.length > 30) {
        // 30 char limit for note
        noteText = '${noteText.substring(0, 30)}...';
      }
    }

    final itemName =
        item.name.trim().isNotEmpty ? item.name.trim().toUpperCase() : 'ITEM';

    return pw.Column(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 20,
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  '$index.',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.Container(
                width: 20,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${item.quantity}x',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 15),

              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  itemName,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  noteText.trim().isNotEmpty ? noteText : '-',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        // Dashed line separating every row
        _kotDashedLine(),
      ],
    );
  }
}
