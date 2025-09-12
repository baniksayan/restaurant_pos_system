import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/api_constants.dart';
import '../../../data/models/menu_api_res_model.dart';
import '../../../data/models/category_model.dart';
import '../../../services/api_service.dart';
import '../../../data/local/hive_service.dart';

class MenuProvider with ChangeNotifier {
  // Menu items from API
  List<Data> _apiMenuItems = [];

  // Categories from API
  List<CategoryModel> _categories = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Multi-table cart and state management
  final Map<String, Map<String, int>> _tableWiseCarts = {}; // Table ID -> Cart
  final Map<String, String> _tableWiseSearchQuery =
      {}; // Table ID -> Search Query
  final Map<String, String> _tableWiseCategory =
      {}; // Table ID -> Selected Category
  String? _currentTableId;

  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String? _errorMessage;

  // Getters
  List<Data> get apiMenuItems => _apiMenuItems;
  List<CategoryModel> get categories => _categories;
  String get searchQuery =>
      _currentTableId != null
          ? (_tableWiseSearchQuery[_currentTableId] ?? '')
          : _searchQuery;
  String get selectedCategory =>
      _currentTableId != null
          ? (_tableWiseCategory[_currentTableId] ?? 'All')
          : _selectedCategory;
  Map<String, int> get cart =>
      _currentTableId != null
          ? Map.unmodifiable(_tableWiseCarts[_currentTableId] ?? {})
          : const <String, int>{};
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get errorMessage => _errorMessage;

  // Helper methods for current table cart
  Map<String, int> _getCurrentCart() {
    if (_currentTableId == null) return <String, int>{};
    return _tableWiseCarts[_currentTableId!] ??= <String, int>{};
  }

  // Table management
  void switchToTable(String? tableId) {
    _currentTableId = tableId;
    notifyListeners();
  }

  void clearTableData(String tableId) {
    _tableWiseCarts.remove(tableId);
    _tableWiseSearchQuery.remove(tableId);
    _tableWiseCategory.remove(tableId);
    notifyListeners();
  }

  String? get currentTableId => _currentTableId;

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

  // 🔥 MAIN FIX: Load menu items from API with token guard
  Future<void> loadMenuItems({int outletId = 10048}) async {
    // ✅ TOKEN CHECK - THIS PREVENTS 500 ERRORS ON FIRST LAUNCH
    final token = HiveService.getAuthToken();
    if (token.isEmpty) {
      debugPrint(
        'No auth token available - skipping menu load in MenuProvider',
      );
      _apiMenuItems = [];
      _errorMessage = null; // Don't show error for expected behavior
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        "itemCode": "",
        "itemName": "",
        "isItemCode": false,
        "outletId": outletId,
      };

      final response = await ApiService.apiRequestHttpRawBody(
        ApiConstants.getItemSearch,
        body,
        method: 'POST',
      );

      if (response != null) {
        final isSuccess = response['isSuccess'];
        if (isSuccess != null && isSuccess == true) {
          final menuApiRes = MenuApiResModel.fromJson(response);
          final data = menuApiRes.data;
          if (data != null) {
            // Deduplicate items by productId to prevent duplicates
            final uniqueItems = <String, Data>{};
            for (final item in data) {
              if (item.productId != null) {
                uniqueItems[item.productId!] = item;
              }
            }
            _apiMenuItems = uniqueItems.values.toList();
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
    if (_currentTableId != null) {
      _tableWiseSearchQuery[_currentTableId!] = query;
    } else {
      _searchQuery = query;
    }
    notifyListeners();
  }

  // Select category
  void selectCategory(String category) {
    if (_currentTableId != null) {
      _tableWiseCategory[_currentTableId!] = category;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  // Cart operations
  void addToCart(String itemId) {
    try {
      final cart = _getCurrentCart();
      final currentQuantity = cart[itemId] ?? 0;
      cart[itemId] = currentQuantity + 1;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to add item to cart: $e";
      notifyListeners();
    }
  }

  void removeFromCart(String itemId) {
    final cart = _getCurrentCart();
    if (itemId.isNotEmpty && cart.containsKey(itemId)) {
      final currentQuantity = cart[itemId];
      if (currentQuantity != null) {
        if (currentQuantity > 1) {
          cart[itemId] = currentQuantity - 1;
        } else {
          cart.remove(itemId);
        }
        notifyListeners();
      }
    }
  }

  int getCartQuantity(String itemId) {
    if (itemId.isEmpty) return 0;
    final cart = _getCurrentCart();
    return cart[itemId] ?? 0;
  }

  int get totalCartItems {
    int total = 0;
    final cart = _getCurrentCart();
    for (var quantity in cart.values) {
      total += quantity;
    }
    return total;
  }

  double calculateTotal() {
    double total = 0.0;
    final cart = _getCurrentCart();
    for (var entry in cart.entries) {
      final itemId = entry.key;
      final quantity = entry.value;

      if (itemId.isNotEmpty && quantity > 0) {
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
    if (_currentTableId != null) {
      _tableWiseCarts[_currentTableId!]?.clear();
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
