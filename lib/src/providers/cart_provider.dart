import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../api/cart_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  double _totalPrice = 0.0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  double get totalPrice => _totalPrice;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cartItems.length;

  /// Fetch cart from backend
  Future<void> fetchCart() async {
    try {
      _setLoading(true);
      _clearError();

      final items = await CartService.getCart();
      _cartItems = items;
      _calculateTotalPrice();

      print('CartProvider: Fetched ${items.length} cart items');
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch cart: $e');
      print('CartProvider: Error fetching cart - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add item to cart
  Future<void> addItem(String serviceId, int quantity) async {
    try {
      _setLoading(true);
      _clearError();

      final newItem = await CartService.addToCart(serviceId, quantity);

      // Check if item already exists with same serviceId and packageId
      final existingIndex = _cartItems.indexWhere(
        (item) =>
            item.serviceId == serviceId && item.packageId == newItem.packageId,
      );

      if (existingIndex != -1) {
        // Update existing item quantity
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + quantity,
        );
      } else {
        // Add new item
        _cartItems.add(newItem);
      }

      _calculateTotalPrice();
      print(
        'CartProvider: Added item to cart - serviceId: $serviceId, quantity: $quantity',
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to add item: $e');
      print('CartProvider: Error adding item - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update item quantity
  Future<void> updateItem(String itemId, int quantity) async {
    try {
      _setLoading(true);
      _clearError();

      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        await removeItem(itemId);
        return;
      }

      final updatedItem = await CartService.updateCartItem(itemId, quantity);

      final index = _cartItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _cartItems[index] = updatedItem;
        _calculateTotalPrice();
        print(
          'CartProvider: Updated item quantity - itemId: $itemId, quantity: $quantity',
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update item: $e');
      print('CartProvider: Error updating item - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    try {
      _setLoading(true);
      _clearError();

      await CartService.removeFromCart(itemId);

      _cartItems.removeWhere((item) => item.id == itemId);
      _calculateTotalPrice();

      print('CartProvider: Removed item from cart - itemId: $itemId');
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove item: $e');
      print('CartProvider: Error removing item - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      _setLoading(true);
      _clearError();

      await CartService.clearCart();

      _cartItems.clear();
      _totalPrice = 0.0;

      print('CartProvider: Cleared entire cart');
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear cart: $e');
      print('CartProvider: Error clearing cart - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Calculate total price of all items
  void _calculateTotalPrice() {
    _totalPrice = _cartItems.fold(
      0.0,
      (total, item) => total + (item.price * item.quantity),
    );
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
  }

  /// Check if cart is empty
  bool get isEmpty => _cartItems.isEmpty;

  /// Get item by ID
  CartItem? getItemById(String itemId) {
    try {
      return _cartItems.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Get items by service ID
  List<CartItem> getItemsByServiceId(String serviceId) {
    return _cartItems.where((item) => item.serviceId == serviceId).toList();
  }

  /// Check if service is already in cart
  bool isServiceInCart(String serviceId) {
    return _cartItems.any((item) => item.serviceId == serviceId);
  }

  /// Get total quantity of a specific service
  int getServiceQuantity(String serviceId) {
    return _cartItems
        .where((item) => item.serviceId == serviceId)
        .fold(0, (total, item) => total + item.quantity);
  }
}
