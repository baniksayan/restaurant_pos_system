// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/connectivity_helper.dart';

class ApiService {
  ApiService._();
  
  static Future<dynamic> apiGet(String endpoint) async {
    final isConnected = await checkInternetAndGoForward();
    if (isConnected) {
      try {
        http.Response response = await http
            .get(Uri.parse(ApiConstants.baseUrl + endpoint), headers: {
          'Accept': 'application/json',
          "x-access-token": ApiConstants.accessToken,
        });
        final res = jsonDecode(response.body.toString());
        if (response.statusCode == 502 && kDebugMode) {
          // Handle bad gateway
          // Navigate to error screen if needed
        }
        if (res['error'] == 2 &&
            res['message'] == "Unauthorized access token") {
          // Handle unauthorized access
          // Navigate to login screen
        }
        if (kDebugMode) {
          debugPrint('$endpoint Api Res ----: ${response.body}');
        }
        return jsonDecode(response.body.toString());
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('---- Api endpoint $endpoint error: $e');
          debugPrint('---- Api endpoint $endpoint stackTrace: $stackTrace');
        }
      }
    }
    return null;
  }
  
  static Future<dynamic> apiRequestHttpRawBody(
      String endpoint, Map<String, dynamic> body,
      {String method = 'POST'}) async {
    final isConnected = await checkInternetAndGoForward();
    if (isConnected) {
      try {
        var headers = {
          'Content-Type': 'application/json',
          'x-access-token': '${ApiConstants.accessToken}',
        };
        var request =
            http.Request(method, Uri.parse(ApiConstants.baseUrl + endpoint));
        request.body = json.encode(body);
        request.headers.addAll(headers);
        http.StreamedResponse response = await request.send();
        var responseData = await response.stream.toBytes();
        String responseString = String.fromCharCodes(responseData);
        final jsonData = jsonDecode(responseString);
        
        if (response.statusCode == 502 && kDebugMode) {
          // Handle bad gateway
        }
        if (jsonData['message'] == 'Unauthorized' || jsonData['error'] == 2) {
          debugPrint('---- Status code: ${response.statusCode}');
          // Handle unauthorized
        }
        debugPrint('$endpoint Api Res : $jsonData');
        return jsonData;
      } catch (e) {
        debugPrint("Api error in $endpoint: $e");
      }
    }
    return null;
  }
  
  static Future<bool> checkInternetAndGoForward() async {
    // You can use your existing connectivity_helper.dart
    // Return connectivity status
    return true; // Implement based on your connectivity helper
  }
}
