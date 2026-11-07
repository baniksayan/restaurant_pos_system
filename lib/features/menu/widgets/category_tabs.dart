import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import '../providers/menu_provider.dart';

class CategoryTabs extends StatelessWidget {
  const CategoryTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isCategoriesLoading) {
          return Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (!menuProvider.hasMenuItems) {
          return const SizedBox.shrink();
        }

        // Get API categories
        final rawCategories = menuProvider.categoryNames;

        // Build combined tabs: ['All', if (hasVegItems) 'Veg Only', ...other API categories]
        final List<String> tabs = [];
        tabs.add('All');
        if (menuProvider.hasVegItems) {
          tabs.add('Veg Only');
        }
        for (var cat in rawCategories) {
          if (cat != 'All' && cat != 'Veg Only') {
            tabs.add(cat);
          }
        }

        final selectedFilter = menuProvider.selectedDietaryFilter;
        final selectedCat = menuProvider.selectedCategory;

        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final tab = tabs[index];

              // Check active selection
              bool isSelected = false;
              if (tab == 'All') {
                isSelected = (selectedFilter == 'All' && selectedCat == 'All');
              } else if (tab == 'Veg Only') {
                isSelected = (selectedFilter == 'Veg');
              } else {
                isSelected = (selectedFilter == 'All' && selectedCat == tab);
              }

              // Color configuration
              final Color activeColor =
                  tab == 'Veg Only'
                      ? const Color(0xFF10B981)
                      : AppColors.primary;

              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (tab == 'All') {
                        menuProvider.selectDietaryFilter('All');
                        menuProvider.selectCategory('All');
                      } else if (tab == 'Veg Only') {
                        menuProvider.selectDietaryFilter('Veg');
                        menuProvider.selectCategory('All');
                      } else {
                        menuProvider.selectDietaryFilter('All');
                        menuProvider.selectCategory(tab);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(
                        minWidth: 56,
                        minHeight: 32,
                        maxHeight: 32,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? activeColor
                                : Colors.white.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? activeColor
                                  : const Color(0xFFE2E8F0).withValues(alpha: 0.85),
                          width: 1.0,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: activeColor.withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
