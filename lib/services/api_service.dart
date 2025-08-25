// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:restaurant_pos_system/data/models/order_channel.dart';
// import '../core/constants/api_constants.dart';

// class ApiService {
//   ApiService._();

//   /// Generic GET request method
//   static Future<Map<String, dynamic>?> apiGet(String endpoint) async {
//     final isConnected = await checkInternetAndGoForward();
//     if (!isConnected) return null;

//     try {
//       final response = await http.get(
//         Uri.parse(ApiConstants.baseUrl + endpoint),
//         headers: {
//           'Accept': 'application/json',
//           'x-access-token': ApiConstants.accessToken,
//         },
//       );

//       final responseBody = jsonDecode(response.body.toString());

//       // Handle bad gateway
//       if (response.statusCode == 502 && kDebugMode) {
//         debugPrint('Bad Gateway Error for endpoint: $endpoint');
//       }

//       // Handle unauthorized access
//       if (responseBody['error'] == 2 &&
//           responseBody['message'] == "Unauthorized access token") {
//         debugPrint('Unauthorized access for endpoint: $endpoint');
//         // Navigate to login screen if needed
//       }

//       if (kDebugMode) {
//         debugPrint('$endpoint API Response: ${response.body}');
//       }

//       return responseBody;
//     } catch (e, stackTrace) {
//       if (kDebugMode) {
//         debugPrint('API GET Error for $endpoint: $e');
//         debugPrint('StackTrace: $stackTrace');
//       }
//       return null;
//     }
//   }

//   /// Generic POST/PUT/DELETE request method with raw body
//   static Future<Map<String, dynamic>?> apiRequestHttpRawBody(
//     String endpoint,
//     Map<String, dynamic> body, {
//     String method = 'POST',
//   }) async {
//     final isConnected = await checkInternetAndGoForward();
//     if (!isConnected) return null;

//     try {
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': '${ApiConstants.accessToken}',
//       };

//       final request = http.Request(
//         method,
//         Uri.parse(ApiConstants.baseUrl + endpoint),
//       );

//       request.body = json.encode(body);
//       request.headers.addAll(headers);

//       final streamedResponse = await request.send();
//       final responseData = await streamedResponse.stream.toBytes();
//       final responseString = String.fromCharCodes(responseData);
//       final jsonData = jsonDecode(responseString);

//       // Handle bad gateway
//       if (streamedResponse.statusCode == 502 && kDebugMode) {
//         debugPrint('Bad Gateway Error for endpoint: $endpoint');
//       }

//       // Handle unauthorized access
//       if (jsonData['message'] == 'Unauthorized' || jsonData['error'] == 2) {
//         if (kDebugMode) {
//           debugPrint(
//             'Unauthorized access - Status code: ${streamedResponse.statusCode}',
//           );
//         }
//         // Handle unauthorized navigation if needed
//       }

//       if (kDebugMode) {
//         debugPrint('$endpoint API Response: $jsonData');
//       }

//       return jsonData;
//     } catch (e, stackTrace) {
//       if (kDebugMode) {
//         debugPrint('API Error in $endpoint: $e');
//         debugPrint('StackTrace: $stackTrace');
//       }
//       return null;
//     }
//   }

//   /// Get tables by outlet ID - Updated and improved version
//   static Future<List<OrderChannel>?> getTablesByOutlet({
//     required String token,
//     required int outletId,
//     String orderChannelType = '',
//   }) async {
//     final isConnected = await checkInternetAndGoForward();
//     if (!isConnected) return null;

//     try {
//       final url = ApiConstants.baseUrl + ApiConstants.getTablesByOutlet;

//       final Map<String, dynamic> requestBody = {
//         "orderChanelType": orderChannelType, // Note: keeping the API's typo
//         "outletId": outletId,
//       };

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Accept': 'application/json',
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(requestBody),
//       );

//       if (kDebugMode) {
//         debugPrint('getTablesByOutlet request URL: $url');
//         debugPrint('getTablesByOutlet request body: $requestBody');
//         debugPrint('getTablesByOutlet response status: ${response.statusCode}');
//         debugPrint('getTablesByOutlet response: ${response.body}');
//       }

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = jsonDecode(response.body);

//         if (responseData['isSuccess'] == true && responseData['data'] != null) {
//           final List<dynamic> data = responseData['data'];
//           return data.map((e) => OrderChannel.fromJson(e)).toList();
//         }
//       } else {
//         if (kDebugMode) {
//           debugPrint('Failed to fetch tables: ${response.statusCode}');
//           debugPrint('Error response: ${response.body}');
//         }
//       }

//       return null;
//     } catch (e, stackTrace) {
//       if (kDebugMode) {
//         debugPrint('getTablesByOutlet error: $e');
//         debugPrint('StackTrace: $stackTrace');
//       }
//       return null;
//     }
//   }

