// lib/shared/widgets/layout/premium_refresh_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';

class PremiumRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const PremiumRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<PremiumRefreshIndicator> createState() => _PremiumRefreshIndicatorState();
}

class _PremiumRefreshIndicatorState extends State<PremiumRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;
  double _pullOffset = 0.0;
  bool _isRefreshing = false;
  bool _hasTriggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _pullOffset = 60.0; // lock at 60px
    });
    _rotateController.repeat();
    
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _rotateController.stop();
        setState(() {
          _isRefreshing = false;
          _pullOffset = 0.0;
          _hasTriggeredHaptic = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        final double pixels = notification.metrics.pixels;
        
        if (_isRefreshing) {
          return false;
        }

        if (pixels < 0) {
          // Overscrolling at the top
          final double absoluteOverscroll = -pixels;
          setState(() {
            _pullOffset = absoluteOverscroll * 0.6;
          });

          // Trigger subtle haptic click when pulling past threshold (50px)
          if (_pullOffset > 50.0 && !_hasTriggeredHaptic) {
            HapticFeedback.mediumImpact();
            _hasTriggeredHaptic = true;
          } else if (_pullOffset <= 50.0 && _hasTriggeredHaptic) {
            _hasTriggeredHaptic = false;
          }
        } else if (_pullOffset > 0) {
          setState(() {
            _pullOffset = 0.0;
          });
        }

        if (notification is ScrollEndNotification) {
          if (_pullOffset > 50.0) {
            _handleRefresh();
          } else {
            setState(() {
              _pullOffset = 0.0;
              _hasTriggeredHaptic = false;
            });
          }
        }
        return false;
      },
      child: Stack(
        children: [
          // Pull to refresh indicator at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: Container(
              alignment: Alignment.center,
              child: Opacity(
                opacity: (_pullOffset / 60.0).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _isRefreshing ? _rotateController : AlwaysStoppedAnimation(_pullOffset / 120.0),
                      child: const Icon(
                        Icons.hourglass_empty_rounded,
                        size: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CupertinoActivityIndicator(radius: 8),
                  ],
                ),
              ),
            ),
          ),
          // The child content translated downwards
          Transform.translate(
            offset: Offset(0, _pullOffset),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
