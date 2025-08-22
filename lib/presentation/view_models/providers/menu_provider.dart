import 'package:flutter/material.dart';
import '../../../data/models/menu_item.dart';

class MenuProvider with ChangeNotifier {
  List<MenuItem> _menuItems = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Map<String, int> _cart = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Existing getters
  List<MenuItem> get menuItems => _menuItems;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  Map<String, int> get cart => Map.unmodifiable(_cart);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final List<String> categories = [
    'All',
    'Starters',
    'Main Course',
    'Beverages',
    'Desserts',
  ];

  // Sample menu items using your MenuItem model
  void _initializeSampleData() {
    _menuItems = [
      MenuItem(
        id: '1',
        name: 'Chicken Roll',
        description: 'Spicy chicken wrapped in soft bread',
        price: 120,
        category: 'Starters',
        imageUrl: 'https://butfirstchai.com/wp-content/uploads/2023/09/musakhan-rolls-sumac-chicken-recipe.jpg',
      ),
      MenuItem(
        id: '2',
        name: 'Paneer Tikka',
        description: 'Grilled cottage cheese with spices',
        price: 180,
        category: 'Starters',
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJ2WY2YmIJtXrpmDToEHwJIOAcyBefjpFwXg&s',
      ),
      MenuItem(
        id: '3',
        name: 'Chili Paneer',
        description: 'Indo-Chinese style paneer',
        price: 160,
        category: 'Main Course',
        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyPmolFdbsSAAg4mZENnvph9hkhKoCJNj9EA&s',
      ),
      MenuItem(
        id: '4',
        name: 'Butter Chicken',
        description: 'Creamy tomato-based chicken curry',
        price: 280,
        category: 'Main Course',
        imageUrl: 'https://www.indianhealthyrecipes.com/wp-content/uploads/2023/04/butter-chicken-recipe.jpg',
      ),
      MenuItem(
        id: '5',
        name: 'Chicken Biryani',
        description: 'Aromatic basmati rice with spiced chicken',
        price: 320,
        category: 'Main Course',
        imageUrl: 'https://www.licious.in/blog/wp-content/uploads/2022/06/chicken-hyderabadi-biryani-01.jpg',
      ),
      // Add more items as needed
    ];
  }

  List<MenuItem> get filteredItems {
    var filtered = _menuItems;
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    return filtered;
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addToCart(String itemId) {
    _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    if (_cart[itemId] != null) {
      if (_cart[itemId]! > 1) {
        _cart[itemId] = _cart[itemId]! - 1;
      } else {
        _cart.remove(itemId);
      }
      notifyListeners();
    }
  }

  int getCartQuantity(String itemId) {
    return _cart[itemId] ?? 0;
  }

  int get totalCartItems {
    return _cart.values.fold(0, (sum, qty) => sum + qty);
  }

  double calculateTotal() {
    double total = 0.0;
    _cart.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere((item) => item.id == itemId);
      total += item.price * quantity.toDouble();
    });
    return total;
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> loadMenuItems() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Initialize sample data
      _initializeSampleData();
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load menu items: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Existing methods to maintain compatibility
  void addMenuItem(MenuItem item) {
    _menuItems.add(item);
    notifyListeners();
  }

  void updateMenuItem(MenuItem item) {
    final index = _menuItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _menuItems[index] = item;
      notifyListeners();
    }
  }

  void removeMenuItem(String id) {
    _menuItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
