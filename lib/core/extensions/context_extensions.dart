import 'package:flutter/material.dart';
import '../constants/app_breakpoints.dart';
import '../utils/snackbar_helper.dart';

extension ContextExtensions on BuildContext {
  // Theme & Styling
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // Media Query & Dimensions
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // Responsive Breakpoint Queries
  bool get isTablet => screenWidth >= AppBreakpoints.tablet;
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;
  bool get isMobile => screenWidth < AppBreakpoints.tablet;

  // Snackbars
  void showSuccessSnackBar(String message) =>
      AppSnackBar.showSuccess(this, message);
  void showErrorSnackBar(String message) =>
      AppSnackBar.showError(this, message);
  void showInfoSnackBar(String message) => AppSnackBar.showInfo(this, message);
  void showWarningSnackBar(String message) =>
      AppSnackBar.showWarning(this, message);
}
