import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import '../providers/dashboard_provider.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class LocationSelectorDialog extends StatelessWidget {
  final List<LocationSection> locations;
  final String selectedLocation;
  final Function(String) onLocationChanged;

  const LocationSelectorDialog({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(AppStrings.dashboard.selectLocation),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final location = locations[index];
            final isSelected = selectedLocation == location.name;

            return ListTile(
              leading: Icon(
                location.icon,
                color: isSelected ? AppColors.primary : location.color,
              ),
              title: Text(
                location.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
              trailing:
                  isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
              selected: isSelected,
              onTap: () {
                onLocationChanged(location.name);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }
}
