import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ReportsCsvService {
  static Future<File?> generateAnalyticsReport({
    required String timeFrame,
    required Map<String, String> kpiData,
    required Map<String, String> chartData,
    required Map<String, String> orderStats,
    required Map<String, dynamic> channelData,
  }) async {
    try {
      List<List<String>> csvData = [];
      
      // Header
      csvData.add(['Restaurant Analytics Report']);
      csvData.add(['Generated:', DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())]);
      csvData.add(['Period:', timeFrame]);
      csvData.add([]);
      
      // KPI Section
      csvData.add(['Key Performance Indicators']);
      csvData.add(['Metric', 'Value', 'Change']);
      csvData.add(['Total Revenue', kpiData['revenue']!, kpiData['revenueChange']!]);
      csvData.add(['Total Orders', kpiData['orders']!, kpiData['ordersChange']!]);
      csvData.add(['Avg Order Value', kpiData['avgOrder']!, kpiData['avgOrderChange']!]);
      csvData.add(['Table Turnover Rate', kpiData['turnover']!, kpiData['turnoverChange']!]);
      csvData.add([]);
      
      // Revenue Trend
      csvData.add(['Revenue Trend']);
      csvData.add(['Total Revenue', chartData['totalRevenue']!]);
      csvData.add(['Change', chartData['change']!]);
      csvData.add([]);
      
      // Order Statistics
      csvData.add(['Order Statistics']);
      csvData.add(['Daily Orders', orderStats['dailyOrders']!]);
      csvData.add(['Change', orderStats['change']!]);
      csvData.add([]);
      
      // Order Channels
      csvData.add(['Order Channels Distribution']);
      csvData.add(['Channel', 'Percentage']);
      csvData.add(['Dine-in', '${channelData['dineIn'].toStringAsFixed(1)}%']);
      csvData.add(['Phone Order', '${channelData['phone'].toStringAsFixed(1)}%']);
      csvData.add(['Takeaway', '${channelData['takeaway'].toStringAsFixed(1)}%']);
      csvData.add([]);
      
      // Footer
      csvData.add(['Note: This report is generated from restaurant POS system analytics data.']);

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Check permissions
      if (Platform.isAndroid) {
        if (!await Permission.storage.request().isGranted) {
          return null;
        }
      }

      // Save file
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/analytics_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      
      return file;
    } catch (e) {
      debugPrint('CSV generation error: $e');
      return null;
    }
  }
}
