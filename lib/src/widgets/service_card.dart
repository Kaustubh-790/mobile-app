import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../screens/service/service_detail_screen.dart';
import '../theme/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40, // Card background
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppTheme.beige10,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: service.imageUrl.isNotEmpty
                          ? Image.network(
                              service.imageUrl.startsWith('http')
                                  ? service.imageUrl
                                  : 'http://karighar.onrender.com${service.imageUrl}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.construction,
                                    size: 30,
                                    color: AppTheme.brown200,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.primaryDefault
                                                  .withOpacity(0.5),
                                            ),
                                      ),
                                    );
                                  },
                            )
                          : Center(
                              child: Icon(
                                Icons.construction,
                                size: 30,
                                color: AppTheme.brown200,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Service Title
                Text(
                  service.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brown500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Service Description
                Text(
                  service.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.brown300,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Bottom Row with Badge and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Explore Button
                    GestureDetector(
                      onTap: () {
                        _navigateToServiceDetail(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.clay,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Explore',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.brown500,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),

                    // Rating/Status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: service.rating > 0
                              ? const Color(0xFFD4A373)
                              : AppTheme.brown200, // Gold-ish color for star
                        ),
                        const SizedBox(width: 2),
                        Text(
                          service.rating > 0 ? '${service.rating}' : 'New',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brown400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToServiceDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(serviceSlug: service.slug),
      ),
    );
  }
}
