import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Horizontal spacing widgets
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);

  // Vertical spacing widgets
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox vXxl = SizedBox(height: xxl);

  // Common edge insets
  static const EdgeInsets pAllXs = EdgeInsets.all(xs);
  static const EdgeInsets pAllSm = EdgeInsets.all(sm);
  static const EdgeInsets pAllMd = EdgeInsets.all(md);
  static const EdgeInsets pAllLg = EdgeInsets.all(lg);
  static const EdgeInsets pAllXl = EdgeInsets.all(xl);

  static const EdgeInsets pHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets pHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pHLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets pVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets pVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets pVLg = EdgeInsets.symmetric(vertical: lg);

  // Semantic Insets
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const EdgeInsets card = EdgeInsets.all(16);
  static const EdgeInsets cardLg = EdgeInsets.all(20);
  static const EdgeInsets dialog = EdgeInsets.all(20);
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  );
}
