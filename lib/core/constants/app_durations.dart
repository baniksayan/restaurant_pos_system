class AppDurations {
  AppDurations._();

  /// Quick feedback, button scale, ripple
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard micro-interaction, tab change, small fade
  static const Duration normal = Duration(milliseconds: 200);

  /// Moderate transition, modal dialog open, card expansion
  static const Duration medium = Duration(milliseconds: 300);

  /// Page transition, complex layout change
  static const Duration slow = Duration(milliseconds: 500);

  /// Splash / intro animation
  static const Duration animation = Duration(milliseconds: 800);

  /// Standard snackbar display duration
  static const Duration snackBar = Duration(seconds: 3);

  /// Extended snackbar display duration
  static const Duration snackBarLong = Duration(seconds: 4);
}
