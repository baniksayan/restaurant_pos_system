import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  const SkeletonLoader.rectangular({
    super.key,
    this.width,
    required this.height,
    BorderRadiusGeometry? borderRadius,
  }) : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(8));

  const SkeletonLoader.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0.45, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
