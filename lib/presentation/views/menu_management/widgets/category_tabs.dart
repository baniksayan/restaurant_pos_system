// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/themes/app_colors.dart';
// import '../../../view_models/providers/menu_provider.dart';

// class CategoryTabs extends StatelessWidget {
//   const CategoryTabs({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MenuProvider>(
//       builder: (context, menuProvider, child) {
//         return Container(
//           height: 50,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: menuProvider.categories.length,
//             itemBuilder: (context, index) {
//               final category = menuProvider.categories[index];
//               final isSelected = menuProvider.selectedCategory == category;

//               return Container(
//                 margin: const EdgeInsets.only(right: 12),
//                 child: GestureDetector(
//                   onTap: () => menuProvider.selectCategory(category),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isSelected ? AppColors.primary : Colors.white,
//                       borderRadius: BorderRadius.circular(25),
//                       border: Border.all(
//                         color: isSelected ? AppColors.primary : Colors.grey.shade300,
//                       ),
//                     ),
//                     child: Text(
//                       category,
//                       style: TextStyle(
//                         color: isSelected ? Colors.white : Colors.grey[700],
//                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../view_models/providers/menu_provider.dart';

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

        final categories = menuProvider.categoryNames;

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = menuProvider.selectedCategory == category;

              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => menuProvider.selectCategory(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected 
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
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
