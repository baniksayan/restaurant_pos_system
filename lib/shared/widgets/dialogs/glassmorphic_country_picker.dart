import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/helpers.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';

/// Ultra-premium frosted glassmorphism country selector dialog.
///
/// Features a blurred backdrop, translucent frosted card, search bar with
/// instant filtering by name or dial code, flag container, dial code pill
/// badges, and active selection indicator.
class GlassmorphicCountryPicker extends StatefulWidget {
  final Country selectedCountry;
  final String? languageCode;

  const GlassmorphicCountryPicker({
    super.key,
    required this.selectedCountry,
    this.languageCode,
  });

  /// Presents the frosted glassmorphism country picker dialog.
  static Future<Country?> show(
    BuildContext context, {
    required Country selectedCountry,
    String? languageCode,
  }) {
    return showGeneralDialog<Country>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Country Picker',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return GlassmorphicCountryPicker(
          selectedCountry: selectedCountry,
          languageCode: languageCode,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GlassmorphicCountryPicker> createState() =>
      _GlassmorphicCountryPickerState();
}

class _GlassmorphicCountryPickerState extends State<GlassmorphicCountryPicker> {
  final _searchController = TextEditingController();
  late List<Country> _allCountries;
  late List<Country> _filteredCountries;
  late Country _currentSelected;

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedCountry;
    _allCountries = countries.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _filteredCountries = _allCountries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _filteredCountries = _allCountries);
    } else {
      setState(() {
        _filteredCountries = _allCountries.stringSearch(trimmed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Frosted Backdrop Blur
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticHelper.triggerFeedback();
                Navigator.of(context).pop();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),

          // Centered Glass Modal Card
          SafeArea(
            child: Center(
              child: Container(
                width: isTablet ? 480 : min(size.width * 0.92, 420),
                height: min(size.height * 0.82, 640),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.90),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Glass Header
                          _buildHeader(context),

                          // Search Bar
                          _buildSearchBar(),

                          // Country List View
                          Expanded(child: _buildCountryList()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.40),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Globe Icon Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.public_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Context Subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Choose dial code for phone number',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () {
              HapticHelper.triggerFeedback();
              Navigator.of(context).pop();
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.05),
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search country or dial code (e.g. +91)...',
          hintStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.70),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.85),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryList() {
    if (_filteredCountries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 26,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Countries Found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try searching by country name or dial code',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: _filteredCountries.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.80),
        indent: 12,
        endIndent: 12,
      ),
      itemBuilder: (context, index) {
        final country = _filteredCountries[index];
        final isSelected = country.code == _currentSelected.code;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticHelper.triggerFeedback();
              Navigator.of(context).pop(country);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Flag Container
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.35)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Country Name & ISO Code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          country.code,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Dial Code Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.5,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '+${country.dialCode}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),

                  // Checkmark Indicator
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
