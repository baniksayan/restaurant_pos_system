import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/app_durations.dart';

/// Reusable utility to debounce rapid invocations (e.g. search input)
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = AppDurations.medium});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
