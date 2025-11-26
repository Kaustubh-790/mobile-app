import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/service_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceSlug;

  const ServiceDetailScreen({super.key, required this.serviceSlug});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceModel? service;
  List<dynamic> packages = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> packageQuantities = {}; // Track quantity for each package

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await ApiClient.dio.get(
        '/packages?serviceId=${widget.serviceSlug}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> responseData = response.data as List<dynamic>;

        if (responseData.isNotEmpty) {
          // Get service info from the first package
          final firstPackage = responseData[0];

          // Ensure we have the required fields
          if (firstPackage == null) {
            throw Exception('Invalid package data received');
          }

          service = ServiceModel(
            id: firstPackage['serviceId']?.toString() ?? '',
            title: firstPackage['name'] ?? 'Unknown Service',
            description: 'Professional service packages available',
            imageUrl: '',
            rating: 0,
            isPopular: false,
            slug: widget.serviceSlug,
            isActive: firstPackage['isActive'] ?? true,
            price: _safeToString(firstPackage['price']),
            code: firstPackage['code']?.toString() ?? '',
            packages: responseData,
          );

          packages = responseData;
        }
      }
    } catch (e) {
      print('Error fetching service details: $e');
      if (e.toString().contains('type') &&
          e.toString().contains('is not a subtype')) {
        errorMessage = 'Data format error. Please contact support.';
      } else {
        errorMessage = 'Failed to load service details. Please try again.';
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _safeToString(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    return '0';
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  /// Get quantity for a specific package
  int _getPackageQuantity(String packageId) {
    return packageQuantities[packageId] ?? 1;
  }

  /// Update quantity for a specific package
  void _updatePackageQuantity(String packageId, int newQuantity) {
    if (newQuantity >= 1 && newQuantity <= 10) {
      setState(() {
        packageQuantities[packageId] = newQuantity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        title: Text(
          service?.title.toUpperCase() ?? 'SERVICE DETAILS',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: AppTheme.beigeDefault,
        foregroundColor: AppTheme.brown500,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brown500),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDefault),
              ),
            )
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.brown200),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(fontSize: 16, color: AppTheme.brown300),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchServiceDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDefault,
                      foregroundColor: AppTheme.beige4,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : service == null
          ? Center(child: Text('No service found', style: TextStyle(color: AppTheme.brown300)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Header
                  Container(
                    width: double.infinity,
                    color: AppTheme.beigeDefault,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service!.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brown500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          service!.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.brown300,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Available Packages Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Available Packages',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brown500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Packages List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final package = packages[index];
                      return _buildPackageCard(package, theme);
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard(dynamic package, ThemeData theme) {
    final String packageName = package['name'] ?? 'Unknown Package';
    final int price = _safeParseInt(package['price']);
    final String duration = package['duration'] ?? '';
    final List<dynamic> features = package['features'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brown500,
                        ),
                      ),
                      if (duration.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            duration,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.brown300,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.clay.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹$price',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDefault,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Package Features
            if (features.isNotEmpty) ...[
              Text(
                'Package Features:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brown500,
                ),
              ),
              const SizedBox(height: 12),
              ...features.map(
                (feature) => _buildFeatureItem(_safeToString(feature), theme),
              ),
            ],

            const SizedBox(height: 24),

            // Book Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement booking functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking for $packageName'),
                      backgroundColor: AppTheme.primaryDefault,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDefault,
                  foregroundColor: AppTheme.beige4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Book This Package',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quantity Selector
            Row(
              children: [
                Text(
                  'Quantity: ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brown500,
                  ),
                ),
                const Spacer(),
                _buildQuantitySelector(package),
              ],
            ),

            const SizedBox(height: 16),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _addToCart(package),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.brown500,
                  side: const BorderSide(color: AppTheme.brown300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.clay,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              feature,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.brown400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(dynamic package) {
    final String packageId =
        package['_id']?.toString() ?? package['id']?.toString() ?? '';
    final int currentQuantity = _getPackageQuantity(packageId);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.beige10,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: currentQuantity > 1
                ? () => _updatePackageQuantity(packageId, currentQuantity - 1)
                : null,
            color: currentQuantity > 1 ? AppTheme.brown500 : AppTheme.brown200,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),

          // Quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$currentQuantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
          ),

          // Increase button
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: currentQuantity < 10
                ? () => _updatePackageQuantity(packageId, currentQuantity + 1)
                : null,
            color: currentQuantity < 10 ? AppTheme.brown500 : AppTheme.brown200,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _addToCart(dynamic package) {
    // Check if user is authenticated
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      // Show login prompt
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.sand40,
          title: const Text('Sign in Required'),
          content: const Text(
            'Please sign in to add items to your cart. Create an account or login to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.brown300)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDefault,
                foregroundColor: AppTheme.beige4,
              ),
              child: const Text('Login / Register'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final cartProvider = context.read<CartProvider>();
      final serviceId = package['serviceId']?.toString() ?? '';
      final String packageId =
          package['_id']?.toString() ?? package['id']?.toString() ?? '';
      final int selectedQuantity = _getPackageQuantity(packageId);

      // Extract package details
      final String packageName =
          package['name']?.toString() ??
          package['packageName']?.toString() ??
          'Package';
      final String duration =
          package['duration']?.toString() ??
          package['packageDuration']?.toString() ??
          '';
      final double price = package['price'] is num
          ? (package['price'] as num).toDouble()
          : package['price'] is String
          ? double.tryParse(package['price'] as String) ?? 0.0
          : 0.0;

      if (serviceId.isNotEmpty) {
        // Get current user ID from auth provider
        final currentUser = context.read<AuthProvider>().currentUser;
        final userId = currentUser?.id;

        cartProvider.addItemWithDetails(
          serviceId,
          selectedQuantity,
          packageId: packageId,
          packageName: packageName,
          duration: duration,
          price: price,
          userId: userId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $selectedQuantity item(s) to cart'),
            backgroundColor: AppTheme.primaryDefault,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Service ID not found'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Check if it's an authentication error
      if (e.toString().contains('Authentication') ||
          e.toString().contains('401') ||
          e.toString().contains('expired') ||
          e.toString().contains('unauthorized')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.sand40,
            title: const Text('Session Expired'),
            content: const Text(
              'Your session has expired. Please login again to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.brown300)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDefault,
                  foregroundColor: AppTheme.beige4,
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
