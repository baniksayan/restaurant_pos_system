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
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        // Get API categories
        final rawCategories = menuProvider.categoryNames;

        // Build combined tabs: ['All', 'Veg Only', ...other API categories]
        final List<String> tabs = [];
        tabs.add('All');
        tabs.add('Veg Only');
        for (var cat in rawCategories) {
          if (cat != 'All' && cat != 'Veg Only') {
            tabs.add(cat);
          }
        }

        final selectedFilter = menuProvider.selectedDietaryFilter;
        final selectedCat = menuProvider.selectedCategory;

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
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
              final Color activeColor = tab == 'Veg Only' ? const Color(0xFF4CAF50) : AppColors.primary;

              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
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
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(
                        minWidth: 64,
                        minHeight: 36,
                        maxHeight: 36,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
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
