// lib/presentation/views/profile/widgets/printer_settings_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';

class PrinterSettingsDialog extends StatefulWidget {
  const PrinterSettingsDialog({super.key});

  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> {
  String _selectedConnection = 'WiFi';
  bool _receiptPrinterEnabled = true;
  bool _kitchenPrinterEnabled = false;
  String _printerStatus = 'Disconnected';
  
  final List<String> _connectionTypes = ['WiFi', 'Bluetooth', 'USB'];
  final List<Map<String, dynamic>> _availablePrinters = [
    {'name': 'HP LaserJet Pro', 'type': 'WiFi', 'status': 'Available'},
    {'name': 'Epson TM-T20III', 'type': 'Bluetooth', 'status': 'Available'},
    {'name': 'Canon PIXMA', 'type': 'WiFi', 'status': 'Offline'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.print,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Printer Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection Type
                    const Text(
                      'Connection Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedConnection,
                          isExpanded: true,
                          onChanged: (value) {
                            setState(() {
                              _selectedConnection = value!;
                            });
                          },
                          items: _connectionTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    type == 'WiFi' ? Icons.wifi :
                                    type == 'Bluetooth' ? Icons.bluetooth :
                                    Icons.usb,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Printer Types
                    const Text(
                      'Printer Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: const Row(
                        children: [
                          Icon(Icons.receipt, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Receipt Printer'),
                        ],
                      ),
                      subtitle: const Text('Print customer bills and receipts'),
                      value: _receiptPrinterEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _receiptPrinterEnabled = value;
                        });
                      },
                    ),
                    
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      title: const Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Kitchen Printer'),
                        ],
                      ),
                      subtitle: const Text('Print KOT (Kitchen Order Tickets)'),
                      value: _kitchenPrinterEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _kitchenPrinterEnabled = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Available Printers
                    const Text(
                      'Available Printers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _availablePrinters.map((printer) {
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: printer['status'] == 'Available' 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.print,
                                color: printer['status'] == 'Available' 
                                    ? Colors.green 
                                    : Colors.red,
                                size: 20,
                              ),
                            ),
                            title: Text(printer['name']),
                            subtitle: Text('${printer['type']} • ${printer['status']}'),
                            trailing: printer['status'] == 'Available'
                                ? ElevatedButton(
                                    onPressed: () => _connectPrinter(printer['name']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text('Connect'),
                                  )
                                : const Text(
                                    'Offline',
                                    style: TextStyle(color: Colors.red),
                                  ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Test Print Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _testPrint,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Test Print'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _connectPrinter(String printerName) {
    setState(() {
      _printerStatus = 'Connected to $printerName';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected to $printerName'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _testPrint() {
    if (_printerStatus == 'Disconnected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please connect a printer first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test print sent successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveSettings() {
    // Here you would save the printer settings to your backend/local storage
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Printer settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
