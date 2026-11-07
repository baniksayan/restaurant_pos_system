import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_settings/app_settings.dart';

enum NetworkStatus { connected, disconnected, slow, checking }

class NetworkProvider extends ChangeNotifier with WidgetsBindingObserver {
  NetworkStatus _status = NetworkStatus.checking;
  bool _isDialogShown = false;
  String _networkMessage = '';
  bool _showRestoredBanner = false;
  bool _hasEverDisconnected = false;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _heartbeatTimer;
  Timer? _restoredBannerTimer;
  Timer? _noneDebounceTimer;
  Timer? _resumeGraceTimer;
  Timer? _confirmationTimer;

  bool _isChecking = false;
  bool _pendingCheck = false;
  bool _isAppForeground = true;
  int _consecutiveFailures = 0;
  static const int _failureThreshold = 3;

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
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity(notifyChecking: false);
    _listenToConnectivityChanges();
    _startHeartbeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppForeground = true;
      _consecutiveFailures = 0;
      _startHeartbeat();
      // Allow network radios (Wi-Fi/Cellular) a generous grace period to wake from sleep / Doze mode
      _resumeGraceTimer?.cancel();
      _resumeGraceTimer = Timer(const Duration(milliseconds: 1200), () {
        if (_isAppForeground) {
          _checkConnectivity(notifyChecking: false, force: true);
        }
      });
    } else {
      // Screen locked, app paused or minimized
      _isAppForeground = false;
      _heartbeatTimer?.cancel();
      _noneDebounceTimer?.cancel();
      _confirmationTimer?.cancel();
      _resumeGraceTimer?.cancel();
      _restoredBannerTimer?.cancel();
      if (_showRestoredBanner) {
        _showRestoredBanner = false;
        notifyListeners();
      }
    }
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (!_isAppForeground) return;

        if (result == ConnectivityResult.none) {
          // Debounce transient interface blips (e.g. Wi-Fi to Cellular handover)
          _noneDebounceTimer?.cancel();
          _noneDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
            if (_isAppForeground) {
              _checkConnectivity(notifyChecking: false);
            }
          });
        } else {
          // Interface became active; cancel any pending disconnect check and verify
          _noneDebounceTimer?.cancel();
          _checkConnectivity(notifyChecking: false);
        }
      },
    );
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isAppForeground) {
        _checkConnectivity(notifyChecking: false, isHeartbeat: true);
      }
    });
  }

  Future<void> _checkConnectivity({
    bool notifyChecking = true,
    bool isHeartbeat = false,
    bool force = false,
  }) async {
    if (!_isAppForeground && !force) return;

    if (_isChecking) {
      _pendingCheck = true;
      return;
    }
    _isChecking = true;

    try {
      if (notifyChecking && _status != NetworkStatus.checking) {
        _status = NetworkStatus.checking;
        notifyListeners();
      }

      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _handleFailure('No network interface');
        return;
      }

      // Verify actual internet connectivity via DNS and direct socket
      final hasInternet = await _testInternetConnection();
      if (hasInternet) {
        _consecutiveFailures = 0;
        _updateStatus(NetworkStatus.connected, 'Connected');
      } else {
        _handleFailure('Unable to connect to internet');
      }
    } catch (e) {
      _handleFailure('Connection error: $e');
    } finally {
      _isChecking = false;
      if (_pendingCheck && _isAppForeground) {
        _pendingCheck = false;
        _checkConnectivity(notifyChecking: false);
      }
    }
  }

  void _handleFailure(String reason) {
    _consecutiveFailures++;

    if (_status == NetworkStatus.disconnected) {
      _updateStatus(NetworkStatus.disconnected, reason);
      return;
    }

    if (_consecutiveFailures >= _failureThreshold) {
      _updateStatus(NetworkStatus.disconnected, reason);
    } else {
      // Re-check once after 1.5 seconds to confirm failure before alarming user
      _confirmationTimer?.cancel();
      _confirmationTimer = Timer(const Duration(milliseconds: 1500), () {
        if (_isAppForeground) {
          _checkConnectivity(notifyChecking: false);
        }
      });
    }
  }

  Future<bool> _testInternetConnection() async {
    // 1. Primary DNS lookup to google.com
    try {
      final googleResult = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 3000));
      if (googleResult.isNotEmpty && googleResult[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // 2. Direct socket probe to Google DNS 8.8.8.8:53 (bypasses system DNS daemon latency on wake-up)
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(milliseconds: 2500),
      );
      socket.destroy();
      return true;
    } catch (_) {}

    // 3. Direct socket probe to Cloudflare DNS 1.1.1.1:53
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 2500),
      );
      socket.destroy();
      return true;
    } catch (_) {}

    // 4. Fallback DNS lookup to cloudflare.com
    try {
      final cloudflareResult = await InternetAddress.lookup('cloudflare.com')
          .timeout(const Duration(milliseconds: 2500));
      if (cloudflareResult.isNotEmpty &&
          cloudflareResult[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return false;
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
    // Allow fullscreen offline overlay to fade out smoothly (350ms) before pill glides down
    _restoredBannerTimer = Timer(const Duration(milliseconds: 350), () {
      if (_status == NetworkStatus.connected) {
        _showRestoredBanner = true;
        notifyListeners();

        _restoredBannerTimer?.cancel();
        _restoredBannerTimer = Timer(const Duration(milliseconds: 3500), () {
          _showRestoredBanner = false;
          notifyListeners();
        });
      }
    });
  }

  void dismissRestoredBanner() {
    if (_showRestoredBanner) {
      _restoredBannerTimer?.cancel();
      _showRestoredBanner = false;
      notifyListeners();
    }
  }

  Future<void> retryConnection() async {
    _consecutiveFailures = _failureThreshold;
    await _checkConnectivity(notifyChecking: true, force: true);
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
      // Opens Android's Wireless & Networks / SIM & Mobile Networks settings
      await AppSettings.openAppSettings(type: AppSettingsType.wireless);
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

  @visibleForTesting
  void setShowRestoredBannerForTesting(bool show) {
    _showRestoredBanner = show;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _heartbeatTimer?.cancel();
    _restoredBannerTimer?.cancel();
    _noneDebounceTimer?.cancel();
    _resumeGraceTimer?.cancel();
    _confirmationTimer?.cancel();
    super.dispose();
  }
}
