import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/service_model.dart';

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

          // Extract service name from package name or use a more descriptive title
          String serviceName = firstPackage['name'] ?? 'Unknown Service';
          String serviceDescription = 'Professional service packages available';

          // Try to extract service type from the package name for better description
          if (serviceName.toLowerCase().contains('labour')) {
            serviceDescription =
                'Professional labour and construction services';
          } else if (serviceName.toLowerCase().contains('package')) {
            serviceDescription =
                'Comprehensive service packages tailored to your needs';
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
}
