import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/core/constants/api_constants.dart';
import 'package:restaurant_pos_system/data/models/menu_api_res_model.dart';
import '../models/category_model.dart';
import 'package:restaurant_pos_system/data/remote/api_service.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';

class MenuProvider with ChangeNotifier {
  // Menu items from API
  List<Data> _apiMenuItems = [];

  // Categories from API
  List<CategoryModel> _categories = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDietaryFilter = 'All'; // 'All', 'Veg', 'Non-Veg'

  // Multi-table state management (cart removed - handled by AnimatedCartProvider)
  final Map<String, String> _tableWiseSearchQuery =
      {}; // Table ID -> Search Query
  final Map<String, String> _tableWiseCategory =
      {}; // Table ID -> Selected Category
  final Map<String, String> _tableWiseDietaryFilter =
      {}; // Table ID -> Dietary Filter ('All', 'Veg', 'Non-Veg')
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
  String get selectedDietaryFilter =>
      _currentTableId != null
          ? (_tableWiseDietaryFilter[_currentTableId] ?? 'All')
          : _selectedDietaryFilter;
  Map<String, int> get cart =>
      const <
        String,
        int
      >{}; // Always empty - cart handled by AnimatedCartProvider
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String? get errorMessage => _errorMessage;

  // Cart functionality removed from MenuProvider - handled by AnimatedCartProvider

  // Table management
  void switchToTable(String? tableId) {
    _currentTableId = tableId;
    notifyListeners();
  }

  void clearTableData(String tableId) {
    _tableWiseSearchQuery.remove(tableId);
    _tableWiseCategory.remove(tableId);
    _tableWiseDietaryFilter.remove(tableId);
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

    // Filter by category (use getter to support table-wise categories)
    if (selectedCategory != 'All') {
      filtered =
          filtered.where((item) {
            final itemCategory = item.categoryName;
            if (itemCategory != null && itemCategory.isNotEmpty) {
              return itemCategory.toLowerCase() ==
                  selectedCategory.toLowerCase();
            }
            return false;
          }).toList();
    }

    // Filter by dietary preference
    if (selectedDietaryFilter != 'All') {
      final isVegFilter = selectedDietaryFilter == 'Veg';
      filtered =
          filtered
              .where((item) => (item.pureVeg ?? false) == isVegFilter)
              .toList();
    }

    // Filter by search query (use getter to support table-wise search)
    if (searchQuery.isNotEmpty) {
      filtered =
          filtered.where((item) {
            final productName = item.productName ?? '';
            final description = item.description ?? '';
            final searchLower = searchQuery.toLowerCase();
            return productName.toLowerCase().contains(searchLower) ||
                description.toLowerCase().contains(searchLower);
          }).toList();
    }

    return filtered;
  }

  // Extract categories from menu items
  Future<void> loadCategories({required int outletId}) async {
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

  // MAIN FIX: Load menu items from API with token guard
  Future<void> loadMenuItems({required int outletId}) async {
    // TOKEN CHECK - THIS PREVENTS 500 ERRORS ON FIRST LAUNCH
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

    // OUTLET ID CHECK
    if (outletId <= 0) {
      debugPrint(
        'Invalid outlet ID ($outletId) - skipping menu load in MenuProvider',
      );
      _apiMenuItems = [];
      _errorMessage = 'Invalid outlet ID. Cannot load menu items.';
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
        "outletId": HiveService.getOutletId() ?? outletId,
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
  Future<void> loadMenuData({required int outletId}) async {
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

  // Select dietary filter
  void selectDietaryFilter(String filter) {
    if (_currentTableId != null) {
      _tableWiseDietaryFilter[_currentTableId!] = filter;
    } else {
      _selectedDietaryFilter = filter;
    }
    notifyListeners();
  }

  // Cart operations - REMOVED: No longer track cart quantities in MenuProvider
  // The AnimatedCartProvider handles all cart functionality
  void addToCart(String itemId) {
    // No-op: Cart functionality moved to AnimatedCartProvider
    // This method kept for compatibility but does nothing
  }

  void removeFromCart(String itemId) {
    // No-op: Cart functionality moved to AnimatedCartProvider
    // This method kept for compatibility but does nothing
  }

  int getCartQuantity(String itemId) {
    // Always return 0 to prevent auto-selection in menu
    return 0;
  }

  int get totalCartItems {
    // Always return 0 since we're not tracking cart in MenuProvider anymore
    return 0;
  }

  double calculateTotal() {
    // Always return 0 since we're not tracking cart in MenuProvider anymore
    return 0.0;
  }

  void clearCart() {
    // No-op: Cart functionality moved to AnimatedCartProvider
  }

  // Helper to look up product image URL by productId
  String? getImageUrlForProduct(String productId) {
    if (_apiMenuItems.isEmpty || productId.isEmpty) return null;
    for (final item in _apiMenuItems) {
      if (item.productId == productId) {
        final url = item.imageThumbUrl ?? item.imageUrl;
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
