import 'package:flutter/material.dart';

/// Centralized semantic application icons.
/// Keeps business-critical and navigation icons visually uniform across features.
class AppIcons {
  AppIcons._();

  // Navigation & Actions
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData remove = Icons.remove_rounded;
  static const IconData check = Icons.check_circle_rounded;
  static const IconData print = Icons.print_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData filter = Icons.filter_list_rounded;

  // Domain & Feature Semantics
  static const IconData table = Icons.table_restaurant_rounded;
  static const IconData cart = Icons.shopping_cart_outlined;
  static const IconData kitchen = Icons.soup_kitchen_rounded;
  static const IconData bill = Icons.receipt_long_rounded;
  static const IconData cash = Icons.payments_outlined;
  static const IconData qrCode = Icons.qr_code_2_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;
}
