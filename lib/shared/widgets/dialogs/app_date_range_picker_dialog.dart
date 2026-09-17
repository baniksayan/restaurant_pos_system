import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';

/// A premium, reusable modal/popup-style Date Range Picker dialog for WhizEats.
///
/// Features:
/// - Constrained date range (defaults to past 6 months up to today).
/// - Future dates are disabled and non-selectable.
/// - Opens as a centered modal popup with tap-outside-to-close behavior.
/// - Continuous, connected range styling with rounded start, end, and weekly row boundaries.
/// - Quick preset filter chips (Today, Last 7 Days, Last 30 Days, This Month, Last 6 Months).
/// - Dynamic date selection summary header and clean action buttons.
class AppDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDateRangePickerDialog({
    super.key,
    this.initialRange,
    this.firstDate,
    this.lastDate,
  });

  /// Convenience method to display the popup modal date range picker.
  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final now = DateTime.now();
    final effectiveFirst = firstDate ??
        DateTime(now.year, now.month - 6, now.day);
    final effectiveLast = lastDate ??
        DateTime(now.year, now.month, now.day);

    return showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => AppDateRangePickerDialog(
        initialRange: initialRange,
        firstDate: effectiveFirst,
        lastDate: effectiveLast,
      ),
    );
  }

  @override
  State<AppDateRangePickerDialog> createState() =>
      _AppDateRangePickerDialogState();
}

class _AppDateRangePickerDialogState extends State<AppDateRangePickerDialog> {
  late DateTime _firstDate;
  late DateTime _lastDate;
  late DateTime _currentMonth;

  DateTime? _startDate;
  DateTime? _endDate;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekDays = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _firstDate = widget.firstDate ?? DateTime(now.year, now.month - 6, now.day);
    _lastDate = widget.lastDate ?? today;

    // Ensure _lastDate cannot be in the future beyond today
    if (_lastDate.isAfter(today)) {
      _lastDate = today;
    }

