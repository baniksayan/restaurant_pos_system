import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_settings/app_settings.dart';

enum NetworkStatus { connected, disconnected, slow, checking }

class NetworkProvider extends ChangeNotifier {
  NetworkStatus _status = NetworkStatus.checking;
  bool _isDialogShown = false;
  String _networkMessage = '';
  bool _showRestoredBanner = false;
  bool _hasEverDisconnected = false;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _heartbeatTimer;
  Timer? _restoredBannerTimer;
  bool _isChecking = false;

  final List<VoidCallback> _onRestoredCallbacks = [];

  NetworkStatus get status => _status;
  bool get isDialogShown => _isDialogShown;
  String get networkMessage => _networkMessage;
  bool get showRestoredBanner => _showRestoredBanner;

  bool get isConnected => _status == NetworkStatus.connected;
  bool get isDisconnected => _status == NetworkStatus.disconnected;
  bool get isSlow => _status == NetworkStatus.slow;
  bool get isCheckingStatus => _status == NetworkStatus.checking;

  void addRestoredCallback(VoidCallback callback) {
    if (!_onRestoredCallbacks.contains(callback)) {
      _onRestoredCallbacks.add(callback);
    }
  }

  void removeRestoredCallback(VoidCallback callback) {
    _onRestoredCallbacks.remove(callback);
  }

  void initialize() {
    _checkConnectivity(notifyChecking: false);
    _listenToConnectivityChanges();
    _startHeartbeat();
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (result == ConnectivityResult.none) {
          _updateStatus(NetworkStatus.disconnected, 'No internet connection');
        } else {
          _checkConnectivity(notifyChecking: false);
        }
      },
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      // Background ping to catch silent WAN loss or auto-detect recovery
      _checkConnectivity(notifyChecking: false, isHeartbeat: true);
    });
  }

  Future<void> _checkConnectivity({
    bool notifyChecking = true,
    bool isHeartbeat = false,
  }) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      if (notifyChecking && _status != NetworkStatus.checking) {
        _status = NetworkStatus.checking;
        notifyListeners();
      }

      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _updateStatus(NetworkStatus.disconnected, 'No network interface');
        return;
      }

      // Verify actual internet connectivity via DNS lookup
      await _testInternetConnection();
    } catch (e) {
      _updateStatus(NetworkStatus.disconnected, 'Connection error: $e');
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _testInternetConnection() async {
    try {
      final stopwatch = Stopwatch()..start();

      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(milliseconds: 2500));

      stopwatch.stop();

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        final elapsed = stopwatch.elapsedMilliseconds;
        if (elapsed < 3500) {
          _updateStatus(NetworkStatus.connected, 'Connected');
        } else {
          _updateStatus(NetworkStatus.slow, 'Slow connection detected');
        }
      } else {
        _updateStatus(NetworkStatus.disconnected, 'No internet access');
      }
    } catch (_) {
      // Fallback check to 1.1.1.1 / cloudflare
      try {
        final fallback = await InternetAddress.lookup(
          'cloudflare.com',
        ).timeout(const Duration(milliseconds: 2000));
        if (fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty) {
          _updateStatus(NetworkStatus.connected, 'Connected');
          return;
        }
      } catch (_) {}

      _updateStatus(NetworkStatus.disconnected, 'Unable to connect to internet');
    }
  }

  void _updateStatus(NetworkStatus newStatus, String message) {
    final previousStatus = _status;
    _status = newStatus;
    _networkMessage = message;

    if (newStatus == NetworkStatus.disconnected) {
      _hasEverDisconnected = true;
      _showRestoredBanner = false;
      _restoredBannerTimer?.cancel();
    } else if (newStatus == NetworkStatus.connected) {
      if (_hasEverDisconnected && previousStatus == NetworkStatus.disconnected) {
        _triggerConnectionRestored();
      }
    }

    notifyListeners();

    if (kDebugMode) {
      debugPrint('Network Status: ${newStatus.name} - $message');
    }
  }

  void _triggerConnectionRestored() {
    _hasEverDisconnected = false;
    _showRestoredBanner = true;

    // Fire registered callbacks to reload data automatically across screens
    for (final cb in List.of(_onRestoredCallbacks)) {
      try {
        cb();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[NetworkProvider] Restored callback error: $e');
        }
      }
    }

    _restoredBannerTimer?.cancel();
    _restoredBannerTimer = Timer(const Duration(milliseconds: 2800), () {
      _showRestoredBanner = false;
      notifyListeners();
    });
  }

  Future<void> retryConnection() async {
    await _checkConnectivity(notifyChecking: true);
  }

  Future<void> openWifiSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.wifi);
    } catch (e) {
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
      } catch (_) {}
    }
  }

  Future<void> openMobileDataSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.dataRoaming);
    } catch (e) {
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
      } catch (_) {}
    }
  }

  Future<void> openGeneralSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
    } catch (_) {}
  }

  void setDialogShown(bool shown) {
    _isDialogShown = shown;
    notifyListeners();
  }

  @visibleForTesting
  void setStatusForTesting(NetworkStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _heartbeatTimer?.cancel();
    _restoredBannerTimer?.cancel();
    super.dispose();
  }
}
