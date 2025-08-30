import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../api/cart_service.dart';
import '../models/user.dart';

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
  Future<void> fetchCart({String? userId}) async {
    try {
      _setLoading(true);
      _clearError();

      final items = await CartService.getCart(userId: userId);
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

  /// Add item to cart - DEPRECATED: Use addItemWithDetails instead
  @Deprecated('Use addItemWithDetails to ensure correct pricing')
  Future<void> addItem(
    String serviceId,
    int quantity, {
    String? userId,
    double? price,
  }) async {
    print(
      'CartProvider: addItem is deprecated, use addItemWithDetails instead',
    );
    // Fallback to addItemWithDetails with null packageId
    await addItemWithDetails(serviceId, quantity, userId: userId, price: price);
  }

  /// Add item to cart with full package details - This ensures backend gets packageId
  Future<void> addItemWithDetails(
    String serviceId,
    int quantity, {
    String? packageId,
    String? packageName,
    String? duration,
    double? price,
    String? userId,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('CartProvider: Adding item with details');
      print(
        'CartProvider: serviceId: $serviceId, packageId: $packageId, quantity: $quantity, price: $price',
      );

      // Check if item already exists with same serviceId and packageId
      final existingIndex = _cartItems.indexWhere(
        (item) => item.serviceId == serviceId && item.packageId == packageId,
      );

      if (existingIndex != -1) {
        // Update existing item quantity using backend
        final existingItem = _cartItems[existingIndex];
        await updateItem(
          existingItem.id,
          existingItem.quantity + quantity,
          userId: userId,
        );
        return;
      }

      try {
        // Add to backend - let backend calculate the price from packageId
        final newItem = await CartService.addToCart(
          serviceId,
          quantity,
          packageId:
              packageId, // This is crucial - backend needs this to calculate price
          userId: userId,
          customizations: customizations,
        );

        print(
          'CartProvider: Backend returned item with price: ${newItem.price}',
        );

        // If backend returned item with correct packageId and price, use it
        if (newItem.price > 0 ||
            (packageId != null && newItem.packageId == packageId)) {
          _cartItems.add(newItem);
        } else {
          // If backend didn't set correct details, enhance the item
          final enhancedItem = newItem.copyWith(
            packageId: packageId ?? newItem.packageId,
            packageName: packageName ?? newItem.packageName,
            duration: duration ?? newItem.duration,
            price: newItem.price > 0 ? newItem.price : (price ?? 0.0),
          );
          _cartItems.add(enhancedItem);
        }

        _calculateTotalPrice();
        print('CartProvider: Successfully added item via backend');
        notifyListeners();
      } catch (backendError) {
        print(
          'CartProvider: Backend add failed, using local fallback: $backendError',
        );

        // Fallback to local-only mode if backend fails
        final newItem = CartItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          serviceId: serviceId,
          packageId: packageId,
          packageName: packageName,
          duration: duration,
          quantity: quantity,
          price: price ?? 0.0,
          addedAt: DateTime.now().toIso8601String(),
          customizations: customizations,
        );

        _cartItems.add(newItem);
        _calculateTotalPrice();
        print('CartProvider: Added item using local fallback');
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add item to cart: $e');
      print('CartProvider: Error adding item with details - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add item using packageId directly - Ensures backend calculates correct price
  Future<void> addPackageToCart(
    String serviceId,
    String packageId,
    int quantity, {
    String? userId,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print(
        'CartProvider: Adding package to cart - serviceId: $serviceId, packageId: $packageId',
      );

      // Check if item already exists
      final existingIndex = _cartItems.indexWhere(
        (item) => item.serviceId == serviceId && item.packageId == packageId,
      );

      if (existingIndex != -1) {
        // Update existing item quantity
        final existingItem = _cartItems[existingIndex];
        await updateItem(
          existingItem.id,
          existingItem.quantity + quantity,
          userId: userId,
        );
        return;
      }

      // Add to backend using the new method
      final newItem = await CartService.addItemWithPackage(
        serviceId,
        quantity,
        packageId: packageId,
        userId: userId,
        customizations: customizations,
      );

      _cartItems.add(newItem);
      _calculateTotalPrice();
      print(
        'CartProvider: Successfully added package to cart with price: ${newItem.price}',
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to add package to cart: $e');
      print('CartProvider: Error adding package - $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update item quantity
  Future<void> updateItem(
    String itemId,
    int quantity, {
    String? userId,
    double? price,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (quantity <= 0) {
        await removeItem(itemId, userId: userId);
        return;
      }

      final updatedItem = await CartService.updateCartItem(
        itemId,
        quantity,
        userId: userId,
        price: price,
      );

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
  Future<void> removeItem(String itemId, {String? userId}) async {
    try {
      _setLoading(true);
      _clearError();

      await CartService.removeFromCart(itemId, userId: userId);

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
  Future<void> clearCart({String? userId}) async {
    try {
      _setLoading(true);
      _clearError();

      await CartService.clearCart(userId: userId);

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

  /// Check if specific package is in cart
  bool isPackageInCart(String serviceId, String packageId) {
    return _cartItems.any(
      (item) => item.serviceId == serviceId && item.packageId == packageId,
    );
  }

  /// Get total quantity of a specific service
  int getServiceQuantity(String serviceId) {
    return _cartItems
        .where((item) => item.serviceId == serviceId)
        .fold(0, (total, item) => total + item.quantity);
  }

  /// Get total quantity of a specific package
  int getPackageQuantity(String serviceId, String packageId) {
    return _cartItems
        .where(
          (item) => item.serviceId == serviceId && item.packageId == packageId,
        )
        .fold(0, (total, item) => total + item.quantity);
  }
}
