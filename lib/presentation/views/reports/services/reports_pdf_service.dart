import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ReportsPdfService {
  static Future<File?> generateAnalyticsReport({
    required String timeFrame,
    required Map<String, String> kpiData,
    required Map<String, String> chartData,
    required Map<String, String> orderStats,
    required Map<String, dynamic> channelData,
  }) async {
    try {
      final doc = pw.Document();

      // Load a Unicode-supporting font
      final font = await rootBundle.load("fonts/Roboto-Regular.ttf");
      final fontBold = await rootBundle.load("fonts/Roboto-Bold.ttf");
      final ttf = pw.Font.ttf(font);
      final ttfBold = pw.Font.ttf(fontBold);

      doc.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Restaurant Analytics Report',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Business Performance Dashboard',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey700,
                        font: ttf,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Period: $timeFrame',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        font: ttfBold,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 12, font: ttf),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // KPI Section
              pw.Text(
                'Key Performance Indicators',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: ttfBold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Metric',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Value',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Change',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total Revenue',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['revenue']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['revenueChange']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total Orders',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['orders']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['ordersChange']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Avg Order Value',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['avgOrder']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['avgOrderChange']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Table Turnover Rate',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['turnover']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          kpiData['turnoverChange']!,
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Revenue Trend Section
              pw.Text(
                'Revenue Trend',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: ttfBold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Total Revenue: ${chartData['totalRevenue']}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Change: ${chartData['change']}',
                      style: pw.TextStyle(fontSize: 14, font: ttf),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Order Statistics
              pw.Text(
                'Order Statistics',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: ttfBold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Daily Orders: ${orderStats['dailyOrders']}',
                      style: pw.TextStyle(fontSize: 14, font: ttf),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Change: ${orderStats['change']}',
                      style: pw.TextStyle(fontSize: 14, font: ttf),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Order Channels
              pw.Text(
                'Order Channels Distribution',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: ttfBold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Channel',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Percentage',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Dine-in',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${channelData['dineIn'].toStringAsFixed(1)}%',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Phone Order',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${channelData['phone'].toStringAsFixed(1)}%',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Takeaway',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${channelData['takeaway'].toStringAsFixed(1)}%',
                          style: pw.TextStyle(font: ttf),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Summary Section
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '- Restaurant performance shows consistent growth across key metrics',
                      style: pw.TextStyle(fontSize: 12, font: ttf),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '- Dine-in remains the primary order channel with ${channelData['dineIn'].toStringAsFixed(0)}% share',
                      style: pw.TextStyle(fontSize: 12, font: ttf),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '- Average order value trends indicate healthy customer spending patterns',
                      style: pw.TextStyle(fontSize: 12, font: ttf),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  'This report is generated automatically from restaurant POS system analytics data.\nFor any queries, please contact your system administrator.',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                    font: ttf,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ];
          },
        ),
      );

      // Check permissions
      if (Platform.isAndroid) {
        if (!await Permission.storage.request().isGranted) {
          return null;
        }
      }

      // Save file
      final directory = await getExternalStorageDirectory();
      final file = File(
        '${directory!.path}/analytics_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await doc.save());

      return file;
    } catch (e) {
      print('PDF generation error: $e');
      return null;
    }
  }
}