//   /// Alternative method for getting tables (raw response)
//   static Future<Map<String, dynamic>?> getTablesByOutletRaw({
//     required int outletId,
//     String orderChannelType = "",
//   }) async {
//     final isConnected = await checkInternetAndGoForward();
//     if (!isConnected) return null;

//     try {
//       final Map<String, dynamic> requestBody = {
//         "orderChanelType": orderChannelType, // Note: keeping the API's typo
//         "outletId": outletId,
//       };

//       final response = await http.post(
//         Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getTablesByOutlet}'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${ApiConstants.accessToken}',
//         },
//         body: json.encode(requestBody),
//       );

//       if (kDebugMode) {
//         debugPrint('getTablesByOutletRaw response status: ${response.statusCode}');
//         debugPrint('getTablesByOutletRaw response: ${response.body}');
//       }

//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         if (kDebugMode) {
//           debugPrint('Failed to fetch tables: ${response.statusCode}');
//           debugPrint('Response: ${response.body}');
//         }
//         return null;
//       }
//     } catch (e, stackTrace) {
//       if (kDebugMode) {
//         debugPrint('Error fetching tables: $e');
//         debugPrint('StackTrace: $stackTrace');
//       }
//       return null;
//     }
//   }

//   /// Get all product categories for an outlet
//   static Future<Map<String, dynamic>?> getAllProductCategories({
//     required int outletId,
//   }) async {
//     final isConnected = await checkInternetAndGoForward();
//     if (!isConnected) return null;

//     try {
//       const endpoint = 'product/GetAllProductCategory';
//       final body = {"outletId": outletId};

//       if (kDebugMode) {
//         debugPrint('Calling categories API: $endpoint');
//         debugPrint('Request Body: $body');
//       }

//       final response = await apiRequestHttpRawBody(
//         endpoint,
//         body,
//         method: 'POST',
//       );

//       if (response != null && kDebugMode) {
//         debugPrint('Categories API Response: $response');
//       }

//       return response;
//     } catch (e, stackTrace) {
//       if (kDebugMode) {
//         debugPrint('Error in getAllProductCategories: $e');
//         debugPrint('StackTrace: $stackTrace');
//       }
//       return null;
//     }
//   }

//   /// Check internet connectivity
//   static Future<bool> checkInternetAndGoForward() async {
//     // TODO: Implement using your existing connectivity_helper.dart
//     // This should check actual internet connectivity
//     return true;
//   }
// }



import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:restaurant_pos_system/data/models/order_channel.dart';
import '../core/constants/api_constants.dart';


class ApiService {
  ApiService._();

  /// Generic GET request method

  static Future<Map<String, dynamic>?> apiGet(String endpoint) async {
    final isConnected = await checkInternetAndGoForward();

    if (!isConnected) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + endpoint),

