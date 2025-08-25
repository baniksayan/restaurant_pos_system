// import 'package:flutter/material.dart';
// import '../../../data/models/menu_item.dart';

// class MenuProvider with ChangeNotifier {
//   List<MenuItem> _menuItems = [];
//   String _searchQuery = '';
//   String _selectedCategory = 'All';
//   final Map<String, int> _cart = {};
//   bool _isLoading = false;
//   String? _errorMessage;

//   // Existing getters
//   List<MenuItem> get menuItems => _menuItems;
//   String get searchQuery => _searchQuery;
//   String get selectedCategory => _selectedCategory;
//   Map<String, int> get cart => Map.unmodifiable(_cart);
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;

//   final List<String> categories = [
//     'All',
//     'Starters',
//     'Main Course',
//     'Beverages',
//     'Desserts',
//   ];

//   // Sample menu items using your MenuItem model
//   void _initializeSampleData() {
//     _menuItems = [
//       MenuItem(
//         id: '1',
//         name: 'Chicken Roll',
//         description: 'Spicy chicken wrapped in soft bread',
//         price: 120,
//         category: 'Starters',
//         imageUrl: 'https://butfirstchai.com/wp-content/uploads/2023/09/musakhan-rolls-sumac-chicken-recipe.jpg',
//       ),
//       MenuItem(
//         id: '2',
//         name: 'Paneer Tikka',
//         description: 'Grilled cottage cheese with spices',
//         price: 180,
//         category: 'Starters',
//         imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRJ2WY2YmIJtXrpmDToEHwJIOAcyBefjpFwXg&s',
//       ),
//       MenuItem(
//         id: '3',
//         name: 'Chili Paneer',
//         description: 'Indo-Chinese style paneer',
//         price: 160,
//         category: 'Main Course',
//         imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyPmolFdbsSAAg4mZENnvph9hkhKoCJNj9EA&s',
//       ),
//       MenuItem(
//         id: '4',
//         name: 'Butter Chicken',
//         description: 'Creamy tomato-based chicken curry',
//         price: 280,
//         category: 'Main Course',
//         imageUrl: 'https://www.indianhealthyrecipes.com/wp-content/uploads/2023/04/butter-chicken-recipe.jpg',
//       ),
//       MenuItem(
//         id: '5',
//         name: 'Chicken Biryani',
//         description: 'Aromatic basmati rice with spiced chicken',
//         price: 320,
//         category: 'Main Course',
//         imageUrl: 'https://www.licious.in/blog/wp-content/uploads/2022/06/chicken-hyderabadi-biryani-01.jpg',
//       ),
//       // Add more items as needed
//     ];
//   }

//   List<MenuItem> get filteredItems {
//     var filtered = _menuItems;

//     if (_selectedCategory != 'All') {
//       filtered = filtered.where((item) => item.category == _selectedCategory).toList();
//     }

//     if (_searchQuery.isNotEmpty) {
//       filtered = filtered
//           .where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
//           .toList();
//     }

//     return filtered;
//   }

//   void updateSearchQuery(String query) {
//     _searchQuery = query;
//     notifyListeners();
//   }

//   void selectCategory(String category) {
//     _selectedCategory = category;
//     notifyListeners();
//   }

//   void addToCart(String itemId) {
//     _cart[itemId] = (_cart[itemId] ?? 0) + 1;
//     notifyListeners();
//   }

//   void removeFromCart(String itemId) {
//     if (_cart[itemId] != null) {
//       if (_cart[itemId]! > 1) {
//         _cart[itemId] = _cart[itemId]! - 1;
//       } else {
//         _cart.remove(itemId);
//       }
//       notifyListeners();
//     }
//   }

//   int getCartQuantity(String itemId) {
//     return _cart[itemId] ?? 0;
//   }

//   int get totalCartItems {
//     return _cart.values.fold(0, (sum, qty) => sum + qty);
//   }

//   double calculateTotal() {
//     double total = 0.0;
//     _cart.forEach((itemId, quantity) {
//       final item = _menuItems.firstWhere((item) => item.id == itemId);
//       total += item.price * quantity.toDouble();
//     });
//     return total;
//   }

//   void clearCart() {
//     _cart.clear();
//     notifyListeners();
//   }

//   Future<void> loadMenuItems() async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       // Initialize sample data
//       _initializeSampleData();

//       // Simulate API call delay
//       await Future.delayed(const Duration(seconds: 1));

//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _errorMessage = 'Failed to load menu items: $e';
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Existing methods to maintain compatibility
//   void addMenuItem(MenuItem item) {
//     _menuItems.add(item);
//     notifyListeners();
//   }

//   void updateMenuItem(MenuItem item) {
//     final index = _menuItems.indexWhere((i) => i.id == item.id);
//     if (index != -1) {
//       _menuItems[index] = item;
//       notifyListeners();
//     }
//   }

//   void removeMenuItem(String id) {
//     _menuItems.removeWhere((item) => item.id == id);
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/models/menu_api_res_model.dart';
import '../../../data/models/category_model.dart';
import '../../../services/api_service.dart';

