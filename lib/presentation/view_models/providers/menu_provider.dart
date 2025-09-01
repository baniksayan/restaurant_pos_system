import 'package:flutter/material.dart';
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
