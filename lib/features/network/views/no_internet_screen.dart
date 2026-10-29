import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import '../providers/network_provider.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onRetry;
  final bool isOverlay;

  const NoInternetScreen({
    super.key,
    this.onRetry,
    this.isOverlay = false,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _hoverController;
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<double> _entranceScale;

  @override
  void initState() {
    super.initState();

    // Infinite radar pulse controller
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // Gentle hover levitation controller
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // Smooth entry controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _entranceScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _hoverController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkProvider = context.watch<NetworkProvider>();
    final isChecking = networkProvider.isCheckingStatus;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.isOverlay
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: _buildContent(context, networkProvider, isChecking),
            )
          : _buildContent(context, networkProvider, isChecking),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NetworkProvider networkProvider,
    bool isChecking,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: widget.isOverlay
            ? const Color(0xFF090D16).withValues(alpha: 0.90)
            : const Color(0xFF0B1120),
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.2,
          colors: [
            const Color(0xFF1E1B4B).withValues(alpha: 0.65), // Soft deep indigo glow
            widget.isOverlay
                ? const Color(0xFF090D16).withValues(alpha: 0.92)
                : const Color(0xFF0B1120),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _entranceFade,
              child: ScaleTransition(
                scale: _entranceScale,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FAANG Hero Radar Visual
                      _buildHeroRadar(),

                      const SizedBox(height: 28),

                      // Ambient Status Chip
                      _buildStatusPill(),

                      const SizedBox(height: 16),

                      // Headline
                      const Text(
                        'No Internet Connection',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Minimal Subtitle
                      const Text(
                        'WhizEats Pro requires an internet connection to sync tables, orders, and live KDS in real time. Please connect to Wi-Fi or Cellular Data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Apple-style Glass Settings Control Card
                      _buildSettingsControlCard(networkProvider),

                      const SizedBox(height: 18),

                      // Primary Reconnect Action Button
                      _buildReconnectButton(
                        isChecking: isChecking,
                        onPressed: () async {
                          await HapticHelper.triggerFeedback();
                          if (widget.onRetry != null) {
                            widget.onRetry!();
                          }
                          await networkProvider.retryConnection();
                        },
                      ),

                      const SizedBox(height: 24),

                      // Auto-recovery pulse footer
                      _buildAutoRecoveryFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// FAANG-grade Animated Hero Radar Disc with levitation
  Widget _buildHeroRadar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_radarController, _hoverController]),
      builder: (context, child) {
        // Subtle floating translation (+/- 5px)
        final hoverOffset =
            math.sin(_hoverController.value * 2 * math.pi) * 5.0;

        return Transform.translate(
          offset: Offset(0, hoverOffset),
          child: SizedBox(
            width: 190,
            height: 190,
            child: CustomPaint(
              painter: _FaangRadarPainter(
                progress: _radarController.value,
                primaryColor: const Color(0xFF6366F1),
                accentColor: const Color(0xFFF43F5E),
              ),
              child: Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF262E45),
                        Color(0xFF131A2A),
                      ],
                    ),
                    boxShadow: [
                      // Outer ambient glow
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      // Soft specular drop
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glowing inner sphere ring
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF182032).withValues(alpha: 0.8),
                        ),
                      ),
                      // Center Hero Icon
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 42,
                        color: Color(0xFFF87171),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Status Pill Chip with breathing amber/rose beacon
  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, _) {
              final pulse =
                  (math.sin(_radarController.value * 2 * math.pi) + 1) / 2;
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF43F5E),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF43F5E)
                          .withValues(alpha: 0.4 + (pulse * 0.4)),
                      blurRadius: 6 + (pulse * 6),
                      spreadRadius: pulse * 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Offline Mode',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFDA4AF),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Apple-Style Grouped Glass Control Card
  Widget _buildSettingsControlCard(NetworkProvider networkProvider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F33).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Wi-Fi Action Row
          _buildSettingsTile(
            icon: Icons.wifi_rounded,
            iconGradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            title: 'Wi-Fi Settings',
            subtitle: 'Connect to restaurant wireless network',
            onTap: () async {
              await HapticHelper.triggerFeedback();
              networkProvider.openWifiSettings();
            },
          ),

          // Hairline divider
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 68, right: 18),
            color: const Color(0xFF334155).withValues(alpha: 0.25),
          ),

          // Mobile Data Action Row
          _buildSettingsTile(
            icon: Icons.signal_cellular_alt_rounded,
            iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
            title: 'Mobile Data',
            subtitle: 'Enable cellular data or roaming backup',
            onTap: () async {
              await HapticHelper.triggerFeedback();
              networkProvider.openMobileDataSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Squircle Icon Badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: iconGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconGradient.first.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
              ),

              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing action chevron
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Primary FAANG-grade Reconnect Button
  Widget _buildReconnectButton({
    required bool isChecking,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Modern Indigo
              Color(0xFF4F46E5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isChecking ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.15),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isChecking
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Testing Connection...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Check Connection',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
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

  /// Subtle Auto-Recovery Status Footer
  Widget _buildAutoRecoveryFooter() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF64748B).withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'Auto-reconnects as soon as internet returns',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for multi-layered concentric radar orbital waves
class _FaangRadarPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _FaangRadarPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const maxRadius = 92.0;
    const minRadius = 48.0;

    // Ambient glow in the core
    final coreGlowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, 54, coreGlowPaint);

    // 3 expanding orbital rings with sine opacity
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i * 0.33)) % 1.0;
      final currentRadius = minRadius + (maxRadius - minRadius) * waveProgress;

      // Bell curve opacity
      final opacity = math.sin(waveProgress * math.pi) * 0.40;

      final wavePaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, currentRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FaangRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
