// lib/presentation/views/menu_management/menu_view.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/menu_item.dart';

class MenuView extends StatefulWidget {
  final String? selectedTableId; // null = view-only, non-null = can order
  final String? tableName;
  final Function(String itemId, String itemName, double price, Offset position)? onAddToCart;
  
  const MenuView({
    super.key,
    this.selectedTableId,
    this.tableName,
    this.onAddToCart,
  });

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Map<String, int> _cart = {}; // menuItemId -> quantity

  final List<String> _categories = ['All', 'Starters', 'Main Course', 'Beverages', 'Desserts'];

  // Sample menu items (will come from API later)
  final List<MenuItemModel> _menuItems = [
    MenuItemModel(
      id: '1',
      name: 'Chicken Roll',
      price: 120,
      category: 'Starters',
      isVeg: false,
      imageUrl: 'https://butfirstchai.com/wp-content/uploads/2023/09/musakhan-rolls-sumac-chicken-recipe.jpg',
      description: 'Spicy chicken wrapped in soft bread',
    ),
    MenuItemModel(
      id: '2', 
      name: 'Paneer Tikka',
      price: 180,
      category: 'Starters',
      isVeg: true,
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJ2WY2YmIJtXrpmDToEHwJIOAcyBefjpFwXg&s',
      description: 'Grilled cottage cheese with spices',
    ),
    MenuItemModel(
      id: '3',
      name: 'Chili Paneer',
      price: 160,
      category: 'Main Course',
      isVeg: true,
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyPmolFdbsSAAg4mZENnvph9hkhKoCJNj9EA&s',
      description: 'Indo-Chinese style paneer',
    ),
    MenuItemModel(
      id: '4',
      name: 'Butter Chicken',
      price: 280,
      category: 'Main Course',
      isVeg: false,
      imageUrl: 'https://www.indianhealthyrecipes.com/wp-content/uploads/2023/04/butter-chicken-recipe.jpg',
      description: 'Creamy tomato-based chicken curry',
    ),
    MenuItemModel(
      id: '5',
      name: 'Chicken Biryani',
      price: 320,
      category: 'Main Course',
      isVeg: false,
      imageUrl: 'https://www.licious.in/blog/wp-content/uploads/2022/06/chicken-hyderabadi-biryani-01.jpg',
      description: 'Aromatic basmati rice with spiced chicken',
    ),
    MenuItemModel(
      id: '6',
      name: 'Palak Paneer',
      price: 220,
      category: 'Main Course',
      isVeg: true,
      imageUrl: 'https://www.munatycooking.com/wp-content/uploads/2022/09/palak-paneer-feature-1200-x-1200.jpg',
      description: 'Cottage cheese in spinach gravy',
    ),
    MenuItemModel(
      id: '7',
      name: 'Fish Curry',
      price: 260,
      category: 'Main Course',
      isVeg: false,
      imageUrl: 'https://stewwithsaba.com/wp-content/uploads/2024/05/IMG_4409-edited.jpg',
      description: 'Traditional spiced fish curry',
    ),
    MenuItemModel(
      id: '8',
      name: 'Dal Makhani',
      price: 180,
      category: 'Main Course',
      isVeg: true,
      imageUrl: 'https://www.sharmispassions.com/wp-content/uploads/2012/05/dal-makhani7.jpg',
      description: 'Creamy black lentil curry',
    ),
    MenuItemModel(
      id: '9',
      name: 'Mutton Curry',
      price: 350,
      category: 'Main Course',
      isVeg: false,
      imageUrl: 'https://www.licious.in/blog/wp-content/uploads/2023/02/shutterstock_2205168763-750x508.jpg',
      description: 'Tender mutton in rich spiced gravy',
    ),
    MenuItemModel(
      id: '10',
      name: 'Veg Pulao',
      price: 150,
      category: 'Main Course',
      isVeg: true,
      imageUrl: 'https://www.sharmispassions.com/wp-content/uploads/2014/07/VegPulao1.jpg',
      description: 'Fragrant rice with mixed vegetables',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final canOrder = widget.selectedTableId != null;
    final filteredItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(canOrder),
            _buildSearchBar(),
            _buildCategoryTabs(),
            Expanded(child: _buildMenuGrid(filteredItems, canOrder)),
            if (canOrder && _cart.isNotEmpty) _buildCartFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool canOrder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardShadow, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (canOrder) 
                  Text(
                    widget.tableName ?? 'Select Table',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          
          // Status indicator
          if (canOrder) ...[
            IconButton(
              onPressed: _printKOT,
              icon: const Icon(Icons.print, color: AppColors.primary),
              tooltip: 'Print KOT',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ORDERING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'VIEW ONLY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Search dishes...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid(List<MenuItemModel> items, bool canOrder) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildMenuItemCard(items[index], canOrder);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item, bool canOrder) {
    final quantity = _cart[item.id] ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with veg/non-veg indicator
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                ),
                
                // Veg/Non-Veg indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.isVeg ? Colors.green : Colors.red,
                        shape: item.isVeg ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: item.isVeg ? BorderRadius.circular(2) : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Item details with reduced padding
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Flexible(
                    child: Text(
                      item.description ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      
                      if (canOrder)
                        quantity == 0
                            ? Builder(
                                builder: (context) {
                                  return GestureDetector(
                                    onTap: () => _addToCartWithAnimation(context, item),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _removeFromCart(item.id),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      quantity.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        return GestureDetector(
                                          onTap: () => _addToCartWithAnimation(context, item),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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

  Widget _buildCartFooter() {
    final totalItems = _cart.values.fold(0, (sum, qty) => sum + qty);
    final totalAmount = _calculateTotal();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardShadow, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalItems items',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹$totalAmount',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          ElevatedButton(
            onPressed: _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Place Order',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<MenuItemModel> _getFilteredItems() {
    var filtered = _menuItems;
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) => 
        item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    return filtered;
  }

  // 🎯 MERGED: Animation-enabled add to cart method
  void _addToCartWithAnimation(BuildContext context, MenuItemModel item) {
    // Get button position for animation
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final buttonPosition = renderBox.localToGlobal(Offset.zero);
      
      // Trigger animation callback if provided
      widget.onAddToCart?.call(item.id, item.name, item.price, buttonPosition);
    }
    
    // Add to local cart
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cart[itemId] != null) {
        if (_cart[itemId]! > 1) {
          _cart[itemId] = _cart[itemId]! - 1;
        } else {
          _cart.remove(itemId);
        }
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere((item) => item.id == itemId);
      total += item.price * quantity;
    });
    return total;
  }

  void _placeOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order placed for ${widget.tableName}!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Clear cart after placing order
    setState(() {
      _cart.clear();
    });
  }

  void _printKOT() {
    // Implement KOT printing via WiFi/Bluetooth
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KOT sent to kitchen printer!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isVeg;
  final String? imageUrl;
  final String? description;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isVeg,
    this.imageUrl,
    this.description,
  });
}
