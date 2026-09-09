import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:restaurant_pos_system/core/utils/snackbar_helper.dart';

class UrlHelper {
  UrlHelper._();

  /// Opens a URL externally in the platform browser.
  static Future<bool> openUrl(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppSnackBar.showError(context, 'Could not open link: $urlString');
      }
      return launched;
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Error opening link: $e');
      }
      return false;
    }
  }
}
