import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUser;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple validation - replace with real authentication
    if (username.isNotEmpty && password.length >= 3) {
      _isAuthenticated = true;
      _currentUser = username;
    } else {
      throw Exception('Invalid credentials');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
