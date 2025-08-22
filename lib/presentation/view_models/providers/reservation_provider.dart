// lib/presentation/view_models/providers/reservation_provider.dart
import 'package:flutter/material.dart';
import '../../../data/models/reservation.dart';

class ReservationProvider extends ChangeNotifier {
  final List<Reservation> _reservations = [];

  List<Reservation> get reservations => _reservations;

  // Pricing logic with enhanced rates
  static const Map<String, double> _timeSlotRates = {
    'morning': 250.0, // 6AM-12PM
    'afternoon': 350.0, // 12PM-6PM
    'evening': 600.0, // 6PM-12AM
  };

  static const Map<String, double> _occasionMultipliers = {
    'Birthday': 1.2,
    'Anniversary': 1.3,
    'Ceremony': 1.5,
    'Party': 1.5,
    'Other': 1.0,
  };

  String _getTimeSlot(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    return 'evening';
  }

  double calculatePrice({
    required DateTime fromTime,
    required DateTime toTime,
    required String occasion,
    bool decoration = false,
  }) {
    final duration = toTime.difference(fromTime);
    final durationInHours = duration.inMinutes / 60.0;

    final timeSlot = _getTimeSlot(fromTime);
    final baseRate = _timeSlotRates[timeSlot] ?? 350.0;
    final occasionMultiplier = _occasionMultipliers[occasion] ?? 1.0;

    double basePrice = durationInHours * baseRate;
    double finalPrice = basePrice * occasionMultiplier;

    if (decoration) {
      finalPrice += 500.0; // Decoration charge
    }

    return finalPrice;
  }

  bool isTableAvailable({
    required String tableId,
    required DateTime fromTime,
    required DateTime toTime,
  }) {
    for (final reservation in _reservations) {
      if (reservation.tableId == tableId && reservation.status == 'confirmed') {
        // Check for overlap
        if ((fromTime.isBefore(reservation.toTime) &&
            toTime.isAfter(reservation.fromTime))) {
          return false;
        }
      }
    }
    return true;
  }

  String? validateReservationTime({
    required DateTime fromTime,
    required DateTime toTime,
  }) {
    final now = DateTime.now();
    final minLeadTime = now.add(const Duration(hours: 2));
    final maxTime = DateTime(now.year, now.month, now.day, 23, 59);

    if (fromTime.isBefore(minLeadTime)) {
      return 'Reservation must be made at least 2 hours in advance';
    }

    if (toTime.isAfter(maxTime)) {
      return 'Reservation cannot exceed restaurant closing time (12:00 AM)';
    }

    final duration = toTime.difference(fromTime);
    if (duration.inMinutes < 30) {
      return 'Minimum reservation duration is 30 minutes';
    }

    if (duration.inHours > 6) {
      return 'Maximum reservation duration is 6 hours';
    }

    return null;
  }

  Future<bool> addReservation(Reservation reservation) async {
    if (!isTableAvailable(
      tableId: reservation.tableId,
      fromTime: reservation.fromTime,
      toTime: reservation.toTime,
    )) {
      return false;
    }

    _reservations.add(reservation);
    notifyListeners();

    // TODO: In real app, save to API/database here
    print('Reservation saved: ${reservation.toJson()}');

    return true;
  }

  void removeReservation(String reservationId) {
    _reservations.removeWhere((r) => r.id == reservationId);
    notifyListeners();
  }

  List<Reservation> getReservationsForTable(String tableId) {
    return _reservations.where((r) => r.tableId == tableId).toList();
  }
}
