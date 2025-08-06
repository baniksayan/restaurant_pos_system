import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/table.dart';
import '../../../shared/widgets/animations/fade_in_animation.dart';
import '../../../shared/widgets/buttons/animated_button.dart';

class TableDetailView extends StatefulWidget {
  final RestaurantTable table;

  const TableDetailView({super.key, required this.table});

  @override
  State<TableDetailView> createState() => _TableDetailViewState();
}

class _TableDetailViewState extends State<TableDetailView> {
  String _selectedCategory = 'Best Seller';
  
  final List<String> _categories = [
    'Best Seller',
    'Pure Veg',
    'Non Veg',
    'Beverages',
    'Desserts',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.table.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Capacity: ${widget.table.capacity} | ${widget.table.status.name.toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.table.status == TableStatus.occupied) ...[
            IconButton(
              icon: Icon(
                widget.table.kotGenerated ? Icons.receipt : Icons.receipt_outlined,
                color: widget.table.kotGenerated ? AppColors.warning : AppColors.textSecondary,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(
                widget.table.billGenerated ? Icons.payment : Icons.payment_outlined,
                color: widget.table.billGenerated ? AppColors.success : AppColors.textSecondary,
              ),
              onPressed: () {},
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Category Selection
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: AnimatedButton(
                    text: category,
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
                    textColor: isSelected ? Colors.white : AppColors.textPrimary,
                    height: 36,
                    width: null,
                  ),
                );
              },
            ),
          ),
          
          // Menu Items Grid
          Expanded(
            child: FadeInAnimation(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: 8, // Sample items
                itemBuilder: (context, index) {
                  return _buildMenuItemCard(index);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.cardShadow, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedButton(
                text: 'View Cart (0)',
                icon: Icons.shopping_cart,
                onPressed: () {},
                backgroundColor: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedButton(
                text: 'Place Order',
                icon: Icons.check,
                onPressed: () {},
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(int index) {
    final sampleItems = [
      {'name': 'Butter Chicken', 'price': '₹280', 'type': 'non-veg'},
      {'name': 'Paneer Tikka', 'price': '₹220', 'type': 'veg'},
      {'name': 'Biryani', 'price': '₹320', 'type': 'non-veg'},
      {'name': 'Dal Tadka', 'price': '₹180', 'type': 'veg'},
      {'name': 'Chicken Curry', 'price': '₹260', 'type': 'non-veg'},
      {'name': 'Naan', 'price': '₹60', 'type': 'veg'},
      {'name': 'Fish Fry', 'price': '₹300', 'type': 'non-veg'},
      {'name': 'Raita', 'price': '₹80', 'type': 'veg'},
    ];

    if (index >= sampleItems.length) return const SizedBox();
    
    final item = sampleItems[index];
    final isVeg = item['type'] == 'veg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.restaurant,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isVeg ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['name']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['price']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
