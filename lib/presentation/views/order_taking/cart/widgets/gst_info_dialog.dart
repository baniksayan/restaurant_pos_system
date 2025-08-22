import 'package:flutter/material.dart';

class GSTInfoDialog extends StatelessWidget {
  const GSTInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info, color: Colors.blue),
          SizedBox(width: 8),
          Text('GST Information'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant GST Details:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('• GST Rate: 18% (Pre-defined)'),
          Text('• Applied to all food items'),
          Text('• Inclusive in final amount'),
          SizedBox(height: 12),
          Card(
            color: Color(0xFFE8F5E8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'This is a standard restaurant GST rate as per regulations.',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
