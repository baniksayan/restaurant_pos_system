import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/features/network/providers/network_provider.dart';
import 'package:restaurant_pos_system/features/network/views/no_internet_screen.dart';
import '../overlays/slow_connection_overlay.dart';

class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final bool showSlowConnectionOverlay;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.showSlowConnectionOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, networkProvider, _) {
        // No internet - show full screen
        if (networkProvider.isDisconnected) {
          return const NoInternetScreen();
        }

        // Slow connection - show overlay
        if (networkProvider.isSlow && showSlowConnectionOverlay) {
          return Stack(
            children: [
              child,
              const SlowConnectionOverlay(),
            ],
          );
        }

        // Normal connection
        return child;
      },
    );
  }
}
