import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restaurant_pos_system/data/local/hive_service.dart';
import 'widgets/permission_dialog.dart';

class AppPermissionService {
  AppPermissionService._();

  static bool _isChecking = false;

  /// Check and register initial permissions at first login or first app launch.
  /// Evaluates permissions genuinely required by the application without
  /// triggering unnecessary runtime popups.
  static Future<void> checkInitialPermissions(BuildContext context) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final alreadyChecked = HiveService.hasCheckedInitialPermissions();
      if (alreadyChecked) {
        if (kDebugMode) {
          debugPrint(
            '[AppPermissionService] Initial permissions already checked.',
          );
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '[AppPermissionService] Performing first-use permissions evaluation...',
        );
      }

      // 1. Internet: Install-time normal permission on Android; no runtime prompt needed.
      // 2. Network Status: Normal permission (ACCESS_NETWORK_STATE); no runtime prompt needed.
      // 3. Storage: Sandboxed app storage & Scoped Storage used by PDF/reports; no runtime prompt needed.
      // 4. Bluetooth: The current app uses the OS Print Spooler (package:printing) without direct
      //    hardware BLE connectivity; no runtime prompt needed.

      // Persist that the initial onboarding permission evaluation has been completed.
      await HiveService.setInitialPermissionsChecked(true);

      if (kDebugMode) {
        debugPrint(
          '[AppPermissionService] Initial permissions registered successfully.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppPermissionService] Error during initial check: $e');
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Ensures storage permission for file saving/exporting where actually required.
  ///
  /// On modern Android (API 29+ / Android 10+) and iOS, app-specific external
  /// storage (`getExternalFilesDir`) and app documents directories are sandboxed
  /// and do NOT require runtime storage permissions. On legacy Android (<= API 28),
  /// runtime storage permission is requested gracefully.
  static Future<bool> ensureStoragePermission({BuildContext? context}) async {
    // Non-Android platforms (iOS, desktop, web) use app sandboxes: no permission needed.
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // In modern Android (Scoped Storage), checking Permission.storage returns denied
      // because broad external storage access is deprecated. App-specific storage
      // (used by getExternalStorageDirectory) does NOT require any permission.
      // We only request Permission.storage if the system explicitly requires it.
      final status = await Permission.storage.status;

      if (status.isGranted || status.isLimited) {
        return true;
      }

      // If status is permanently denied or restricted on modern Android,
      // app-specific storage still succeeds. We proceed safely.
      if (status.isPermanentlyDenied || status.isRestricted) {
        return true;
      }

      // On devices where storage permission can still be requested (legacy Android):
      final result = await Permission.storage.request();
      if (result.isGranted || result.isLimited) {
        return true;
      }

      // If denied and context is available, allow graceful continuation
      if (context != null && context.mounted && result.isPermanentlyDenied) {
        await showSettingsRedirectDialog(
          context,
          title: 'Storage Permission Required',
          message:
              'Storage access is needed to export reports to your device. Please enable it in Settings.',
          icon: Icons.folder_outlined,
        );
      }

      // If still denied on legacy Android, return false; on Android 10+ app-specific storage still works.
      return result.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppPermissionService] Storage permission check error: $e');
      }
      // Fail open for app-specific file writing so reports are not blocked
      return true;
    }
  }

  /// Ensures Bluetooth and nearby device permissions if direct hardware
  /// thermal printing is activated.
  static Future<bool> ensureBluetoothPermission({BuildContext? context}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    try {
      if (Platform.isAndroid) {
        // Android 12+ (API 31+) uses BLUETOOTH_SCAN and BLUETOOTH_CONNECT
        final scanStatus = await Permission.bluetoothScan.status;
        final connectStatus = await Permission.bluetoothConnect.status;

        if (scanStatus.isGranted && connectStatus.isGranted) {
          return true;
        }

        final statuses =
            await [
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
            ].request();

        final allGranted = statuses.values.every(
          (status) => status.isGranted || status.isLimited,
        );

        if (!allGranted && context != null && context.mounted) {
          final isPermanent = statuses.values.any(
            (status) => status.isPermanentlyDenied,
          );
          if (isPermanent) {
            await showSettingsRedirectDialog(
              context,
              title: 'Bluetooth Permission Required',
              message:
                  'Bluetooth permissions are required to discover and connect to nearby thermal printers. Please enable them in Settings.',
              icon: Icons.bluetooth,
            );
          }
        }
        return allGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.status;
        if (status.isGranted) {
          return true;
        }

        final result = await Permission.bluetooth.request();
        if (result.isPermanentlyDenied && context != null && context.mounted) {
          await showSettingsRedirectDialog(
            context,
            title: 'Bluetooth Permission Required',
            message:
                'Bluetooth access is required to connect to thermal printers. Please enable it in Settings.',
            icon: Icons.bluetooth,
          );
        }
        return result.isGranted;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AppPermissionService] Bluetooth permission check error: $e',
        );
      }
      return false;
    }
  }

  /// Shows a clean, non-intrusive dialog explaining that a permission was permanently
  /// denied and offering an immediate option to open App Settings.
  static Future<void> showSettingsRedirectDialog(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.settings_outlined,
  }) async {
    if (!context.mounted) return;

    await PermissionDialog.show(
      context,
      title: title,
      message: message,
      primaryButtonText: 'Open Settings',
      secondaryButtonText: 'Not Now',
      icon: icon,
      onPrimaryPressed: () async {
        await openAppSettings();
      },
    );
  }
}
