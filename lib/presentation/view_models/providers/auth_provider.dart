import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restaurant_pos_system/core/constants/api_constants.dart';
import 'package:restaurant_pos_system/data/models/auth_api_res_model.dart';
import 'package:restaurant_pos_system/services/api_service.dart';

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
  Future<void> checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate splash screen delay
      await Future.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('current_user');
      final savedRole = prefs.getString('user_role');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && savedUser != null) {
        _isAuthenticated = true;
        _currentUser = savedUser;
        _userRole = savedRole ?? 'Manager';
        _rememberMe = true;
      }
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      _errorMessage = 'Error checking authentication state';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Updated login method with API integration
  Future<bool> login(
    BuildContext context,
    String username,
    String password, {
    bool rememberMe = false,
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
        //saved token to hive
        await HiveService.saveAuthToken(model.data?.posToken ?? '');
        //saving auth data to hive
        await HiveService.saveAuthData(model);
        _isAuthenticated = true;
        _currentUser = username;
        _userRole = 'Manager'; // Set based on your API response
        _rememberMe = rememberMe;

        // Save login state if remember me is checked
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user', username);
          await prefs.setString('user_role', _userRole ?? 'Manager');
          await prefs.setBool('remember_me', true);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Oops! Something doesn’t match. Try again.';
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

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.remove('user_role');
      await prefs.setBool('remember_me', false);

      // Clear provider state
      _isAuthenticated = false;
      _currentUser = null;
      _userRole = null;
      _rememberMe = false;
      _errorMessage = null;

      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error during logout: $e');
      _errorMessage = 'Error during logout';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to update user profile
  void updateUserProfile(String name, String role) {
    _currentUser = name;
    _userRole = role;
    notifyListeners();
  }
}
