import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/constants/app_strings.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import '../providers/dashboard_provider.dart';

/// Premium glassmorphic dialog for selecting an outlet / location.
///
/// Matches the app's signature glassmorphic design system:
/// frosted backdrop blur, translucent white card, and interactive frosted items.
class LocationSelectorDialog extends StatelessWidget {
  final List<LocationSection> locations;
  final String selectedLocation;
  final Function(String) onLocationChanged;
  final double? maxWidth;

  const LocationSelectorDialog({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationChanged,
    this.maxWidth,
  });

  /// Displays the glass-morphic location selector dialog with transparent barrier.
  static Future<void> show(
    BuildContext context, {
    required List<LocationSection> locations,
    required String selectedLocation,
    required Function(String) onLocationChanged,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return LocationSelectorDialog(
          locations: locations,
          selectedLocation: selectedLocation,
          onLocationChanged: onLocationChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogMaxWidth =
        maxWidth ?? (size.width < 480 ? size.width * 0.92 : 380.0);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Stack(
          children: [
            // Standard ambient backdrop blur & subtle dimming
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: dialogMaxWidth),
                    child: GestureDetector(
                      onTap: () {}, // Prevent taps inside the card from closing
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.52),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.75),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.storefront_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.dashboard
                                                  .selectLocation,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Select an outlet to work in',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        onTap: () => Navigator.pop(context),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: AppColors.textSecondary,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(
                                    height: 1,
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                  const SizedBox(height: 12),

                                  // Locations List
                                  Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: locations.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final location = locations[index];
                                        final isSelected =
                                            selectedLocation == location.name;

                                        return InkWell(
                                          onTap: () async {
                                            await HapticHelper
                                                .triggerFeedback();
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                            }
                                            onLocationChanged(location.name);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? location.color
                                                      .withValues(alpha: 0.12)
                                                  : Colors.white
                                                      .withValues(alpha: 0.40),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? location.color
                                                    : Colors.white.withValues(
                                                        alpha: 0.65,
                                                      ),
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                              boxShadow: [
                                                if (isSelected)
                                                  BoxShadow(
                                                    color: location.color
                                                        .withValues(alpha: 0.10),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 2),
                                                  ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? location.color
                                                        : location.color
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                    borderRadius:
                                                      BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    location.icon,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : location.color,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        location.name,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w700
                                                              : FontWeight.w600,
                                                          color: isSelected
                                                              ? location.color
                                                              : AppColors
                                                                  .textPrimary,
                                                        ),
                                                      ),
                                                      if (location.address !=
                                                              null &&
                                                          location.address!
                                                              .trim()
                                                              .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          location.address!
                                                              .trim(),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11.5,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    color: location.color,
                                                    size: 20,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
