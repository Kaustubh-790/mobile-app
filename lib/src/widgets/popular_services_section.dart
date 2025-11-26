import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/services_provider.dart';
import '../models/service_model.dart';
import 'service_card.dart';
import '../theme/app_theme.dart';

class PopularServicesSection extends StatefulWidget {
  const PopularServicesSection({super.key});

  @override
  State<PopularServicesSection> createState() => _PopularServicesSectionState();
}

class _PopularServicesSectionState extends State<PopularServicesSection> {
  @override
  void initState() {
    super.initState();
    // Fetch popular services when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesProvider>().fetchPopularServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ServicesProvider>(
      builder: (context, servicesProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Services',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
                    ),
                  ),
                  if (!servicesProvider.isLoading)
                    TextButton(
                      onPressed: () {
                        servicesProvider.refreshPopularServices();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryDefault,
                      ),
                      child: const Text('Refresh'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content based on state
            if (servicesProvider.isLoading)
              _buildLoadingState()
            else if (servicesProvider.error != null)
              _buildErrorState(servicesProvider.error!, servicesProvider)
            else if (servicesProvider.popularServices.isEmpty)
              _buildEmptyState()
            else
              _buildServicesGrid(servicesProvider.popularServices),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryDefault,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading popular services...',
              style: TextStyle(color: AppTheme.brown300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ServicesProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 40),
          const SizedBox(height: 12),
          Text(
            'Failed to load services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.replaceAll('Exception: ', ''),
            style: TextStyle(fontSize: 14, color: AppTheme.brown400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              provider.fetchPopularServices();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.brown200),
            const SizedBox(height: 16),
            Text(
              'No popular services available',
              style: TextStyle(fontSize: 16, color: AppTheme.brown300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(List<ServiceModel> services) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75, // Taller cards
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCard(
            service: service,
            onTap: () {
              _handleServiceTap(service);
            },
          );
        },
      ),
    );
  }

  void _handleServiceTap(ServiceModel service) {
    // Handle service selection - you can navigate to service details
    // or show a bottom sheet, etc.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildServiceDetailSheet(service),
    );
  }

  Widget _buildServiceDetailSheet(ServiceModel service) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.brown200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Service details
          Text(
            service.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.brown500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            service.description,
            style: TextStyle(fontSize: 16, color: AppTheme.brown300),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Text(
                'Price: ₹${service.price}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDefault,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 24,
                    color: service.rating > 0
                        ? const Color(0xFFD4A373)
                        : AppTheme.brown200,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    service.rating > 0 ? service.rating.toString() : 'New',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brown500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.brown500,
                    side: const BorderSide(color: AppTheme.brown300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement booking logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking ${service.title}...'),
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
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),

          // Safe area padding for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
