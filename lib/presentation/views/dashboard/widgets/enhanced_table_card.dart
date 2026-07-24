import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';

class EnhancedTableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const EnhancedTableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(table.status);
    final cardSeed = table.id.hashCode ^ table.name.hashCode;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusConfig.color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusConfig.color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Dynamic Random Wave Curve with Linear Gradient Fill
              Positioned.fill(
                child: CustomPaint(
                  painter: RandomWavePainter(
                    baseColor: statusConfig.color,
                    seed: cardSeed,
                  ),
                ),
              ),

              // Card Content Centered Perfectly in the Middle
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular Container with Soft Linear Gradient & Large PNG Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusConfig.color.withValues(alpha: 0.14),
                              statusConfig.color.withValues(alpha: 0.04),
                            ],
                          ),
                          border: Border.all(
                            color: statusConfig.color.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(3.5),
                        child: Image.asset(
                          statusConfig.iconPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              statusConfig.fallbackIcon,
                              color: statusConfig.color,
                              size: 32,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Table Name
                      Text(
                        table.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),

                      // Capacity Icon & Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 12.5,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Capacity: ${table.capacity}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Status Pill Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusConfig.color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: statusConfig.color.withValues(alpha: 0.22),
                              blurRadius: 3,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Text(
                          statusConfig.displayName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TableStatusConfig _getStatusConfig(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const _TableStatusConfig(
          color: Color(0xFF10B981), // Emerald Green
          iconPath: 'assets/images/icons/available_icon.png',
          fallbackIcon: Icons.table_restaurant,
          displayName: 'AVAILABLE',
        );
      case TableStatus.occupied:
        return const _TableStatusConfig(
          color: Color(0xFFEF4444), // Coral Red
          iconPath: 'assets/images/icons/occupied_icon.png',
          fallbackIcon: Icons.table_restaurant,
          displayName: 'OCCUPIED',
        );
      case TableStatus.kotGenerated:
        return const _TableStatusConfig(
          color: Color.fromRGBO(139, 92, 246, 1), // Purple
          iconPath: 'assets/images/icons/kot_generated_icon.png',
          fallbackIcon: Icons.receipt_long,
          displayName: 'KOT GENERATED',
        );
      case TableStatus.billGenerated:
        return const _TableStatusConfig(
          color: Color(0xFF3B82F6), // Blue
          iconPath: 'assets/images/icons/bill_generated_icon.png',
          fallbackIcon: Icons.request_quote,
          displayName: 'BILL GENERATED',
        );
      case TableStatus.billSettled:
        return const _TableStatusConfig(
          color: Color(0xFF06B6D4), // Cyan / Teal
          iconPath: 'assets/images/icons/bill_settled_icon.png',
          fallbackIcon: Icons.check_circle,
          displayName: 'BILL SETTLED',
        );
      case TableStatus.reserved:
        return const _TableStatusConfig(
          color: Color(0xFFF59E0B), // Amber / Yellow
          iconPath: 'assets/images/icons/available_icon.png',
          fallbackIcon: Icons.bookmark,
          displayName: 'RESERVED',
        );
      case TableStatus.outOfOrder:
        return const _TableStatusConfig(
          color: Color(0xFF64748B), // Slate Grey
          iconPath: 'assets/images/icons/available_icon.png',
          fallbackIcon: Icons.block,
          displayName: 'OUT OF ORDER',
        );
    }
  }
}

class _TableStatusConfig {
  final Color color;
  final String iconPath;
  final IconData fallbackIcon;
  final String displayName;

  const _TableStatusConfig({
    required this.color,
    required this.iconPath,
    required this.fallbackIcon,
    required this.displayName,
  });
}

class RandomWavePainter extends CustomPainter {
  final Color baseColor;
  final int seed;

  RandomWavePainter({required this.baseColor, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    // Generate deterministic pseudo-random factors from seed
    final r1 = ((seed * 9301 + 49297) % 233280) / 233280.0;
    final r2 = (((seed + 7) * 9301 + 49297) % 233280) / 233280.0;
    final r3 = (((seed + 13) * 9301 + 49297) % 233280) / 233280.0;

    final startY = size.height * (0.68 + r1 * 0.10);
    final control1X = size.width * (0.20 + r2 * 0.20);
    final control1Y = size.height * (0.52 + r3 * 0.15);
    final control2X = size.width * (0.60 + r1 * 0.25);
    final control2Y = size.height * (0.76 + r2 * 0.10);
    final endY = size.height * (0.66 + r3 * 0.12);

    final path = Path();
    path.moveTo(0, startY);
    path.cubicTo(control1X, control1Y, control2X, control2Y, size.width, endY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: r1 > 0.5 ? Alignment.topLeft : Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              baseColor.withValues(alpha: 0.12),
              baseColor.withValues(alpha: 0.02),
            ],
          ).createShader(rect)
          ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RandomWavePainter oldDelegate) =>
      oldDelegate.baseColor != baseColor || oldDelegate.seed != seed;
}
