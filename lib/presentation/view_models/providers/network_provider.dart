import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum NetworkStatus { 
  connected, 
  disconnected, 
  slow,
  checking 
}

class NetworkProvider extends ChangeNotifier {
  NetworkStatus _status = NetworkStatus.checking;
  bool _isDialogShown = false;
  String _networkMessage = '';
  
  NetworkStatus get status => _status;
  bool get isDialogShown => _isDialogShown;
  String get networkMessage => _networkMessage;
  
  bool get isConnected => _status == NetworkStatus.connected;
  bool get isDisconnected => _status == NetworkStatus.disconnected;
  bool get isSlow => _status == NetworkStatus.slow;

  void initialize() {
    _checkConnectivity();
    _listenToConnectivityChanges();
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      _status = NetworkStatus.checking;
      notifyListeners();

      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        _updateStatus(NetworkStatus.disconnected, 'No internet connection');
        return;
      }

      // Test actual internet connection speed
      await _testInternetSpeed();
    } catch (e) {
      _updateStatus(NetworkStatus.disconnected, 'Connection error');
    }
  }

  Future<void> _testInternetSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        final responseTime = stopwatch.elapsedMilliseconds;
        
        if (responseTime < 3000) {
          _updateStatus(NetworkStatus.connected, 'Connected');
        } else {
          _updateStatus(NetworkStatus.slow, 'Slow connection detected');
        }
      } else {
        _updateStatus(NetworkStatus.disconnected, 'No internet access');
      }
    } catch (e) {
      _updateStatus(NetworkStatus.disconnected, 'Unable to connect');
    }
  }

  void _updateStatus(NetworkStatus newStatus, String message) {
    _status = newStatus;
    _networkMessage = message;
    notifyListeners();

    if (kDebugMode) {
      debugPrint('Network Status: ${newStatus.name} - $message');
    }
  }

  Future<void> retryConnection() async {
    await _checkConnectivity();
  }

  void setDialogShown(bool shown) {
    _isDialogShown = shown;
    notifyListeners();
  }
}
