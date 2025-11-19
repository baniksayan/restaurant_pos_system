import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_pos_system/core/constants/api_constants.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart';
import 'package:restaurant_pos_system/services/api_service.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/table_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/tax_provider.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUser;
  String? _userRole;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _shouldNavigateDirectlyToMenu = false;
  String? _autoSelectedTableId;
  String? _autoSelectedTableName;

  // Existing getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  // New getters for login form
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;

  // New getters for direct menu navigation
  bool get shouldNavigateDirectlyToMenu => _shouldNavigateDirectlyToMenu;
  String? get autoSelectedTableId => _autoSelectedTableId;
  String? get autoSelectedTableName => _autoSelectedTableName;

  // New methods for login form
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Initialize and check for saved login state
  Future<bool> checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate splash screen delay
      await Future.delayed(const Duration(seconds: 2));

      // Check if user was previously logged in (persisted state)
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('current_user');
      final savedRole = prefs.getString('user_role');
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final authToken = HiveService.getAuthToken();

      // FIX: If we have saved credentials AND valid token, user is still logged in
      if (rememberMe && savedUser != null && authToken.isNotEmpty) {
        _isAuthenticated = true;
        _currentUser = savedUser;
        _userRole = savedRole ?? 'Manager';
        _rememberMe = true;

        if (kDebugMode) {
          debugPrint('User restored from saved state: $savedUser');
        }

        _isLoading = false;
        notifyListeners();
        return true; // User is authenticated
      }

      // No valid saved state, user needs to login
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false; // User needs to login
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      _errorMessage = 'Error checking authentication state';
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update login to always save state for persistence
  Future<bool> login(
    BuildContext context,
    String username,
    String password, {
    bool rememberMe = true, // Default to true for development
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use your existing API call structure
      final body = {
        "userId": username,
        "password": password,
        "companyCode": "",
        "connectionString": "",
        "url": "",
      };

      if (kDebugMode) {
        debugPrint('Request Body: $body');
      }

      final response = await ApiService.apiRequestHttpRawBody(
        ApiConstants.auth,
        body,
        method: 'POST',
      );

      if (response == null) {
        _errorMessage =
            'No response from server. Please check your connection.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Safe casting to handle both Map<dynamic, dynamic> and Map<String, dynamic>
      final Map<String, dynamic> safeResponse = Map<String, dynamic>.from(
        response,
      );
      final model = AuthApiResModel.fromJson(safeResponse);

      if (kDebugMode) {
        debugPrint('Auth API Response: $safeResponse');
        debugPrint('Model isSuccess: ${model.isSuccess}');
        debugPrint('Model message: ${model.message}');
        debugPrint('Status Code: ${model.statusCode}');
      }

      if (model.isSuccess == true && model.data != null) {
        // Save token to hive
        await HiveService.saveAuthToken(model.data?.posToken ?? '');

        debugPrint('Saved Token: ${HiveService.getAuthToken()}');
        debugPrint('Saved Token from api const.: ${ApiConstants.accessToken}');
        HiveService.setUserId(model.data?.userDetails?.userId ?? '');
        HiveService.setWaiterId("cceb307f-2f01-4e0e-8f28-e07ba8e941ac");

        // Extract and save outlet ID from locationId (as specified by user)
        debugPrint('=== OUTLET ID PROCESSING ===');
        debugPrint('Full API Response Data: ${model.data?.location?.toJson()}');

        final locationId = model.data?.location?.locationId;
        debugPrint('Extracted locationId from API: $locationId');

        // Save locationId as outlet ID (as per user's requirement)
        HiveService.setOutletId(locationId ?? 10080);

        final savedOutletId = HiveService.getOutletId();
        debugPrint('Final outlet ID saved to Hive: $savedOutletId');
        debugPrint('=== OUTLET ID PROCESSING END ===');

        // Save auth data to hive
        await HiveService.saveAuthData(model);

        _isAuthenticated = true;
        _currentUser = username;
        _userRole = 'Manager'; // Set based on your API response
        _rememberMe = rememberMe;

        // Check if companySiteUrl is "Menu" for direct menu navigation
        final companySiteUrl = model.data?.userDetails?.companySiteUrl;
        if (companySiteUrl != null && companySiteUrl.isNotEmpty) {
          // Store companySiteUrl in Hive
          HiveService.setCompanySiteUrl(companySiteUrl);
          if (kDebugMode) {
            debugPrint('Stored companySiteUrl in Hive: $companySiteUrl');
          }

          if (companySiteUrl.toLowerCase() == 'menu') {
            if (kDebugMode) {
              debugPrint(
                'companySiteUrl is "Menu" - preparing for direct menu navigation',
              );
            }

            // Fetch tables and auto-select the first available one
            await _setupAutoTableSelection(context);
          } else {
            _shouldNavigateDirectlyToMenu = false;
            _autoSelectedTableId = null;
            _autoSelectedTableName = null;
          }
        } else {
          _shouldNavigateDirectlyToMenu = false;
          _autoSelectedTableId = null;
          _autoSelectedTableName = null;
        }

        // ALWAYS save login state for persistence during development
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', username);
        await prefs.setString('user_role', _userRole ?? 'Manager');
        await prefs.setBool('remember_me', true); // Always true for persistence

        if (kDebugMode) {
          debugPrint('User logged in and state persisted: $username');
        }

        // **NEW: Initialize data providers after successful login**
        await _initializeDataProviders(context);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Handle different error scenarios
        if (model.statusCode == 500) {
          _errorMessage =
              'Server error. Please try again later or contact support.';
        } else if (model.message != null && model.message!.isNotEmpty) {
          _errorMessage = model.message!;
        } else {
          _errorMessage =
              'Authentication failed. Please check your credentials.';
        }

        if (kDebugMode) {
          debugPrint('Login failed: ${model.message}');
          debugPrint('Status Code: ${model.statusCode}');
        }

        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      // More user-friendly error messages
      if (e.toString().contains(
        'type \'_Map<dynamic, dynamic>\' is not a subtype',
      )) {
        _errorMessage = 'Server response error. Please try again.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkImageLoadException')) {
        _errorMessage = 'No internet connection. Please check your network.';
      } else if (e.toString().contains('TimeoutException')) {
        _errorMessage = 'Connection timeout. Please try again.';
      } else {
        _errorMessage = 'Login failed. Please try again.';
      }

      _isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('Error in login: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      return false;
    }
  }

  // **NEW: Public method to setup automatic table selection for direct menu navigation**
  Future<void> setupAutoTableSelection(BuildContext context) async {
    await _setupAutoTableSelection(context);
  }

  // **NEW: Private method to setup automatic table selection for direct menu navigation**
  Future<void> _setupAutoTableSelection(BuildContext context) async {
    try {
      if (kDebugMode) {
        debugPrint(
          'Setting up auto table selection for direct menu navigation',
        );
      }

      // Get the table provider to fetch tables
      final tableProvider = Provider.of<TableProvider>(context, listen: false);

      // Ensure tables are loaded
      await tableProvider.fetchTables();

      // Find the first available table
      final tables = tableProvider.tables;
      if (tables.isNotEmpty) {
        // Find first available table, or if none available, use the first table
        final availableTable = tables.firstWhere(
          (table) => table.status.toString().contains('available'),
          orElse: () => tables.first,
        );

        _shouldNavigateDirectlyToMenu = true;
        _autoSelectedTableId = availableTable.id;
        _autoSelectedTableName = availableTable.name;

        if (kDebugMode) {
          debugPrint(
            'Auto-selected table: ${availableTable.name} (${availableTable.id})',
          );
        }

        // **ENHANCED: Automatically create order for the selected table**
        // This ensures orderId is ready for KOT generation without showing table UI
        if (kDebugMode) {
          debugPrint(
            'companySiteUrl="Menu" - Creating background order for table ${availableTable.name}',
          );
        }

        final orderCreated = await tableProvider.createOrderForTable(
          availableTable.id,
          availableTable.name,
        );

        if (orderCreated) {
          if (kDebugMode) {
            debugPrint(
              '✅ Background order created successfully for direct menu access',
            );
            debugPrint('OrderId ready: ${tableProvider.currentOrderId}');
          }
        } else {
          if (kDebugMode) {
            debugPrint(
              '❌ Failed to create background order - menu may not work properly',
            );
          }
          // Don't fail login, but warn that KOT generation might not work
        }
      } else {
        if (kDebugMode) {
          debugPrint('No tables available for auto-selection');
        }
        _shouldNavigateDirectlyToMenu = false;
        _autoSelectedTableId = null;
        _autoSelectedTableName = null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting up auto table selection: $e');
      }
      _shouldNavigateDirectlyToMenu = false;
      _autoSelectedTableId = null;
      _autoSelectedTableName = null;
    }
  }

  // Method to reset auto navigation flags
  void resetAutoNavigationFlags() {
    _shouldNavigateDirectlyToMenu = false;
    _autoSelectedTableId = null;
    _autoSelectedTableName = null;
    notifyListeners();
  }

  // **NEW: Private method to initialize data providers after authentication**
  // **NEW: Private method to initialize data providers after authentication**
  Future<void> _initializeDataProviders(BuildContext context) async {
    try {
      if (kDebugMode) {
        debugPrint('Initializing authenticated data providers...');
      }

      // Get providers from context
      final tableProvider = Provider.of<TableProvider>(context, listen: false);
      final taxProvider = Provider.of<TaxProvider>(context, listen: false);

      // Initialize TableProvider
      await tableProvider.fetchTables().catchError((error) {
        debugPrint('Failed to load tables: $error');
        return; // Continue even if tables fail
      });

      // Initialize TaxProvider - load from Hive or fetch from API
      await taxProvider.initializeTaxData().catchError((error) {
        debugPrint('Failed to load tax data: $error');
        return; // Continue even if tax data fails
      });

      // Give a small delay and try again if no tax data was loaded
      if (!taxProvider.hasTaxData) {
        debugPrint(
          '⚠️ No tax data after first attempt, trying again in 1 second...',
        );
        await Future.delayed(const Duration(seconds: 1));
        await taxProvider.refreshTaxData().catchError((error) {
          debugPrint('Second attempt to load tax data failed: $error');
          return;
        });
      }

      if (kDebugMode) {
        debugPrint('Post-login data loaded successfully');
        debugPrint(
          'Tax data status: ${taxProvider.hasTaxData ? "Loaded" : "Using defaults"}',
        );
        if (taxProvider.hasTaxData) {
          debugPrint(
            'CGST: ${taxProvider.cgstPercentage}%, SGST: ${taxProvider.sgstPercentage}%',
          );
        }
      }
    } catch (e) {
      // Don't throw error, just log it
      if (kDebugMode) {
        debugPrint('Error loading post-login data: $e');
      }
    }
  }

  // ONLY clear auth state on manual logout - Updated method
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear stored credentials from all sources
      await _clearStoredCredentials();

      // Clear user cache and data
      await _clearUserCache();

      // Reset user state
      _isAuthenticated = false;
      _currentUser = null;
      _userRole = null;
      _rememberMe = false;
      _errorMessage = null;

      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (kDebugMode) {
        debugPrint('User manually logged out - state cleared');
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      throw Exception('Logout failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Private method to clear stored credentials
  Future<void> _clearStoredCredentials() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('user_role');
      await prefs.setBool('remember_me', false);

      // Clear Hive storage (auth token and data)
      try {
        await HiveService.clearAuthToken();
        await HiveService.clearAuthData();
      } catch (hiveError) {
        if (kDebugMode) {
          debugPrint('Error clearing Hive data: $hiveError');
        }
        // Don't throw error for Hive operations, continue with other cleanup
      }

      if (kDebugMode) {
        debugPrint('Stored credentials cleared successfully');
      }
    } catch (e) {
      debugPrint('Error clearing stored credentials: $e');
      throw Exception('Failed to clear stored credentials: ${e.toString()}');
    }
  }

  // Private method to clear user cache and temporary data
  Future<void> _clearUserCache() async {
    try {
      // Reset any other user-related state that should not persist after logout
      // This is where you would clear any other cached data specific to your app
      // Example: Clear any temporary files, cached images, etc.
      // You can add specific cache clearing logic here based on your app's needs

      if (kDebugMode) {
        debugPrint('User cache cleared successfully');
      }
    } catch (e) {
      debugPrint('Error clearing user cache: $e');
      // Don't throw error for cache clearing, it's not critical
    }
  }

  // Method to check if logout is in progress
  bool get isLoggingOut => _isLoading && !_isAuthenticated;

  // Method to update user profile
  void updateUserProfile(String name, String role) {
    _currentUser = name;
    _userRole = role;
    notifyListeners();
  }

  // Method to force logout (for emergency cases)
  Future<void> forceLogout() async {
    try {
      // Immediately reset state
      _isAuthenticated = false;
      _currentUser = null;
      _userRole = null;
      _rememberMe = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();

      // Clear credentials in background
      unawaited(_clearStoredCredentials());
      unawaited(_clearUserCache());

      if (kDebugMode) {
        debugPrint('Force logout completed');
      }
    } catch (e) {
      debugPrint('Error during force logout: $e');
    }
  }

  // Helper method for unawaited futures
  void unawaited(Future future) {
    future.catchError((error) {
      debugPrint('Unawaited future error: $error');
    });
  }
}
