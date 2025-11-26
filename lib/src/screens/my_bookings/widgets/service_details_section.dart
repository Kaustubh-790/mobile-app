import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/status_utils.dart';
import '../../../theme/app_theme.dart';
import 'service_item_card.dart';

class ServiceDetailsSection extends StatelessWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const ServiceDetailsSection({
    super.key,
    required this.booking,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services (${booking.services.length})',
              style: TextStyle(
                color: AppTheme.brown500,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: booking.services.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final service = booking.services[index];
                return ServiceItemCard(
                  service: service,
                  booking: booking,
                  serviceIndex: index,
                  onRefresh: onRefresh,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
