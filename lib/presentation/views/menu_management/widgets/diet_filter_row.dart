import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/menu_provider.dart';

class DietFilterRow extends StatelessWidget {
  const DietFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        final currentFilter = menuProvider.selectedDietaryFilter;

        Widget buildFilterChip(
          String label,
          String filterValue,
          Color activeColor,
          Widget icon,
        ) {
          final isSelected = currentFilter == filterValue;
          return GestureDetector(
            onTap: () => menuProvider.selectDietaryFilter(filterValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? activeColor : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? activeColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              buildFilterChip(
                'All',
                'All',
                AppColors.primary,
                const Icon(Icons.restaurant_menu_rounded, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              buildFilterChip(
                'Veg Only',
                'Veg',
                const Color(0xFF4CAF50),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              buildFilterChip(
                'Non-Veg',
                'Non-Veg',
                const Color(0xFF8D6E63),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: CustomPaint(
                        painter: _TrianglePainter(color: const Color(0xFF8D6E63)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
