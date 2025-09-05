import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_pos_system/core/constants/api_constants.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart';
import 'package:restaurant_pos_system/services/api_service.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/table_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/menu_provider.dart';
import 'package:restaurant_pos_system/presentation/view_models/providers/tax_provider.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUser;
  String? _userRole;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  // Existing getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  // New getters for login form
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;

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

      final model = AuthApiResModel.fromJson(response!);

      if (model.isSuccess == true && model.data != null) {
        // Save token to hive
        await HiveService.saveAuthToken(model.data?.posToken ?? '');

        // Save auth data to hive
        await HiveService.saveAuthData(model);

        _isAuthenticated = true;
        _currentUser = username;
        _userRole = 'Manager'; // Set based on your API response
        _rememberMe = rememberMe;

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
        _errorMessage = 'Oops! Something doesn\'t match. Try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('Error in login: $e');
      }

      return false;
    }
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

      // Only initialize TableProvider for now (the main issue)
      await tableProvider.fetchTables().catchError((error) {
        debugPrint('Failed to load tables: $error');
        return; // Continue even if tables fail
      });

      // TODO: Add other providers when their methods are available
      // Example:
      // final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      // await menuProvider.loadMenu(); // Use the actual method name

      // final taxProvider = Provider.of<TaxProvider>(context, listen: false);
      // await taxProvider.fetchTaxes(); // Use the actual method name

      if (kDebugMode) {
        debugPrint('Post-login table data loaded successfully');
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
