import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../checkout/checkout_screen.dart';
import '../search/search_screen.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        backgroundColor: AppTheme.beigeDefault,
        title: Text(
          'SHOPPING CART',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.cartItems.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep, color: AppTheme.brown500),
                  onPressed: () => _showClearCartDialog(context, cartProvider),
                  tooltip: 'Clear Cart',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDefault),
                    ),
                  );
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
                        Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading cart',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.brown500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            cartProvider.error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.brown300,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryDefault,
                            foregroundColor: AppTheme.beige4,
                          ),
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
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: cartProvider.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartProvider.cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.sand50,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.beige10),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppTheme.brown300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sign in to view your cart',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.brown500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Login or create an account to add items to your cart and manage your bookings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.brown300,
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
                backgroundColor: AppTheme.primaryDefault,
                foregroundColor: AppTheme.beige4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(ThemeData theme, {bool showLoginPrompt = false}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.sand50,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.beige10),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppTheme.brown200,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              showLoginPrompt ? 'Sign in to view your cart' : 'No items in cart',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              showLoginPrompt 
                  ? 'Login or create an account to add items to your cart and manage your bookings.'
                  : 'Browse services to add items to your cart',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.brown300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                    backgroundColor: AppTheme.primaryDefault,
                    foregroundColor: AppTheme.beige4,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                backgroundColor: showLoginPrompt 
                    ? AppTheme.sand40 
                    : AppTheme.primaryDefault,
                foregroundColor: showLoginPrompt 
                    ? AppTheme.brown500 
                    : AppTheme.beige4,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServiceDisplayName(item),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brown500,
                        ),
                      ),
                      if (item.packageName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Package: ${item.packageName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.brown300,
                          ),
                        ),
                      ],
                      if (item.duration != null &&
                          item.duration!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Duration: ${item.duration}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.brown300,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                  onPressed: () =>
                      _showRemoveItemDialog(context, item, cartProvider),
                  tooltip: 'Remove item',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '₹ ${item.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryDefault,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuantityControls(context, item, cartProvider),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppTheme.beige10),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.brown400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹ ${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.brown500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.beige10,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
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
            color: item.quantity > 1 ? AppTheme.brown500 : AppTheme.brown200,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.quantity}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
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
            color: AppTheme.brown500,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, CartProvider cartProvider) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.brown400,
                  ),
                ),
                Text(
                  '₹ ${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryDefault,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cartProvider.cartItems.isNotEmpty
                    ? () => _navigateToCheckout(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDefault,
                  foregroundColor: AppTheme.beige4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Proceed to Checkout',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.beige4,
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
          backgroundColor: AppTheme.sand40,
          title: const Text('Remove Item'),
          content: Text(
            'Are you sure you want to remove "${_getServiceDisplayName(item)}" from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.brown300)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Get current user ID from auth provider
                final currentUser = context.read<AuthProvider>().currentUser;
                final userId = currentUser?.id;
                cartProvider.removeItem(item.id, userId: userId);
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
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
          backgroundColor: AppTheme.sand40,
          title: const Text('Clear Cart'),
          content: const Text(
            'Are you sure you want to clear your entire cart? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.brown300)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Get current user ID from auth provider
                final currentUser = context.read<AuthProvider>().currentUser;
                final userId = currentUser?.id;
                cartProvider.clearCart(userId: userId);
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Clear Cart'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutScreen()),
    );
  }
}