        headers: {
          'Accept': 'application/json',

          'x-access-token': ApiConstants.accessToken,
        },
      );

      final responseBody = jsonDecode(response.body.toString());

      // Handle bad gateway

      if (response.statusCode == 502 && kDebugMode) {
        debugPrint('Bad Gateway Error for endpoint: $endpoint');
      }

      // Handle unauthorized access

      if (responseBody['error'] == 2 &&
          responseBody['message'] == "Unauthorized access token") {
        debugPrint('Unauthorized access for endpoint: $endpoint');

        // Navigate to login screen if needed
      }

      if (kDebugMode) {
        debugPrint('$endpoint API Response: ${response.body}');
      }

      return responseBody;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('API GET Error for $endpoint: $e');

        debugPrint('StackTrace: $stackTrace');
      }

      return null;
    }
  }

  /// Generic POST/PUT/DELETE request method with raw body

  static Future<Map<String, dynamic>?> apiRequestHttpRawBody(
    String endpoint,

    Map<String, dynamic> body, {

    String method = 'POST',
  }) async {
    final isConnected = await checkInternetAndGoForward();

    if (!isConnected) return null;

    try {
      final headers = {
        'Content-Type': 'application/json',

        'Authorization': '${ApiConstants.accessToken}',
      };

      final request = http.Request(
        method,

        Uri.parse(ApiConstants.baseUrl + endpoint),
      );

      request.body = json.encode(body);

      request.headers.addAll(headers);

      final streamedResponse = await request.send();

      final responseData = await streamedResponse.stream.toBytes();

      final responseString = String.fromCharCodes(responseData);

      final jsonData = jsonDecode(responseString);

      // Handle bad gateway

      if (streamedResponse.statusCode == 502 && kDebugMode) {
        debugPrint('Bad Gateway Error for endpoint: $endpoint');
      }

      // Handle unauthorized access

      if (jsonData['message'] == 'Unauthorized' || jsonData['error'] == 2) {
        if (kDebugMode) {
          debugPrint(
            'Unauthorized access - Status code: ${streamedResponse.statusCode}',
          );
        }

        // Handle unauthorized navigation if needed
      }

      if (kDebugMode) {
        debugPrint('$endpoint API Response: $jsonData');
      }

      return jsonData;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('API Error in $endpoint: $e');

        debugPrint('StackTrace: $stackTrace');
      }

      return null;
    }
  }

  /// Get tables by outlet ID - Updated and improved version

  static Future<List<OrderChannel>?> getTablesByOutlet({
    required String token,

    required int outletId,

    String orderChannelType = '',
  }) async {
    final isConnected = await checkInternetAndGoForward();

    if (!isConnected) return null;

    try {
      final url = ApiConstants.baseUrl + ApiConstants.getTablesByOutlet;

      final Map<String, dynamic> requestBody = {
        "orderChanelType": orderChannelType, // Note: keeping the API's typo

        "outletId": outletId,
      };

      final response = await http.post(
        Uri.parse(url),

        headers: {
          'Accept': 'application/json',

          'Content-Type': 'application/json',

          'Authorization': 'Bearer $token',
        },

        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        debugPrint('getTablesByOutlet request URL: $url');

        debugPrint('getTablesByOutlet request body: $requestBody');

        debugPrint('getTablesByOutlet response status: ${response.statusCode}');

        debugPrint('getTablesByOutlet response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['isSuccess'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];

          return data.map((e) => OrderChannel.fromJson(e)).toList();
        }
      } else {
        if (kDebugMode) {
          debugPrint('Failed to fetch tables: ${response.statusCode}');

          debugPrint('Error response: ${response.body}');
        }
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('getTablesByOutlet error: $e');

        debugPrint('StackTrace: $stackTrace');
      }

      return null;
    }
  }

  /// Alternative method for getting tables (raw response)

  static Future<Map<String, dynamic>?> getTablesByOutletRaw({
    required int outletId,

    String orderChannelType = "",
  }) async {
    final isConnected = await checkInternetAndGoForward();

    if (!isConnected) return null;

    try {
      final Map<String, dynamic> requestBody = {
        "orderChanelType": orderChannelType, // Note: keeping the API's typo

        "outletId": outletId,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getTablesByOutlet}'),

        headers: {
          'Content-Type': 'application/json',

          'Authorization': 'Bearer ${ApiConstants.accessToken}',
        },

        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        debugPrint(
          'getTablesByOutletRaw response status: ${response.statusCode}',
        );

        debugPrint('getTablesByOutletRaw response: ${response.body}');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (kDebugMode) {
          debugPrint('Failed to fetch tables: ${response.statusCode}');

          debugPrint('Response: ${response.body}');
        }

        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error fetching tables: $e');

        debugPrint('StackTrace: $stackTrace');
      }

      return null;
    }
  }

  /// New method for getting tables with proper error handling
  static Future<Map<String, dynamic>?> getTablesByOutletNew({
    required int outletId,
    String orderChannelType = "",
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      final Map<String, dynamic> requestBody = {
        "orderChanelType": orderChannelType, // Note: keeping the API's typo
        "outletId": outletId,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getTablesByOutlet}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.accessToken}',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        debugPrint(
          'getTablesByOutletNew request URL: ${ApiConstants.baseUrl}${ApiConstants.getTablesByOutlet}',
        );
        debugPrint('getTablesByOutletNew request body: $requestBody');
        debugPrint(
          'getTablesByOutletNew response status: ${response.statusCode}',
        );
        debugPrint('getTablesByOutletNew response: ${response.body}');
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        if (kDebugMode) {
          debugPrint('Failed to fetch tables: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error fetching tables: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      return null;
    }
  }

  /// Get all product categories for an outlet

  static Future<Map<String, dynamic>?> getAllProductCategories({
    required int outletId,
  }) async {
    final isConnected = await checkInternetAndGoForward();

    if (!isConnected) return null;

    try {
      const endpoint = 'product/GetAllProductCategory';

      final body = {"outletId": outletId};

      if (kDebugMode) {
        debugPrint('Calling categories API: $endpoint');

        debugPrint('Request Body: $body');
      }

      final response = await apiRequestHttpRawBody(
        endpoint,

        body,

        method: 'POST',
      );

      if (response != null && kDebugMode) {
        debugPrint('Categories API Response: $response');
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in getAllProductCategories: $e');

        debugPrint('StackTrace: $stackTrace');
      }

      return null;
    }
  }

  /// Check internet connectivity

  static Future<bool> checkInternetAndGoForward() async {
    // TODO: Implement using your existing connectivity_helper.dart

    // This should check actual internet connectivity

    return true;
  }
}
