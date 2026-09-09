import 'package:flutter/material.dart';

class BlinkingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool shouldBlink;

  const BlinkingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.shouldBlink = true,
  });

  @override
  State<BlinkingWidget> createState() => _BlinkingWidgetState();
}

class _BlinkingWidgetState extends State<BlinkingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.shouldBlink) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BlinkingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBlink != oldWidget.shouldBlink) {
      if (widget.shouldBlink) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
