import 'package:flutter/material.dart';

/// Holds only break status — the waiter's identity/name/phone comes straight
/// from the cached login response (see ProfileHeader) rather than from here.
/// This previously also carried a WaiterProfile/stats/achievements model
/// filled with sample data ("Rajesh Kumar", fake sales figures); nothing in
/// the UI ever read it and no backend endpoint backs those figures, so it
/// was removed rather than left as dead fabricated data.
class ProfileProvider extends ChangeNotifier {
  bool _isOnBreak = false;
  DateTime? _breakStartTime;

  bool get isOnBreak => _isOnBreak;
  DateTime? get breakStartTime => _breakStartTime;

  void toggleBreakStatus() {
    _isOnBreak = !_isOnBreak;
    _breakStartTime = _isOnBreak ? DateTime.now() : null;
    notifyListeners();
  }

  void logout() {
    _isOnBreak = false;
    _breakStartTime = null;
    notifyListeners();
  }
}
