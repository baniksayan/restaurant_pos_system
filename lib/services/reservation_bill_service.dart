import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/reservation.dart';

class ReservationBillService {
  static String generateBillNumber() {
    final now = DateTime.now();
    return 'RSV${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  // Generate PDF bill instead of text
  static Future<File> generateAdvanceBillPDF(Reservation reservation) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'WiZARD RESTAURANT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'TABLE RESERVATION BILL',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Bill Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                    pw.Text('Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text('Bill No: ${reservation.billNumber}', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                
                pw.SizedBox(height: 20),
                
                // Customer Details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER DETAILS', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text('Name: ${reservation.customerName}'),
                      pw.Text('Phone: ${reservation.customerPhone}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                // Reservation Details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('RESERVATION DETAILS', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text('Table: ${reservation.tableName}'),
                      pw.Text('Persons: ${reservation.persons}'),
                      pw.Text('Occasion: ${reservation.occasion}'),
                      pw.Text('From: ${reservation.fromTime.day}/${reservation.fromTime.month}/${reservation.fromTime.year} ${reservation.fromTime.hour}:${reservation.fromTime.minute.toString().padLeft(2, '0')}'),
                      pw.Text('To: ${reservation.toTime.day}/${reservation.toTime.month}/${reservation.toTime.year} ${reservation.toTime.hour}:${reservation.toTime.minute.toString().padLeft(2, '0')}'),
                      pw.Text('Duration: ${reservation.duration.inHours}h ${reservation.duration.inMinutes % 60}m'),
                      if (reservation.specialNotes != null && reservation.specialNotes!.isNotEmpty)
                        pw.Text('Special Notes: ${reservation.specialNotes}'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                // Pricing Table
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          borderRadius: pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(8),
                            topRight: pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text('PRICING DETAILS', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Column(
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Base Amount:'),
                                pw.Text('₹${reservation.basePrice.toStringAsFixed(0)}'),
                              ],
                            ),
                            if (reservation.decoration) ...[
                              pw.SizedBox(height: 5),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Table Decoration:'),
                                  pw.Text('₹500'),
                                ],
                              ),
                            ],
                            pw.SizedBox(height: 10),
                            pw.Divider(),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Total Amount:', 
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                                pw.Text('₹${reservation.finalPrice.toStringAsFixed(0)}', 
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            pw.SizedBox(height: 10),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Advance Paid:', 
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                                pw.Text('₹${reservation.advanceAmount.toStringAsFixed(0)}', 
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Remaining:', 
                                  style: pw.TextStyle(color: PdfColors.red800)),
                                pw.Text('₹${reservation.remainingAmount.toStringAsFixed(0)}', 
                                  style: pw.TextStyle(color: PdfColors.red800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Payment Status
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('ADVANCE PAYMENT RECEIVED', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                      pw.SizedBox(height: 5),
                      pw.Text('Please arrive on time for your reservation'),
                      pw.Text('Remaining amount to be paid at the restaurant'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Important Notes
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    border: pw.Border.all(color: PdfColors.orange300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('IMPORTANT NOTES', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('• Please arrive 15 minutes early'),
                      pw.Text('• Advance amount is non-refundable'),
                      pw.Text('• Table will be held for 15 minutes only'),
                      pw.Text('• For changes, call: +91-8768412832'),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Thank You for Choosing', 
                        style: pw.TextStyle(fontSize: 12)),
                      pw.Text('WiZARD RESTAURANT', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    
    // Save to temporary directory
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reservation_bill_${reservation.billNumber}.pdf');
    await file.writeAsBytes(bytes);
    
    return file;
  }

  // Share PDF file to WhatsApp
  static Future<void> shareAdvanceBillToWhatsApp(Reservation reservation, File pdfFile) async {
    try {
      final message = '''*Table Reservation Confirmed!*

Dear ${reservation.customerName},

Your table reservation has been confirmed at *WiZARD Restaurant*

*Reservation Details:*
• Table: ${reservation.tableName}
• Date & Time: ${reservation.fromTime.day}/${reservation.fromTime.month} at ${reservation.fromTime.hour}:${reservation.fromTime.minute.toString().padLeft(2, '0')}
• Duration: ${reservation.duration.inHours}h ${reservation.duration.inMinutes % 60}m
• Persons: ${reservation.persons}

*Payment Summary:*
• Total Amount: ₹${reservation.finalPrice.toStringAsFixed(0)}
• Advance Paid: ₹${reservation.advanceAmount.toStringAsFixed(0)}
• Remaining: ₹${reservation.remainingAmount.toStringAsFixed(0)}

For any changes, call: +91-8768412832

Thank you for choosing WiZARD Restaurant!''';

      // Share PDF file with WhatsApp
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: message,
        subject: 'Table Reservation Bill - ${reservation.billNumber}',
      );

    } catch (e) {
      print('Error sharing to WhatsApp: $e');
      throw e;
    }
  }

  // Alternative method to share directly to specific WhatsApp number
  static Future<bool> shareToSpecificWhatsAppNumber(
    Reservation reservation, 
    File pdfFile
  ) async {
    try {
      // First method: Use Share with WhatsApp specific intent (Android)
      if (Platform.isAndroid) {
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          text: 'Your reservation bill from WiZARD Restaurant',
          subject: 'Table Reservation Bill',
        );
        return true;
      }
      
      // For iOS or if direct sharing fails, copy file and open WhatsApp
      final message = Uri.encodeComponent(
        'Dear ${reservation.customerName}, your table reservation is confirmed! Check the attached bill. Total: ₹${reservation.finalPrice.toStringAsFixed(0)}, Advance: ₹${reservation.advanceAmount.toStringAsFixed(0)}'
      );
      
      final phoneNumber = reservation.customerPhone.startsWith('+91') 
          ? reservation.customerPhone.substring(3)
          : reservation.customerPhone;
      
      final whatsappUrl = 'https://wa.me/+91$phoneNumber?text=$message';
      
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        
        // Also trigger file sharing separately
        await Share.shareXFiles([XFile(pdfFile.path)]);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error sharing to specific WhatsApp number: $e');
      return false;
    }
  }
}
