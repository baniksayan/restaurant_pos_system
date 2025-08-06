import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/shared/widgets/animations/fade_in_animation.dart';

class StaggeredAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final Axis direction;

  const StaggeredAnimation({
    Key? key,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.direction = Axis.vertical,
  }) : super(key: key);

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return FadeInAnimation(
          duration: widget.duration,
          delay: Duration(milliseconds: index * widget.staggerDelay.inMilliseconds),
          slideFrom: widget.direction == Axis.vertical 
              ? const Offset(0, 0.3) 
              : const Offset(0.3, 0),
          child: child,
        );
      }).toList(),
    );
  }
}
