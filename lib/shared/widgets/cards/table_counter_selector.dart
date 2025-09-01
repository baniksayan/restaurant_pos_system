import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class TableCounterSelector extends StatefulWidget {
  final int count;
  final ValueChanged<int> onChanged;
  final bool isSelected;

  const TableCounterSelector({
    Key? key,
    required this.count,
    required this.onChanged,
    required this.isSelected,
  }) : super(key: key);

  @override
  State<TableCounterSelector> createState() => _TableCounterSelectorState();
}

class _TableCounterSelectorState extends State<TableCounterSelector> {
  late int _counter;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _counter = widget.count;
  }

  void _increment() async {
    await _vibrate();
    setState(() {
      _counter++;
      widget.onChanged(_counter);
    });
  }

  void _decrement() async {
    await _vibrate();
    if (_counter > 1) {
      setState(() {
        _counter--;
        widget.onChanged(_counter);
      });
    }
  }

  void _expand() async {
    await _vibrate();
    setState(() {
      _expanded = true;
      if (_counter < 1) {
        _counter = 1;
        widget.onChanged(_counter);
      }
    });
  }

  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 40);
      }
      await HapticFeedback.lightImpact();
    } catch (_) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The blurred box and checkbox when isSelected
    Widget selector = _expanded
        ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.blue.shade100, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.blue),
                  onPressed: _decrement,
                  splashRadius: 22,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _increment,
                  splashRadius: 22,
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 28,
                ),
              ],
            ),
          )
        : InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: _expand,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade50,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          );

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.isSelected ? 0.4 : 1.0,
          child: BackdropFilter(
            filter: widget.isSelected
                ? ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5)
                : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        selector,
        if (widget.isSelected)
          const Positioned(
            top: 0,
            right: 0,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Colors.blue,
              child: Icon(Icons.check, color: Colors.white, size: 18),
            ),
          )
      ],
    );
  }
}
