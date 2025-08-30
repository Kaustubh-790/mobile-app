import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/cart_item.dart';

class CartService {
  static final ApiClient _apiClient = ApiClient();

  /// Get user's cart
  static Future<List<CartItem>> getCart() async {
    try {
      print('CartService: Fetching cart...');

      final response = await _apiClient.instance.get('/cart');

      if (response.statusCode == 200) {
        final Map<String, dynamic> cartData = response.data;
        print('CartService: Raw cart response: $cartData');

        // Handle different response structures
        List<dynamic> itemsData = [];

        if (cartData['items'] != null) {
          // Standard cart response with items array
          itemsData = cartData['items'] as List<dynamic>;
        } else if (cartData is List) {
          // Direct list of cart items
          itemsData = cartData as List<dynamic>;
        } else if (cartData['cartItems'] != null) {
          // Alternative response structure
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

  /// Add item to cart
  static Future<CartItem> addToCart(String serviceId, int quantity) async {
    try {
      print(
        'CartService: Adding item to cart - serviceId: $serviceId, quantity: $quantity',
      );

      final response = await _apiClient.instance.post(
        '/cart/add',
        data: {'serviceId': serviceId, 'quantity': quantity},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;
        print('CartService: Add to cart response: $responseData');

        // Handle different response structures
        Map<String, dynamic> cartItemData;

        if (responseData['cartItem'] != null) {
          cartItemData = responseData['cartItem'] as Map<String, dynamic>;
        } else if (responseData['item'] != null) {
          cartItemData = responseData['item'] as Map<String, dynamic>;
        } else if (responseData['data'] != null) {
          cartItemData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Assume the response is the cart item itself
          cartItemData = responseData;
        }

        // Create a mock CartItem if the response doesn't contain all required fields
        if (cartItemData['_id'] == null && cartItemData['id'] == null) {
          // Generate a temporary ID for the new item
          cartItemData['_id'] = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        }

        if (cartItemData['addedAt'] == null) {
          cartItemData['addedAt'] = DateTime.now().toIso8601String();
        }

        final CartItem cartItem = CartItem.fromJson(cartItemData);
        print('CartService: Successfully added item to cart');
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

  /// Update cart item quantity
  static Future<CartItem> updateCartItem(String itemId, int quantity) async {
    try {
      print(
        'CartService: Updating cart item - itemId: $itemId, quantity: $quantity',
      );

      final response = await _apiClient.instance.put(
        '/cart/update/$itemId',
        data: {'quantity': quantity},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        print('CartService: Update cart item response: $responseData');

        // Handle different response structures
        Map<String, dynamic> cartItemData;

        if (responseData['cartItem'] != null) {
          cartItemData = responseData['cartItem'] as Map<String, dynamic>;
        } else if (responseData['item'] != null) {
          cartItemData = responseData['item'] as Map<String, dynamic>;
        } else if (responseData['data'] != null) {
          cartItemData = responseData['data'] as Map<String, dynamic>;
        } else {
          // Assume the response is the cart item itself
          cartItemData = responseData;
        }

        final CartItem cartItem = CartItem.fromJson(cartItemData);
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
  static Future<void> removeFromCart(String itemId) async {
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
  static Future<void> clearCart() async {
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
