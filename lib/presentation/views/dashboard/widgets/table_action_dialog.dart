import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/models/restaurant_table.dart';

/// ============================================================
/// DESIGN TOKENS
/// ============================================================
class _Tokens {
  static const primary = Color(0xFF1F6FEB); // Occupy & Order
  static const primarySoft = Color(0xFFEAF1FF);
  static const secondary = Color(
    0xFF16794A,
  ); // Reserve Table (calmer, distinct hue)
  static const secondarySoft = Color(0xFFEAF7F0);
  static const textDark = Color(0xFF1A1D23);
  static const textMuted = Color(0xFF6B7280);
  static const sheetBg = Colors.white;
}

/// ============================================================
/// DIALOG
/// ============================================================
class TableActionDialog extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onOccupy;
  final VoidCallback onReserve;

  const TableActionDialog({
    super.key,
    required this.table,
    required this.onOccupy,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width < 480 ? size.width * 0.92 : 420.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: _Tokens.sheetBg,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(tableLabel: table.name),
                const SizedBox(height: 4),
                const Text(
                  'Choose table action',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _Tokens.textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                _ActionCard(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Occupy & Order',
                  subtitle: 'Start a new order now',
                  color: _Tokens.primary,
                  softColor: _Tokens.primarySoft,
                  filled: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    onOccupy();
                  },
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.schedule_rounded,
                  title: 'Reserve Table',
                  subtitle: 'Book for an upcoming guest',
                  color: _Tokens.secondary,
                  softColor: _Tokens.secondarySoft,
                  filled: false,
                  onTap: () {
                    Navigator.of(context).pop();
                    onReserve();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String tableLabel;
  const _Header({required this.tableLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.table_restaurant_rounded,
          color: _Tokens.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tableLabel,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _Tokens.textDark,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _CloseButton(onTap: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(left: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF2F3F5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 18,
          color: _Tokens.textMuted,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color softColor;
  final bool filled;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.softColor,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    final bg = filled ? color : softColor;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                filled
                    ? null
                    : Border.all(
                      color: color.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      filled
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color:
                            filled
                                ? Colors.white.withValues(alpha: 0.85)
                                : _Tokens.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    filled
                        ? Colors.white.withValues(alpha: 0.8)
                        : color.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