    if (widget.initialRange != null) {
      _startDate = DateTime(
        widget.initialRange!.start.year,
        widget.initialRange!.start.month,
        widget.initialRange!.start.day,
      );
      _endDate = DateTime(
        widget.initialRange!.end.year,
        widget.initialRange!.end.month,
        widget.initialRange!.end.day,
      );
      _currentMonth = DateTime(_startDate!.year, _startDate!.month, 1);
    } else {
      _startDate = today;
      _endDate = today;
      _currentMonth = DateTime(today.year, today.month, 1);
    }
  }

  bool _isDateDisabled(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final first = DateTime(_firstDate.year, _firstDate.month, _firstDate.day);
    final last = DateTime(_lastDate.year, _lastDate.month, _lastDate.day);
    return d.isBefore(first) || d.isAfter(last);
  }

  void _onDateTapped(DateTime date) {
    if (_isDateDisabled(date)) return;

    setState(() {
      final selected = DateTime(date.year, date.month, date.day);

      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start a new range selection
        _startDate = selected;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (selected.isBefore(_startDate!)) {
          // If clicked date is earlier than start date, make it the new start
          _startDate = selected;
        } else {
          // Complete the range
          _endDate = selected;
        }
      }
    });
  }

  void _applyPreset(DateTime start, DateTime end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var effectiveStart = start;
    var effectiveEnd = end;

    if (effectiveStart.isBefore(_firstDate)) effectiveStart = _firstDate;
    if (effectiveEnd.isAfter(_lastDate)) effectiveEnd = _lastDate;
    if (effectiveEnd.isAfter(today)) effectiveEnd = today;

    setState(() {
      _startDate = effectiveStart;
      _endDate = effectiveEnd;
      _currentMonth = DateTime(effectiveEnd.year, effectiveEnd.month, 1);
    });
  }

  void _prevMonth() {
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    final minMonth = DateTime(_firstDate.year, _firstDate.month, 1);
    if (!prev.isBefore(minMonth)) {
      setState(() => _currentMonth = prev);
    }
  }

  void _nextMonth() {
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final maxMonth = DateTime(_lastDate.year, _lastDate.month, 1);
    if (!next.isAfter(maxMonth)) {
      setState(() => _currentMonth = next);
    }
  }

  bool get _canGoPrev {
    final minMonth = DateTime(_firstDate.year, _firstDate.month, 1);
    final prev = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    return !prev.isBefore(minMonth);
  }

  bool get _canGoNext {
    final maxMonth = DateTime(_lastDate.year, _lastDate.month, 1);
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return !next.isAfter(maxMonth);
  }

  String _formatRangeSummary() {
    if (_startDate == null) return 'Select date range';
    final s = '${_startDate!.day} ${_monthNames[_startDate!.month - 1].substring(0, 3)} ${_startDate!.year}';
    if (_endDate == null || _startDate == _endDate) {
      return s;
    }
    final e = '${_endDate!.day} ${_monthNames[_endDate!.month - 1].substring(0, 3)} ${_endDate!.year}';
    return '$s  →  $e';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Tap outside listener wrapped around the entire presentation
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Block tap inside dialog card from dismissing
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header: Title & Close Button ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.date_range_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Date Range',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatRangeSummary(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _startDate != null
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: const Color(0xFF94A3B8),
                            onPressed: () => Navigator.pop(context),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // ── Quick Presets Scrollable Row ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildPresetChip(
                              'Today',
                              () => _applyPreset(today, today),
                            ),
                            const SizedBox(width: 6),
                            _buildPresetChip(
                              'Last 7 Days',
                              () => _applyPreset(
                                today.subtract(const Duration(days: 6)),
                                today,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildPresetChip(
                              'Last 30 Days',
                              () => _applyPreset(
                                today.subtract(const Duration(days: 29)),
                                today,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildPresetChip(
                              'This Month',
                              () => _applyPreset(
                                DateTime(today.year, today.month, 1),
                                today,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildPresetChip(
                              'Last 6 Months',
                              () => _applyPreset(_firstDate, today),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Month Navigator ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 22,
                            ),
                            color: _canGoPrev
                                ? AppColors.textPrimary
                                : const Color(0xFFCBD5E1),
                            onPressed: _canGoPrev ? _prevMonth : null,
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Text(
                            '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                            ),
                            color: _canGoNext
                                ? AppColors.textPrimary
                                : const Color(0xFFCBD5E1),
                            onPressed: _canGoNext ? _nextMonth : null,
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Days of Week Row ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Row(
                        children: _weekDays.map((d) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Calendar Grid ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                      child: _buildDaysGrid(),
                    ),

                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // ── Bottom Action Buttons ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              onPressed: _startDate != null
                                  ? () {
                                      final start = _startDate!;
                                      final end = _endDate ?? _startDate!;
                                      Navigator.pop(
                                        context,
                                        DateTimeRange(start: start, end: end),
                                      );
                                    }
                                  : null,
                              child: const Text(
                                'Apply Range',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysGrid() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // DateTime.weekday: 1 = Monday, 7 = Sunday
    final leadingEmpty = firstDayOfMonth.weekday - 1;

    final totalCells = leadingEmpty + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final hasFullRange = _startDate != null &&
        _endDate != null &&
        _endDate!.isAfter(_startDate!);

    final stripColor = AppColors.primary.withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rowCount, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - leadingEmpty + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 34));
              }

              final cellDate = DateTime(year, month, dayNumber);
              final isDisabled = _isDateDisabled(cellDate);
              final isToday = cellDate == today;

              final isStart = _startDate != null && cellDate == _startDate;
              final isEnd = _endDate != null && cellDate == _endDate;
              final isInRange = _startDate != null &&
                  _endDate != null &&
                  cellDate.isAfter(_startDate!) &&
                  cellDate.isBefore(_endDate!);

              final isRowStart = colIndex == 0 || dayNumber == 1;
              final isRowEnd = colIndex == 6 || dayNumber == daysInMonth;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onDateTapped(cellDate),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // ── Layer 1: Seamless Continuous Range Strip ──
                        if (hasFullRange)
                          if (isInRange)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: stripColor,
                                  borderRadius: BorderRadius.horizontal(
                                    left: isRowStart
                                        ? const Radius.circular(17)
                                        : Radius.zero,
                                    right: isRowEnd
                                        ? const Radius.circular(17)
                                        : Radius.zero,
                                  ),
                                ),
                              ),
                            )
                          else if (isStart)
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              left: 17,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: stripColor,
                                  borderRadius: BorderRadius.horizontal(
                                    right: isRowEnd
                                        ? const Radius.circular(17)
                                        : Radius.zero,
                                  ),
                                ),
                              ),
                            )
                          else if (isEnd)
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: 0,
                              right: 17,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: stripColor,
                                  borderRadius: BorderRadius.horizontal(
                                    left: isRowStart
                                        ? const Radius.circular(17)
                                        : Radius.zero,
                                  ),
                                ),
                              ),
                            ),

                        // ── Layer 2: Day Number Circle ──
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isStart || isEnd)
                                ? AppColors.primary
                                : Colors.transparent,
                            border: isToday && !isStart && !isEnd
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: (isStart || isEnd || isToday)
                                    ? FontWeight.w800
                                    : (isInRange
                                        ? FontWeight.w700
                                        : FontWeight.w600),
                                color: isDisabled
                                    ? const Color(0xFFCBD5E1)
                                    : (isStart || isEnd)
                                        ? Colors.white
                                        : (isInRange || isToday)
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
