import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticHelper {
  static Future<void> triggerFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 50);
      }
      await HapticFeedback.lightImpact();
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }
}