class MenuProvider with ChangeNotifier {
  // Menu items from API
  List<Data> _apiMenuItems = [];

  // Categories from API
  List<CategoryModel> _categories = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Map<String, int> _cart = {};
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _errorMessage;

  // Getters
  List<Data> get apiMenuItems => _apiMenuItems;
  List<CategoryModel> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  Map<String, int> get cart => Map.unmodifiable(_cart);
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get errorMessage => _errorMessage;

  // Get all categories including "All"
  List<String> get categoryNames {
    List<String> names = ['All'];
    for (var category in _categories) {
      if (category.categoryName.isNotEmpty) {
        names.add(category.categoryName);
      }
    }
    return names.toSet().toList(); // Remove duplicates
  }

  // Filtered items based on selected category and search
  List<Data> get filteredItems {
    var filtered = List<Data>.from(_apiMenuItems);

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((item) {
            final itemCategory = item.categoryName;
            if (itemCategory != null && itemCategory.isNotEmpty) {
              return itemCategory.toLowerCase() ==
                  _selectedCategory.toLowerCase();
            }
            return false;
          }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((item) {
            final productName = item.productName ?? '';
            final description = item.description ?? '';
            final searchLower = _searchQuery.toLowerCase();
            return productName.toLowerCase().contains(searchLower) ||
                description.toLowerCase().contains(searchLower);
          }).toList();
    }

    return filtered;
  }

  // Extract categories from menu items
  Future<void> loadCategories({int outletId = 10048}) async {
    _isCategoriesLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Extract categories from existing menu items
      if (_apiMenuItems.isNotEmpty) {
        Set<String> uniqueCategories = {};
        List<CategoryModel> tempCategories = [];

        for (var item in _apiMenuItems) {
          final categoryName = item.categoryName;
          final categoryId = item.categoryId;

          if (categoryName != null &&
              categoryName.isNotEmpty &&
              categoryId != null &&
              !uniqueCategories.contains(categoryName)) {
            uniqueCategories.add(categoryName);
            tempCategories.add(
              CategoryModel(categoryId: categoryId, categoryName: categoryName),
            );
          }
        }

        _categories = tempCategories;

        // Reset selected category if it no longer exists
        final currentCategoryNames = categoryNames;
        if (_selectedCategory != 'All' &&
            !currentCategoryNames.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading categories: $e';
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  // Load menu items from API
  Future<void> loadMenuItems({int outletId = 10048}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final endpoint = 'product/GetItemSearch';
      final body = {
        "itemCode": "",
        "itemName": "",
        "isItemCode": false,
        "outletId": outletId,
      };

      final response = await ApiService.apiRequestHttpRawBody(
        endpoint,
        body,
        method: 'POST',
      );

      if (response != null) {
        final isSuccess = response['isSuccess'];
        if (isSuccess != null && isSuccess == true) {
          final menuApiRes = MenuApiResModel.fromJson(response);
          final data = menuApiRes.data;
          if (data != null) {
            _apiMenuItems = data;
          } else {
            _apiMenuItems = [];
          }
        } else {
          _errorMessage = 'Failed to load menu items';
        }
      } else {
        _errorMessage = 'No response from server';
      }
    } catch (e) {
      _errorMessage = 'Error loading menu items: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load menu items first, then extract categories
  Future<void> loadMenuData({int outletId = 10048}) async {
    // Load menu items first
    await loadMenuItems(outletId: outletId);
    // Then extract categories from menu items
    await loadCategories(outletId: outletId);
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Select category
  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Cart operations
  void addToCart(String itemId) {
    if (itemId.isNotEmpty) {
      final currentQuantity = _cart[itemId] ?? 0;
      _cart[itemId] = currentQuantity + 1;
      notifyListeners();
    }
  }

  void removeFromCart(String itemId) {
    if (itemId.isNotEmpty && _cart.containsKey(itemId)) {
      final currentQuantity = _cart[itemId];
      if (currentQuantity != null) {
        if (currentQuantity > 1) {
          _cart[itemId] = currentQuantity - 1;
        } else {
          _cart.remove(itemId);
        }
      }
      notifyListeners();
    }
  }

  int getCartQuantity(String itemId) {
    if (itemId.isEmpty) return 0;
    return _cart[itemId] ?? 0;
  }

  int get totalCartItems {
    int total = 0;
    for (var quantity in _cart.values) {
      if (quantity != null) {
        total += quantity;
      }
    }
    return total;
  }

  double calculateTotal() {
    double total = 0.0;
    for (var entry in _cart.entries) {
      final itemId = entry.key;
      final quantity = entry.value;
      if (itemId.isNotEmpty && quantity != null && quantity > 0) {
        try {
          final item = _apiMenuItems.firstWhere(
            (item) => item.productId == itemId,
            orElse: () => Data(),
          );
          final price = item.productPrice;
          if (price != null) {
            total += price.toDouble() * quantity.toDouble();
          }
        } catch (e) {
          // Item not found, skip
          continue;
        }
      }
    }
    return total;
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
