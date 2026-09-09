import 'package:restaurant_pos_system/core/constants/app_strings.dart';

class AppValidators {
  AppValidators._();

  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static final RegExp _indianMobilePrefixRegex = RegExp(r'^[6-9]');

  /// Validates that a string is not null or empty
  static String? required(String? value, [String fieldName = 'field']) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Validates customer or user name (minimum 2 characters)
  static String? name(String? value, [String fieldName = 'name']) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    if (value.trim().length < 2) {
      return AppStrings.validation.nameTooShort;
    }
    return null;
  }

  /// Validates standard 10-digit Indian mobile number format
  static String? indianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validation.enterPhoneNumber;
    }
    final trimmed = value.trim();
    if (trimmed.length != 10) {
      return AppStrings.validation.phoneMustBeTenDigits;
    }
    if (!_indianMobilePrefixRegex.hasMatch(trimmed)) {
      return AppStrings.validation.phoneMustStartWith;
    }
    return null;
  }

  /// General phone validator with minimum length check
  static String? phone(String? value, {int minLength = 7}) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validation.enterPhoneNumber;
    }
    if (value.trim().length < minLength) {
      return AppStrings.validation.enterValidPhone;
    }
    return null;
  }

  /// Standard email validator
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validation.enterEmail;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return AppStrings.validation.enterValidEmail;
    }
    return null;
  }
}
