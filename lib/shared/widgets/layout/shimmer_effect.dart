import 'package:flutter/material.dart';

/// A unified, high-performance shimmer container that coordinates a smooth,
/// synchronized light wave across all descendant [ShimmerLoading] bones.
class Shimmer extends StatefulWidget {
  final Widget child;
  final LinearGradient? gradient;
  final Duration duration;
  final bool enabled;

  static const LinearGradient defaultGradient = LinearGradient(
    colors: [
      Color(0xFFE2E8F0), // Slate 200
      Color(0xFFEDF2F7), // Slate 100
      Color(0xFFFFFFFF), // Pure white shine
      Color(0xFFEDF2F7), // Slate 100
      Color(0xFFE2E8F0), // Slate 200
    ],
    stops: [0.0, 0.35, 0.5, 0.65, 1.0],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    tileMode: TileMode.clamp,
  );

  const Shimmer({
    super.key,
    required this.child,
    this.gradient,
    this.duration = const Duration(milliseconds: 1400),
    this.enabled = true,
  });

  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  @override
  ShimmerState createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Listenable get shimmerChanges => _controller;

  LinearGradient get gradient => widget.gradient ?? Shimmer.defaultGradient;

  bool get enabled => widget.enabled;

  bool get isSized =>
      (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  Size get size => (context.findRenderObject() as RenderBox).size;

  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerBox = context.findRenderObject() as RenderBox?;
    if (shimmerBox == null || !shimmerBox.hasSize || !descendant.hasSize) {
      return Offset.zero;
    }
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    return _ShimmerScope(
      shimmerState: this,
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  final ShimmerState shimmerState;

  const _ShimmerScope({
    required this.shimmerState,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => false;
}

/// Applies a synchronized shimmer gradient shader mask to its child based on its
/// position relative to the nearest ancestor [Shimmer].
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  Listenable? _shimmerChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerChanges != null) {
      _shimmerChanges!.removeListener(_onShimmerChange);
    }
    _shimmerChanges = Shimmer.of(context)?.shimmerChanges;
    if (_shimmerChanges != null) {
      _shimmerChanges!.addListener(_onShimmerChange);
    }
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    if (widget.isLoading && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final shimmer = Shimmer.of(context);
    if (shimmer == null || !shimmer.enabled || !shimmer.isSized) {
      // Fallback: Render child with basic placeholder background if no ancestor shimmer exists
      return widget.child;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return widget.child;
    }

    final offsetWithinShimmer = shimmer.getDescendantOffset(
      descendant: renderBox,
    );

    final shimmerSize = shimmer.size;
    final gradient = shimmer.gradient;
    final controllerValue =
        (shimmer.shimmerChanges as AnimationController).value;

    // Shift gradient horizontally to create the sweep effect across ancestor bounds
    final dx = -1.0 + (controllerValue * 3.0);

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(dx - 0.5, -0.3),
          end: Alignment(dx + 0.5, 0.3),
          colors: gradient.colors,
          stops: gradient.stops,
          tileMode: TileMode.clamp,
        ).createShader(
          Rect.fromLTWH(
            -offsetWithinShimmer.dx,
            -offsetWithinShimmer.dy,
            shimmerSize.width,
            shimmerSize.height,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Convenience drop-in wrapper that creates both a [Shimmer] provider and renders [child].
class ShimmerEffect extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFFFFFFF),
    this.duration = const Duration(milliseconds: 1400),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: duration,
      enabled: enabled,
      gradient: LinearGradient(
        colors: [
          baseColor,
          Color.lerp(baseColor, highlightColor, 0.4) ?? baseColor,
          highlightColor,
          Color.lerp(baseColor, highlightColor, 0.4) ?? baseColor,
          baseColor,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        tileMode: TileMode.clamp,
      ),
      child: child,
    );
  }
}

/// A crisp, geometry-perfect placeholder bone designed for skeleton views.
class ShimmerBone extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final ShapeBorder? shape;
  final Color? color;
  final Widget? child;

  const ShimmerBone({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape,
    this.color,
    this.child,
  });

  const ShimmerBone.rectangular({
    super.key,
    this.width,
    required this.height,
    BorderRadiusGeometry? borderRadius,
    this.color,
    this.child,
  })  : borderRadius =
            borderRadius ?? const BorderRadius.all(Radius.circular(6)),
        shape = null;

  const ShimmerBone.circular({
    super.key,
    required double size,
    this.color,
    this.child,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = const CircleBorder();

  const ShimmerBone.pill({
    super.key,
    this.width,
    required this.height,
    this.color,
    this.child,
  })  : borderRadius = const BorderRadius.all(Radius.circular(999)),
        shape = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(6),
            ),
      ),
      child: child,
    );
  }
}
