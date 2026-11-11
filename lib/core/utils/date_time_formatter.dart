class DateTimeFormatter {
  DateTimeFormatter._();

  /// Format relative elapsed time ("Just now", "5 min ago", "2h ago", or date string)
  static String formatRelative(
    DateTime dateTime, {
    bool includeDateForOlderDays = true,
  }) {
    final now = DateTime.now();
    final localDt = dateTime.isUtc ? dateTime.toLocal() : dateTime;

    // If the date has no real time (midnight 00:00:00), do NOT say "12h ago"
    if (localDt.hour == 0 && localDt.minute == 0 && localDt.second == 0) {
      final isToday = now.year == localDt.year &&
          now.month == localDt.month &&
          now.day == localDt.day;
      if (isToday) return 'Today';
      return formatDate(localDt);
    }

    final difference = now.difference(localDt);

    if (difference.inDays > 0 && includeDateForOlderDays) {
      final hour = localDt.hour.toString().padLeft(2, '0');
      final minute = localDt.minute.toString().padLeft(2, '0');
      final day = localDt.day.toString().padLeft(2, '0');
      final month = localDt.month.toString().padLeft(2, '0');
      return '$day/$month/${localDt.year} at $hour:$minute';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  /// Format date as DD/MM/YYYY
  static String formatDate(DateTime dateTime) {
    final dt = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  /// Format time as hh:mm AM/PM
  static String formatTime(DateTime dateTime) {
    final dt = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  /// Format combined date and time.
  /// If the date has no real time (midnight 00:00:00), only the date is returned,
  /// preventing misleading "at 0:00" output.
  static String formatDateTime(DateTime dateTime) {
    final dt = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    if (dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
      return formatDate(dt);
    }
    return '${formatDate(dt)} at ${formatTime(dt)}';
  }

  /// Safely parse date and time from various formats returned by backend APIs
  /// (ISO-8601 with/without timezone or Z, dd/MM/yyyy HH:mm:ss, etc.)
  /// and convert to local device time.
  static DateTime? parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.isUtc ? raw.toLocal() : raw;
    final text = raw.toString().trim();
    if (text.isEmpty || text == 'null') return null;

    // 1. Check for dd/MM/yyyy or dd-MM-yyyy format:
    // e.g. "10/11/2026, 11:30:00", "10/11/2026 11:30:00", "10-11-2026"
    final dmyMatch = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:,?\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(text);
    if (dmyMatch != null) {
      final day = int.parse(dmyMatch.group(1)!);
      final month = int.parse(dmyMatch.group(2)!);
      final year = int.parse(dmyMatch.group(3)!);
      final hour = int.tryParse(dmyMatch.group(4) ?? '0') ?? 0;
      final minute = int.tryParse(dmyMatch.group(5) ?? '0') ?? 0;
      final second = int.tryParse(dmyMatch.group(6) ?? '0') ?? 0;
      return DateTime(year, month, day, hour, minute, second);
    }

    // 2. Standard ISO-8601 parsing (handles "2026-11-10T06:16:58Z", etc.)
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }

    return null;
  }

  /// Combine customer first, middle and last names or fallback to raw customer name.
  /// Prevents dropping the last name when the backend provides separate or partial fields.
  static String resolveCustomerName(Map<String, dynamic> json) {
    String findVal(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) {
          final s = v.toString().trim();
          if (s.isNotEmpty && s != 'null') return s;
        }
      }
      return '';
    }

    final rawName = findVal([
      'customerFullName', 'custFullName', 'customer_full_name',
      'customerName', 'custName', 'customer_name', 'cust_name',
      'partyName', 'clientName'
    ]);

    final firstName = findVal([
      'customerFirstName', 'custFirstName', 'firstName',
      'customer_first_name', 'cust_first_name', 'first_name'
    ]);

    final middleName = findVal([
      'customerMiddleName', 'custMiddleName', 'middleName',
      'customer_middle_name', 'cust_middle_name'
    ]);

    final lastName = findVal([
      'customerLastName', 'custLastName', 'lastName',
      'customer_last_name', 'cust_last_name', 'last_name'
    ]);

    final assembledParts = [firstName, middleName, lastName]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    if (assembledParts.isNotEmpty) {
      if (rawName.isEmpty ||
          rawName.toLowerCase() == 'walk-in' ||
          rawName.toLowerCase() == 'walk-in customer' ||
          rawName.toLowerCase() == 'walk-in guest') {
        return assembledParts;
      }
      if (lastName.isNotEmpty &&
          !rawName.toLowerCase().contains(lastName.toLowerCase())) {
        return '$rawName $lastName'.trim();
      }
      return rawName.length >= assembledParts.length ? rawName : assembledParts;
    }

    return rawName;
  }
}

extension DateTimeFormattingExtension on DateTime {
  String timeAgo({bool includeDateForOlderDays = true}) =>
      DateTimeFormatter.formatRelative(
        this,
        includeDateForOlderDays: includeDateForOlderDays,
      );

  String toFormattedDate() => DateTimeFormatter.formatDate(this);
  String toFormattedTime() => DateTimeFormatter.formatTime(this);
}
