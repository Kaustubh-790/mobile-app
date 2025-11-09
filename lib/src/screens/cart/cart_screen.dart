import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../checkout/checkout_screen.dart';
import '../search/search_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch cart data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AuthProvider>().currentUser;
      final userId = currentUser?.id;
      context.read<CartProvider>().fetchCart(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // If not authenticated, show empty cart with browse services message
            if (!authProvider.isAuthenticated) {
              return _buildEmptyCart(theme, showLoginPrompt: false);
            }

            return Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                if (cartProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Check if error is due to authentication
                if (cartProvider.error != null) {
                  final isAuthError = cartProvider.error!.contains('Session expired') ||
                      cartProvider.error!.contains('Authentication') ||
                      cartProvider.error!.contains('log in again') ||
                      cartProvider.error!.contains('401') ||
                      cartProvider.error!.contains('unauthorized');
                  
                  if (isAuthError) {
                    return _buildLoginPrompt(theme);
                  }
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading cart',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            cartProvider.error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            final currentUser = context.read<AuthProvider>().currentUser;
                            final userId = currentUser?.id;
                            cartProvider.fetchCart(userId: userId);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (cartProvider.cartItems.isEmpty) {
                  return _buildEmptyCart(theme, showLoginPrompt: false);
                }

                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shopping Cart',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (cartProvider.cartItems.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.delete_sweep),
                              onPressed: () => _showClearCartDialog(context, cartProvider),
                              tooltip: 'Clear Cart',
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cartProvider.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartProvider.cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCartItemCard(context, item, cartProvider),
                          );
                        },
                      ),
                    ),
                    _buildBottomSection(context, cartProvider),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sign in to view your cart',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Login or create an account to add items to your cart and manage your bookings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.login),
              label: const Text('Login / Register'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(ThemeData theme, {bool showLoginPrompt = false}) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shopping Cart',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    showLoginPrompt ? 'Sign in to view your cart' : 'No items in cart',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showLoginPrompt 
                        ? 'Login or create an account to add items to your cart and manage your bookings.'
                        : 'Browse services to add items to your cart',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (showLoginPrompt) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Login / Register'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Browse Services'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: showLoginPrompt 
                          ? theme.colorScheme.surface 
                          : theme.colorScheme.primary,
                      foregroundColor: showLoginPrompt 
                          ? theme.colorScheme.onSurface 
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServiceDisplayName(item),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (item.packageName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Package: ${item.packageName}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                      if (item.duration != null &&
                          item.duration!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Duration: ${item.duration}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () =>
                      _showRemoveItemDialog(context, item, cartProvider),
                  tooltip: 'Remove item',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '₹ ${item.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuantityControls(context, item, cartProvider),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₹ ${(item.price * item.quantity).toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: item.quantity > 1
              ? () {
                  final currentUser = context.read<AuthProvider>().currentUser;
                  final userId = currentUser?.id;
                  cartProvider.updateItem(
                    item.id,
                    item.quantity - 1,
                    userId: userId,
                    price: item.price,
                  );
                }
              : null,
          color: item.quantity > 1
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${item.quantity}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            final currentUser = context.read<AuthProvider>().currentUser;
            final userId = currentUser?.id;
            cartProvider.updateItem(
              item.id,
              item.quantity + 1,
              userId: userId,
              price: item.price,
            );
          },
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹ ${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cartProvider.cartItems.isNotEmpty
                    ? () => _navigateToCheckout(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceDisplayName(CartItem item) {
    // Use serviceId as display name, but format it nicely
    if (item.serviceId == 'labour') {
      return 'LABOUR';
    }
    return item.serviceId.replaceAll('_', ' ').toUpperCase();
  }

  void _showRemoveItemDialog(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text(
            'Are you sure you want to remove "${_getServiceDisplayName(item)}" from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Get current user ID from auth provider
                final currentUser = context.read<AuthProvider>().currentUser;
                final userId = currentUser?.id;
                cartProvider.removeItem(item.id, userId: userId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text(
            'Are you sure you want to clear your entire cart? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Get current user ID from auth provider
                final currentUser = context.read<AuthProvider>().currentUser;
                final userId = currentUser?.id;
                cartProvider.clearCart(userId: userId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear Cart'),
            ),
          ],
        );
      },
    );
  }

  // In cart_screen.dart, replace the _showCheckoutPlaceholder function with:
  void _navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }
}
