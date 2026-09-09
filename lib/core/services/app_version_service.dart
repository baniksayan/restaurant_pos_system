import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  AppVersionService._();

  static PackageInfo? _packageInfo;
  static String _displayVersion = '';

  /// Returns the current app version formatted cleanly as "Version X.Y.Z" or "Version X.Y.Z.W",
  /// dynamically retrieved at startup from pubspec.yaml via PackageInfo.
  static String get currentVersion => _displayVersion;

  /// Returns user-friendly version string, e.g. "Version 1.1.1"
  static String get displayVersion => _displayVersion;

  /// Returns the underlying [PackageInfo] if initialized
  static PackageInfo? get packageInfo => _packageInfo;

  /// Formats raw version strings from pubspec.yaml into clean "Version X.Y.Z" or "Version X.Y.Z.W" format.
  static String formatVersion(String rawVersion) {
    String cleaned = rawVersion.trim();
    if (cleaned.toLowerCase().startsWith('version')) {
      cleaned = cleaned.substring(7).trim();
    } else if (cleaned.toLowerCase().startsWith('v')) {
      cleaned = cleaned.substring(1).trim();
    }
    // Replace hyphens in QA suffix builds (e.g. 1.1.40-1 -> 1.1.40.1)
    cleaned = cleaned.replaceAll('-', '.');
    return cleaned.isNotEmpty ? 'Version $cleaned' : '';
  }

  /// Initializes the service by reading the app version dynamically from the platform.
  /// When you build an APK or AAB, Flutter automatically embeds the `version:`
  /// from `pubspec.yaml` into the platform binary, which is read here at startup.
  static Future<void> init() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _displayVersion = formatVersion(_packageInfo!.version);
    } catch (e) {
      debugPrint('AppVersionService: Unable to read platform package info: $e');
    }
  }

  /// Helper for unit tests to set a mock version
  @visibleForTesting
  static void setMockVersion(String version) {
    _displayVersion = formatVersion(version);
  }

  /// Helper for unit tests to reset the state back to defaults
  @visibleForTesting
  static void reset() {
    _packageInfo = null;
    _displayVersion = '';
  }
}
