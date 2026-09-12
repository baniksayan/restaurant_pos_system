import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/app_assets.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';

class EnhancedTableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Seats another group at this table, alongside the ones already here.
  ///
  /// A table already holding an order otherwise opens straight into that
  /// order, giving a second group no way in — their items would land on the
  /// first group's bill. Shown only while the table has orders; an empty
  /// table starts its first order by being tapped.
  final VoidCallback? onAddParty;

  const EnhancedTableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.onLongPress,
    this.onAddParty,
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

              // Shared Table Badge (Only shown if table has 2 or more active orders)
              if (table.orderCount >= 2)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          size: 11,
                          color: Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${table.orderCount} Shared',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Card content. Sized from the space actually available rather
              // than fixed pixels: these cards sit in a grid whose tile height
              // varies with screen width and text scale, and a fixed 60px
              // avatar plus four text rows overflowed on shorter tiles.
              LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final w = constraints.maxWidth;

                  // Avatar takes a share of the tile, clamped so it stays
                  // recognisable on small tiles and does not dominate large
                  // ones.
                  final avatar = (h * 0.34).clamp(34.0, 62.0);
                  final compact = h < 132;

                  final nameSize = (w * 0.105).clamp(11.5, 14.0);
                  final metaSize = (w * 0.082).clamp(9.0, 10.5);
                  final pillSize = (w * 0.072).clamp(8.0, 9.0);
                  final gap = (h * 0.022).clamp(1.0, 4.0);

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: compact ? 4 : 6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: avatar,
                            height: avatar,
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
                                color: statusConfig.color.withValues(
                                  alpha: 0.15,
                                ),
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
                                  size: avatar * 0.55,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: gap),

                          // Table name
                          Text(
                            table.name,
                            style: TextStyle(
                              fontSize: nameSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),

                          // Occupancy. One line whichever state the table is
                          // in, so every card in the grid keeps the same
                          // height and the rows stay aligned.
                          SizedBox(height: gap * 0.6),
                          _buildOccupancyLine(
                            statusConfig: statusConfig,
                            fontSize: metaSize,
                          ),

                          SizedBox(height: gap),

                          // Status pill
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 7 : 9,
                              vertical: compact ? 2 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusConfig.color,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: statusConfig.color.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Text(
                              statusConfig.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: pillSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One line describing who is at the table.
  ///
  /// Empty table shows its size; an occupied one shows the adults and
  /// children seated across every party, against capacity. Always a single
  /// line so cards in the grid stay the same height, and it degrades to plain
  /// capacity when the server has not reported guest counts — "A0 C0" on an
  /// occupied table would read as fact rather than as missing data.
  Widget _buildOccupancyLine({
    required _TableStatusConfig statusConfig,
    required double fontSize,
  }) {
    final adults = table.seatedAdults;
    final children = table.seatedChildren;
    final known = adults != null || children != null;

    if (!known) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            size: fontSize * 1.2,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              'Capacity: ${table.capacity}',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final seated = (adults ?? 0) + (children ?? 0);
    final over = table.capacity > 0 && seated > table.capacity;
    final tone = over ? const Color(0xFFB45309) : statusConfig.color;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _guestChip('A', adults ?? 0, tone, fontSize),
          const SizedBox(width: 4),
          _guestChip('C', children ?? 0, tone, fontSize),
          const SizedBox(width: 5),
          Text(
            'of ${table.capacity}',
            style: TextStyle(
              fontSize: fontSize * 0.92,
              fontWeight: FontWeight.w600,
              color: over ? const Color(0xFFB45309) : Colors.grey[600],
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// A single "A 3" / "C 1" count chip.
  Widget _guestChip(String label, int value, Color tone, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tone.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: tone,
          letterSpacing: -0.1,
          height: 1.1,
        ),
      ),
    );
  }

  _TableStatusConfig _getStatusConfig(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return const _TableStatusConfig(
          color: Color(0xFF10B981), // Emerald Green
          iconPath: AppAssets.tableAvailable,
          fallbackIcon: Icons.table_restaurant,
          displayName: 'AVAILABLE',
        );
      case TableStatus.occupied:
        return const _TableStatusConfig(
          color: Color(0xFFEF4444), // Coral Red
          iconPath: AppAssets.tableOccupied,
          fallbackIcon: Icons.table_restaurant,
          displayName: 'OCCUPIED',
        );
      case TableStatus.kotGenerated:
        return const _TableStatusConfig(
          color: Color.fromRGBO(139, 92, 246, 1), // Purple
          iconPath: AppAssets.tableKotGenerated,
          fallbackIcon: Icons.receipt_long,
          displayName: 'KOT GENERATED',
        );
      case TableStatus.billGenerated:
        return const _TableStatusConfig(
          color: Color(0xFF3B82F6), // Blue
          iconPath: AppAssets.tableBillGenerated,
          fallbackIcon: Icons.request_quote,
          displayName: 'BILL GENERATED',
        );
      case TableStatus.billSettled:
        return const _TableStatusConfig(
          color: Color(0xFF06B6D4), // Cyan / Teal
          iconPath: AppAssets.tableBillSettled,
          fallbackIcon: Icons.check_circle,
          displayName: 'BILL SETTLED',
        );
      case TableStatus.reserved:
        return const _TableStatusConfig(
          color: Color(0xFFF59E0B), // Amber / Yellow
          iconPath: AppAssets.tableAvailable,
          fallbackIcon: Icons.bookmark,
          displayName: 'RESERVED',
        );
      case TableStatus.outOfOrder:
        return const _TableStatusConfig(
          color: Color(0xFF64748B), // Slate Grey
          iconPath: AppAssets.tableAvailable,
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
