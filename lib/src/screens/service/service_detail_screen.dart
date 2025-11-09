import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../models/service_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

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

          // Log the data types for debugging
          print(
            'Debug: serviceId type: ${firstPackage['serviceId']?.runtimeType}, value: ${firstPackage['serviceId']}',
          );
          print(
            'Debug: price type: ${firstPackage['price']?.runtimeType}, value: ${firstPackage['price']}',
          );
          print(
            'Debug: code type: ${firstPackage['code']?.runtimeType}, value: ${firstPackage['code']}',
          );

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(service?.title ?? 'Service Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchServiceDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : service == null
          ? const Center(child: Text('No service found'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Header
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service!.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service!.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Available Packages Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Available Packages',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Packages List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final package = packages[index];
                      return _buildPackageCard(package);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard(dynamic package) {
    final String packageName = package['name'] ?? 'Unknown Package';
    final int price = _safeParseInt(package['price']);
    final String duration = package['duration'] ?? '';
    final List<dynamic> features = package['features'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (duration.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            duration,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹$price',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Package Features
            if (features.isNotEmpty) ...[
              const Text(
                'Package Features:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...features.map(
                (feature) => _buildFeatureItem(_safeToString(feature)),
              ),
            ],

            const SizedBox(height: 16),

            // Book Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement booking functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking for $packageName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Book This Package',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quantity Selector
            Row(
              children: [
                const Text(
                  'Quantity: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                _buildQuantitySelector(package),
              ],
            ),

            const SizedBox(height: 12),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _addToCart(package),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrease button
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: currentQuantity > 1
              ? () => _updatePackageQuantity(packageId, currentQuantity - 1)
              : null,
          color: currentQuantity > 1 ? Colors.red[600] : Colors.grey[400],
          iconSize: 24,
        ),

        // Quantity display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Text(
            '$currentQuantity',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        // Increase button
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: currentQuantity < 10
              ? () => _updatePackageQuantity(packageId, currentQuantity + 1)
              : null,
          color: currentQuantity < 10 ? Colors.green[600] : Colors.grey[400],
          iconSize: 24,
        ),
      ],
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
          title: const Text('Sign in Required'),
          content: const Text(
            'Please sign in to add items to your cart. Create an account or login to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
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

      print('ServiceDetailScreen: Extracted price from package: $price');
      print('ServiceDetailScreen: Package data: $package');

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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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
            title: const Text('Session Expired'),
            content: const Text(
              'Your session has expired. Please login again to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Login'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
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
