import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../utils/status_utils.dart';
import 'rating_modal.dart';
import 'reschedule_modal.dart';

class ServiceItemCard extends StatelessWidget {
  final BookingService service;
  final Booking booking;
  final int serviceIndex;
  final VoidCallback onRefresh;

  const ServiceItemCard({
    super.key,
    required this.service,
    required this.booking,
    required this.serviceIndex,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final canReschedule =
        service.status != 'completed' &&
        service.status != 'cancelled' &&
        (service.rescheduleCount < 2);
    final canRate = service.completedByWorker && service.serviceRating == null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.serviceId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${service.quantity}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: StatusUtils.getStatusColor(
                      service.status,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: StatusUtils.getStatusColor(
                        service.status,
                      ).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    StatusUtils.getStatusText(service.status),
                    style: TextStyle(
                      color: StatusUtils.getStatusColor(service.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price: ₹${service.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (service.rescheduleCount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Rescheduled ${service.rescheduleCount} time(s)',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (service.assignedWorkerId != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.person, color: Colors.blue, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        service.workerName ?? 'Worker Assigned',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canRate)
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => RatingModal(
                          booking: booking,
                          serviceIndex: serviceIndex,
                          onRated: onRefresh,
                        ),
                      );
                    },
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Rate & Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (canReschedule)
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => RescheduleModal(
                          booking: booking,
                          serviceIndex: serviceIndex,
                          onRescheduled: onRefresh,
                        ),
                      );
                    },
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Reschedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Show report modal
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report functionality coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.report, size: 16),
                  label: const Text('Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            // Rating Display
            if (service.serviceRating != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${service.serviceRating}/5',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (service.serviceReview != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '"${service.serviceReview}"',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
