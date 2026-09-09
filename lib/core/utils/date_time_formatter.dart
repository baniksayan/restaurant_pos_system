class DateTimeFormatter {
  DateTimeFormatter._();

  /// Format relative elapsed time ("Just now", "5 min ago", "2h ago", or date string)
  static String formatRelative(
    DateTime dateTime, {
    bool includeDateForOlderDays = true,
  }) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0 && includeDateForOlderDays) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $hour:$minute';
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
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year}';
  }

  /// Format time as HH:MM
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format combined date and time
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
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
