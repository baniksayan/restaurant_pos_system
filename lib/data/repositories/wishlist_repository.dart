// lib/data/repositories/wishlist_repository.dart
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/wishlist_api_res_model.dart'; // You'll need to create this model

class WishlistRepository {
  WishlistRepository._();
  
  static Future<WishListApiResModel?> getCustomerWishItems({
    int wishListCategoryId = 237,
    int customerId = 300,
    int companyId = 112,
  }) async {
    try {
      const endpoint = 'frontend/GetCustomerWishItems';
      final body = {
        "wishListCategoryId": wishListCategoryId,
        "customerId": customerId,
        "companyId": companyId,
      };
 
      if (kDebugMode) {
        debugPrint('Calling Wishlist API: $endpoint');
        debugPrint('Request Body: $body');
      }
 
      final response = await ApiService.apiRequestHttpRawBody(
        endpoint,
        body,
        method: ApiMethods.post,
      );
 
      if (response != null) {
        if (kDebugMode) {
          debugPrint('Wishlist API Response: $response');
        }
 
        return WishListApiResModel.fromJson(response);
      } else {
        if (kDebugMode) {
          debugPrint('Wishlist API returned null response');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error in getCustomerWishItems: $e');
        debugPrint('StackTrace: $stackTrace');
      }
      return null;
    }
  }

  // Add more wishlist-related API calls here
  static Future<bool> addToWishlist({
    required int customerId,
    required int itemId,
    required int companyId,
  }) async {
    // Implementation for adding items to wishlist
    return false;
  }

  static Future<bool> removeFromWishlist({
    required int customerId,
    required int itemId,
    required int companyId,
  }) async {
    // Implementation for removing items from wishlist
    return false;
  }
}
