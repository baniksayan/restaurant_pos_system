import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../../view_models/providers/billing_provider.dart';

class CustomerPhoneCard extends StatefulWidget {
  final TextEditingController phoneController;
  final GlobalKey<FormState> formKey;

  const CustomerPhoneCard({
    super.key,
    required this.phoneController,
    required this.formKey,
  });

  @override
  State<CustomerPhoneCard> createState() => _CustomerPhoneCardState();
}

class _CustomerPhoneCardState extends State<CustomerPhoneCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter phone number to send e-bill (optional)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Consumer<BillingProvider>(
            builder: (context, billingProvider, child) {
              return IntlPhoneField(
                controller: widget.phoneController,
                initialCountryCode: 'IN',
                decoration: const InputDecoration(
                  labelText: 'Customer Phone Number',
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                showCountryFlag: true,
                showDropdownIcon: true,
                onChanged: (phone) {
                  billingProvider.setCustomerPhone(phone.completeNumber);
                  billingProvider.setCountryCode(phone.countryCode);
                },
                validator: (value) {
                  if (value != null &&
                      value.number.isNotEmpty &&
                      value.number.length < 7) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
