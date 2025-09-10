import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/themes/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetTime;
  final String label;

  const CountdownTimer({
    super.key,
    required this.targetTime,
    this.label = '',
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.targetTime.difference(now);
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining == Duration.zero) {
        _timer?.cancel();
      } else {
        _updateRemaining();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    
    Color timerColor = _remaining > const Duration(minutes: 5) 
        ? AppColors.success 
        : _remaining > const Duration(minutes: 2)
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: timerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: timerColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${widget.label.isNotEmpty ? '${widget.label}: ' : ''}$minutes:$seconds',
            style: TextStyle(
              color: timerColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
