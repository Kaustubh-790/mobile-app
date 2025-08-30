import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/cart_item.dart';

class CartService {
  static final ApiClient _apiClient = ApiClient();

  /// Get user's cart
  static Future<List<CartItem>> getCart({String? userId}) async {
    try {
      print('CartService: Fetching cart...');

      final response = await _apiClient.instance.get('/cart');

      if (response.statusCode == 200) {
        final Map<String, dynamic> cartData = response.data;
        print('CartService: Raw cart response: $cartData');

        // Handle different response structures
        List<dynamic> itemsData = [];

        if (cartData['items'] != null) {
          itemsData = cartData['items'] as List<dynamic>;
        } else if (cartData is List) {
          itemsData = cartData as List<dynamic>;
        } else if (cartData['cartItems'] != null) {
          itemsData = cartData['cartItems'] as List<dynamic>;
        }

        final cartItems = itemsData.map((json) {
          try {
            return CartItem.fromJson(json);
          } catch (e) {
            print('CartService: Error parsing cart item: $e');
            print('CartService: Item data: $json');
            rethrow;
          }
        }).toList();

        print(
          'CartService: Successfully fetched ${cartItems.length} cart items',
        );
        return cartItems;
      } else {
        print(
          'CartService: Error fetching cart - Status: ${response.statusCode}',
        );
        throw Exception('Failed to load cart');
      }
    } catch (e) {
      print('CartService: Exception while fetching cart - $e');

      if (e is DioException) {
        print('CartService: DioException type: ${e.type}');
        print('CartService: DioException message: ${e.message}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Unable to connect to server. Please try again later.',
            );
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to load cart: $e');
    }
  }

  /// Add item to cart - Updated to send packageId to backend
  static Future<CartItem> addToCart(
    String serviceId,
    int quantity, {
    String? packageId, // Now required for backend to calculate correct price
    String? userId,
    double? price,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      print(
        'CartService: Adding item to cart - serviceId: $serviceId, packageId: $packageId, quantity: $quantity, price: $price',
      );

      // Prepare request data matching backend expectations
      final requestData = <String, dynamic>{
        'serviceId': serviceId,
        'quantity': quantity,
      };

      // Add packageId if provided - this is what backend uses to calculate price
      if (packageId != null && packageId.isNotEmpty) {
        requestData['packageId'] = packageId;
      }

      // Add customizations if provided
      if (customizations != null && customizations.isNotEmpty) {
        requestData['customizations'] = customizations;
      }

      print('CartService: Request data: $requestData');
      print('CartService: Using endpoint: /cart/add');

      final response = await _apiClient.instance.post(
        '/cart/add',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;
        print('CartService: Add to cart response: $responseData');

        // Backend returns the entire cart, extract the added item
        List<dynamic> items = [];
        if (responseData['items'] != null) {
          items = responseData['items'] as List<dynamic>;
        }

        if (items.isEmpty) {
          throw Exception('No items found in cart response');
        }

        // Find the item that was just added (last item or matching serviceId/packageId)
        Map<String, dynamic> cartItemData;
        if (packageId != null) {
          // Find item with matching serviceId and packageId
          final matchingItem = items.cast<Map<String, dynamic>>().firstWhere(
            (item) =>
                item['serviceId'] == serviceId &&
                (item['packageId']?.toString() == packageId ||
                    item['packageId']?['_id']?.toString() == packageId),
            orElse: () => items.last as Map<String, dynamic>,
          );
          cartItemData = matchingItem;
        } else {
          // If no packageId, get the last added item
          cartItemData = items.last as Map<String, dynamic>;
        }

        // Ensure required fields exist
        if (cartItemData['_id'] == null && cartItemData['id'] == null) {
          cartItemData['_id'] = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        }

        if (cartItemData['addedAt'] == null) {
          cartItemData['addedAt'] = DateTime.now().toIso8601String();
        }

        print('CartService: Final cart item data: $cartItemData');

        final CartItem cartItem = CartItem.fromJson(cartItemData);
        print(
          'CartService: Successfully created CartItem with price: ${cartItem.price}',
        );
        return cartItem;
      } else {
        print(
          'CartService: Error adding item to cart - Status: ${response.statusCode}',
        );
        throw Exception('Failed to add item to cart');
      }
    } catch (e) {
      print('CartService: Exception while adding item to cart - $e');

      if (e is DioException) {
        print('CartService: DioException type: ${e.type}');
        print('CartService: DioException message: ${e.message}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Unable to connect to server. Please try again later.',
            );
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to add item to cart: $e');
    }
  }

  /// Convenience method for adding items with package details
  static Future<CartItem> addItemWithPackage(
    String serviceId,
    int quantity, {
    required String packageId,
    String? userId,
    Map<String, dynamic>? customizations,
  }) async {
    return addToCart(
      serviceId,
      quantity,
      packageId: packageId,
      userId: userId,
      customizations: customizations,
    );
  }

  /// Update cart item quantity
  static Future<CartItem> updateCartItem(
    String itemId,
    int quantity, {
    String? userId,
    double? price,
  }) async {
    try {
      print(
        'CartService: Updating cart item - itemId: $itemId, quantity: $quantity',
      );

      final requestData = {
        'quantity': quantity,
        if (price != null) 'price': price,
      };

      final response = await _apiClient.instance.put(
        '/cart/update/$itemId',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        print('CartService: Update cart item response: $responseData');

        // Backend returns entire cart, find the updated item
        List<dynamic> items = [];
        if (responseData['items'] != null) {
          items = responseData['items'] as List<dynamic>;
        }

        // Find the updated item
        final updatedItemData = items.cast<Map<String, dynamic>>().firstWhere(
          (item) =>
              item['_id']?.toString() == itemId ||
              item['id']?.toString() == itemId,
          orElse: () => responseData,
        );

        final CartItem cartItem = CartItem.fromJson(updatedItemData);
        print('CartService: Successfully updated cart item');
        return cartItem;
      } else {
        print(
          'CartService: Error updating cart item - Status: ${response.statusCode}',
        );
        throw Exception('Failed to update cart item');
      }
    } catch (e) {
      print('CartService: Exception while updating cart item - $e');

      if (e is DioException) {
        print('CartService: DioException type: ${e.type}');
        print('CartService: DioException message: ${e.message}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Unable to connect to server. Please try again later.',
            );
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to update cart item: $e');
    }
  }

  /// Remove item from cart
  static Future<void> removeFromCart(String itemId, {String? userId}) async {
    try {
      print('CartService: Removing item from cart - itemId: $itemId');

      final response = await _apiClient.instance.delete('/cart/$itemId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('CartService: Successfully removed item from cart');
        return;
      } else {
        print(
          'CartService: Error removing item from cart - Status: ${response.statusCode}',
        );
        throw Exception('Failed to remove item from cart');
      }
    } catch (e) {
      print('CartService: Exception while removing item from cart - $e');

      if (e is DioException) {
        print('CartService: DioException type: ${e.type}');
        print('CartService: DioException message: ${e.message}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Unable to connect to server. Please try again later.',
            );
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to remove item from cart: $e');
    }
  }

  /// Clear entire cart
  static Future<void> clearCart({String? userId}) async {
    try {
      print('CartService: Clearing cart...');

      final response = await _apiClient.instance.delete('/cart/clear');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('CartService: Successfully cleared cart');
        return;
      } else {
        print(
          'CartService: Error clearing cart - Status: ${response.statusCode}',
        );
        throw Exception('Failed to clear cart');
      }
    } catch (e) {
      print('CartService: Exception while clearing cart - $e');

      if (e is DioException) {
        print('CartService: DioException type: ${e.type}');
        print('CartService: DioException message: ${e.message}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Unable to connect to server. Please try again later.',
            );
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to clear cart: $e');
    }
  }
}
