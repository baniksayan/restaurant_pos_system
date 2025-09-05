import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:restaurant_pos_system/data/models/order_channel.dart';
import 'package:restaurant_pos_system/data/models/payment_mode_api_res_model.dart';
import 'package:restaurant_pos_system/data/models/create_order_head_request_model.dart';
import 'package:restaurant_pos_system/data/models/create_order_head_api_res_model.dart';
import 'package:restaurant_pos_system/data/models/create_kot_with_order_details_api_res_model.dart';
import 'package:restaurant_pos_system/data/models/order_channel_list_api_response_model.dart';
import 'package:restaurant_pos_system/data/models/order_detail_api_response_model.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  ApiService._();

  /// Generic GET request method
  static Future<dynamic>? apiGet(String endpoint) async {
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
  static Future<dynamic>? apiRequestHttpRawBody(
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

      dynamic jsonData;
      try {
        // Defensive parsing: server may return empty body or non-JSON (e.g., 204/empty)
        if (responseString.trim().isEmpty) {
          if (kDebugMode) {
            debugPrint(
              'Empty response body for endpoint: $endpoint (status: ${streamedResponse.statusCode})',
            );
          }

          if (streamedResponse.statusCode >= 200 &&
              streamedResponse.statusCode < 300) {
            // Success with empty body -> minimal success map
            jsonData = {
              'isSuccess': true,
              'message': '',
              'data': {},
              'statusCode': streamedResponse.statusCode,
            };
          } else {
            // Error with empty body -> return structured error map so callers can handle it
            jsonData = {
              'isSuccess': false,
              'message': 'Empty response body',
              'data': {},
              'statusCode': streamedResponse.statusCode,
            };
          }
        } else {
          // Non-empty body. Try parsing JSON; if it fails, wrap raw text in an error map for non-2xx,
          // or attempt to parse for 2xx.
          try {
            jsonData = jsonDecode(responseString);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                'Response not JSON for $endpoint (status ${streamedResponse.statusCode}): $responseString',
              );
            }

            if (streamedResponse.statusCode >= 200 &&
                streamedResponse.statusCode < 300) {
              // 2xx but not JSON -> treat as success with raw message
              jsonData = {
                'isSuccess': true,
                'message': responseString,
                'data': {},
                'statusCode': streamedResponse.statusCode,
              };
            } else {
              // Non-2xx and non-JSON -> error map with raw body as message
              jsonData = {
                'isSuccess': false,
                'message': responseString,
                'data': {},
                'statusCode': streamedResponse.statusCode,
              };
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to parse JSON response for $endpoint: $e');
          debugPrint('Raw response: "$responseString"');
        }
        return null;
      }

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

  /// Save Order Head - Create new order (correct API for occupying table)
  static Future<CreateOrderHeadApiResModel?> saveOrderHead({
    required String token,
    required String orderChannelId, // Table ID
    required String waiterId,
    required String customerName,
    required int outletId,
    required String userId,
    String custPhoneNo = "",
    int totalAdult = 1,
    int totalChild = 0,
    String custEmailId = "",
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      final requestModel = CreateOrderHeadRequestModel(
        orderChannelId: orderChannelId,
        waiterId: waiterId,
        customerName: customerName,
        outletId: outletId,
        userId: userId,
        custPhoneNo: custPhoneNo,
        totalAdult: totalAdult,
        totalChild: totalChild,
        custEmailId: custEmailId,
      );

      if (kDebugMode) {
        print('[API Call] saveOrderHead - Table: $orderChannelId');
        print('[API Call] Request Body: ${requestModel.toJson()}');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createOrderHead}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestModel.toJson()),
      );

      if (kDebugMode) {
        print(
          '[API Call] saveOrderHead Response Status: ${response.statusCode}',
        );
        print('[API Call] saveOrderHead Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return CreateOrderHeadApiResModel.fromJson(responseData);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[API Error] saveOrderHead: $e');
      }
      return null;
    }
  }

  /// Get tables using OrderChannelListByType API - Enhanced with improved models
  static Future<OrderChannelListApiResponseModel?> getOrderChannelListByType({
    required String token,
    required int outletId,
    String orderChannelType = "Table",
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      final Map<String, dynamic> requestBody = {
        "orderChanelType": orderChannelType, // Keep the API typo
        "outletId": outletId,
      };

      if (kDebugMode) {
        print('[Table Manager] API Call - OrderChannelListByType');
        print(
          '[Table Manager] Request URL: ${ApiConstants.baseUrl}Setting/OrderChannelListByType',
        );
        print('[Table Manager] Request Body: $requestBody');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}Setting/OrderChannelListByType'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('[Table Manager] Response Status: ${response.statusCode}');
        print('[Table Manager] Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return OrderChannelListApiResponseModel.fromJson(responseData);
      } else {
        if (kDebugMode) {
          print('[Table Manager] API Failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Table Manager] API Error: $e');
      }
      return null;
    }
  }

  /// Get Order Details by ID - Enhanced with proper model
  static Future<OrderDetailApiResponseModel?> getOrderDetailById({
    required String token,
    required String orderId,
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      final Map<String, dynamic> requestBody = {"orderId": orderId};

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}Order/getOrderDetailById'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('[API Call] getOrderDetailById - Order: $orderId');
        print('[Cart Loaded] Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (kDebugMode) print('[Cart Loaded] Order $orderId data retrieved');
        return OrderDetailApiResponseModel.fromJson(responseData);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[API Error] getOrderDetailById: $e');
      }
      return null;
    }
  }

  /// Update Order Head Status - Enhanced with proper parameters
  static Future<Map<String, dynamic>?> updateOrderHeadStatus({
    required String token,
    required String orderHeadId,
    required int statusId,
    required String userId,
    int companyId = 18,
    String? orderId, // Legacy support
    String? status, // Legacy support
    String? tableId, // Legacy support
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      Map<String, dynamic> requestBody;

      // Support both old and new parameter formats
      if (orderId != null && status != null) {
        // Legacy format
        requestBody = {
          "orderId": orderId,
          "status": status,
          if (tableId != null) "tableId": tableId,
        };
      } else {
        // New format
        requestBody = {
          "companyId": companyId,
          "orderHeadId": orderHeadId,
          "statusId": statusId,
          "userId": userId,
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}Order/UpdateOrderHeadStatus'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        if (orderId != null) {
          print(
            '[API Call] UpdateOrderHeadStatus - Table: $tableId -> $status',
          );
          print(
            '[Order ${status == 'occupied' ? 'Created' : 'Removed'}] ID: $orderId',
          );
        } else {
          print(
            '[API Call] UpdateOrderHeadStatus - Order: $orderHeadId -> Status: $statusId',
          );
          print(
            '[Order ${statusId == 6
                ? 'Created'
                : statusId == 7
                ? 'Removed'
                : 'Updated'}] ID: $orderHeadId',
          );
        }
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[API Error] UpdateOrderHeadStatus: $e');
      }
      return null;
    }
  }

  /// Get tables by outlet ID - Original version maintained
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
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('getTablesByOutlet error: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      return null;
    }
    return null;
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

  /// Enhanced method with better retry logic and error handling
  static Future<Map<String, dynamic>?> getTablesByOutletEnhanced({
    required int outletId,
    String orderChannelType = "",
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final isConnected = await checkInternetAndGoForward();
        if (!isConnected) {
          if (kDebugMode) {
            debugPrint('No internet connection available');
          }
          return null;
        }

        final Map<String, dynamic> requestBody = {
          "orderChanelType": orderChannelType, // Note: keeping the API's typo
          "outletId": outletId,
        };

        final response = await http
            .post(
              Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.getTablesByOutlet}',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${ApiConstants.accessToken}',
              },
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 30)); // Add timeout

        if (kDebugMode) {
          debugPrint(
            'getTablesByOutletEnhanced request URL: ${ApiConstants.baseUrl}${ApiConstants.getTablesByOutlet}',
          );
          debugPrint('getTablesByOutletEnhanced request body: $requestBody');
          debugPrint(
            'getTablesByOutletEnhanced response status: ${response.statusCode}',
          );
          debugPrint('getTablesByOutletEnhanced response: ${response.body}');
        }

        if (response.statusCode == 200) {
          try {
            final responseData = json.decode(response.body);
            return responseData;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Failed to parse JSON response: $e');
            }
            throw Exception('Invalid JSON response');
          }
        } else if (response.statusCode == 500 && attempts < maxRetries - 1) {
          // Server error - retry with exponential backoff
          if (kDebugMode) {
            debugPrint(
              'Server error (500) on attempt ${attempts + 1}. Retrying...',
            );
          }
          attempts++;
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
          continue;
        } else {
          if (kDebugMode) {
            debugPrint('API request failed: ${response.statusCode}');
            debugPrint('Response: ${response.body}');
          }
          throw Exception(
            'API request failed with status: ${response.statusCode}',
          );
        }
      } catch (e) {
        attempts++;
        if (kDebugMode) {
          debugPrint(
            'getTablesByOutletEnhanced error on attempt $attempts: $e',
          );
        }

        if (attempts >= maxRetries) {
          if (kDebugMode) {
            debugPrint('Max retries ($maxRetries) exceeded for tables API');
          }
          throw Exception(
            'Failed to fetch tables after $maxRetries attempts: $e',
          );
        }

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      }
    }
    return null;
  }

  /// Generic retry wrapper for any API call
  static Future<T?> executeWithRetry<T>(
    Future<T> Function() apiCall, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    String operationName = 'API call',
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final result = await apiCall();
        return result;
      } catch (e) {
        attempts++;
        if (kDebugMode) {
          debugPrint('$operationName failed on attempt $attempts: $e');
        }

        if (attempts >= maxRetries) {
          if (kDebugMode) {
            debugPrint('$operationName failed after $maxRetries attempts');
          }
          rethrow;
        }

        // Exponential backoff
        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * attempts,
        );
        if (kDebugMode) {
          debugPrint('Retrying $operationName in ${delay.inMilliseconds}ms...');
        }
        await Future.delayed(delay);
      }
    }
    return null;
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

  /// Get all taxes for a company
  static Future<Map<String, dynamic>?> getAllTaxes({
    required int companyId,
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      const endpoint = 'Order/getTaxDt';
      final body = {"companyId": companyId};

      if (kDebugMode) {
        debugPrint('Calling getAllTaxes API: $endpoint');
        debugPrint('Request Body: $body');
      }

      final response = await apiRequestHttpRawBody(
        endpoint,
        body,
        method: 'POST',
      );

      if (response != null && kDebugMode) {
        debugPrint('getAllTaxes API Response: $response');
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in getAllTaxes: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      return null;
    }
  }

  /// Get all payment modes
  static Future<PaymentModeApiResModel?> getAllPaymentModes() async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      const endpoint = 'Order/GetPaymentMode';
      final body = <String, dynamic>{}; // Empty body as per API requirement

      if (kDebugMode) {
        debugPrint('Calling getAllPaymentModes API: $endpoint');
        debugPrint('Request Body: $body');
      }

      final response = await apiRequestHttpRawBody(
        endpoint,
        body,
        method: 'POST',
      );

      if (response != null) {
        if (kDebugMode) {
          debugPrint('getAllPaymentModes API Response: $response');
        }
        return PaymentModeApiResModel.fromJson(response);
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in getAllPaymentModes: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      return null;
    }
  }

  /// Create order head
  static Future<CreateOrderHeadApiResModel?> createOrderHead({
    required String orderChannelId,
    required String waiterId,
    required String customerName,
    required int outletId,
    required String userId,
    String? custPhoneNo,
    int? totalAdult,
    int? totalChild,
    String? custEmailId,
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    try {
      final requestModel = CreateOrderHeadRequestModel(
        orderChannelId: orderChannelId,
        waiterId: waiterId,
        customerName: customerName,
        outletId: outletId,
        userId: userId,
        custPhoneNo: custPhoneNo ?? "",
        totalAdult: totalAdult ?? 0,
        totalChild: totalChild ?? 0,
        custEmailId: custEmailId ?? "",
      );

      if (kDebugMode) {
        debugPrint(
          'Calling createOrderHead API: ${ApiConstants.createOrderHead}',
        );
        debugPrint('Request Body: ${requestModel.toJson()}');
      }

      final response = await apiRequestHttpRawBody(
        ApiConstants.createOrderHead,
        requestModel.toJson(),
        method: 'POST',
      );

      if (response != null) {
        if (kDebugMode) {
          debugPrint('createOrderHead API Response: $response');
        }
        return CreateOrderHeadApiResModel.fromJson(response);
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in createOrderHead: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      return null;
    }
  }

  /// Create KOT with order details - Enhanced with proper endpoint support
  static Future<CreateKotWithOrderDetailsApiResModel?>
  createKotWithOrderDetails({
    required String userId,
    required int outletId,
    required String orderId,
    String kotNote = "",
    required List<Map<String, dynamic>> orderDetails,
    String? token, // Added optional token parameter
  }) async {
    final isConnected = await checkInternetAndGoForward();
    if (!isConnected) return null;

    final body = {
      "userId": userId,
      "outletId": outletId,
      "orderId": orderId,
      "kotNote": kotNote,
      "orderDetails": orderDetails,
    };

    if (kDebugMode) {
      debugPrint(
        'Calling createKotWithOrderDetails API: ${ApiConstants.createKotWithOrderDetails}',
      );
      debugPrint('Request Body: $body');
    }

    try {
      dynamic response;

      // Use token-based request if token is provided, otherwise use the original method
      if (token != null) {
        final httpResponse = await http.post(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.createKotWithOrderDetails}',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        );

        if (httpResponse.statusCode == 200) {
          response = json.decode(httpResponse.body);
        }
      } else {
        response = await apiRequestHttpRawBody(
          ApiConstants.createKotWithOrderDetails,
          body,
          method: 'POST',
        );
      }

      if (response != null) {
        if (kDebugMode) {
          debugPrint('createKotWithOrderDetails API Response: $response');
        }

        try {
          // Ensure we pass a Map to the generated model
          final typed = Map<String, dynamic>.from(response);
          return CreateKotWithOrderDetailsApiResModel.fromJson(typed);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to cast response to Map: $e');
          }

          // Build a safe fallback map using available fields
          final fallback = {
            'isSuccess': response['isSuccess'] ?? false,
            'message': response['message']?.toString() ?? response.toString(),
            'data': response['data'] ?? {},
            'statusCode': response['statusCode'] ?? 0,
          };
          return CreateKotWithOrderDetailsApiResModel.fromJson(fallback);
        }
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in createKotWithOrderDetails: $e');
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
