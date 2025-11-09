import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/status_utils.dart';
import 'service_details_section.dart';
import 'cancel_booking_modal.dart';

class BookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onRefresh,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _getCompletionProgress();
    final canCancel = _canCancel();
    final isUnpaid = widget.booking.paymentStatus != 'completed';
    final statusColor = StatusUtils.getStatusColor(widget.booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _toggleExpansion,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row - Booking ID and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatBookingId(widget.booking.id ?? ''),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    StatusUtils.getStatusIcon(
                                      widget.booking.status,
                                    ),
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.booking.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${widget.booking.totalAmount.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_up,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${progress['completedServices']}/${progress['totalServices']} completed',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              value: progress['percentage']! / 100,
                              backgroundColor: theme.colorScheme.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Date and Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatDate(widget.booking.bookingDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '|',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.booking.bookingTime,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.booking.address ?? widget.booking.customerInfo.address,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Payment Method
                  Row(
                    children: [
                      Icon(
                        Icons.payment,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Method: ',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        widget.booking.paymentMethod ?? 'Card',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      if (canCancel && widget.booking.status != 'completed')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => CancelBookingModal(
                                  booking: widget.booking,
                                  onCancelled: widget.onRefresh,
                                ),
                              );
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(
                                color: theme.colorScheme.error,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      if (canCancel &&
                          widget.booking.status != 'completed' &&
                          isUnpaid)
                        const SizedBox(width: 12),
                      if (isUnpaid && widget.booking.status != 'cancelled')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/payment',
                                arguments: {
                                  'bookingId': widget.booking.id,
                                  'cartId': widget.booking.cartId,
                                  'amount': widget.booking.totalAmount,
                                  'fromBookings': true,
                                },
                              );
                            },
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Pay Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Expandable Services Section
            AnimatedBuilder(
              animation: _heightAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _heightAnimation.value,
                    child: _isExpanded
                        ? ServiceDetailsSection(
                            booking: widget.booking,
                            onRefresh: widget.onRefresh,
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getCompletionProgress() {
    final totalServices = widget.booking.services.length;
    final completedServices = widget.booking.services
        .where((service) => service.completedByWorker)
        .length;
    final percentage = totalServices > 0
        ? ((completedServices / totalServices) * 100).round()
        : 0;

    return {
      'totalServices': totalServices,
      'completedServices': completedServices,
      'percentage': percentage,
    };
  }

  bool _canCancel() {
    final isCompleted = widget.booking.services.every(
      (service) => service.status == 'completed',
    );
    final isCancelled = widget.booking.status == 'cancelled';
    final canCancel =
        !isCompleted &&
        !isCancelled &&
        widget.booking.services.every(
          (service) => service.status != 'completed',
        );
    return canCancel;
  }

  String _formatBookingId(String id) {
    if (id.length >= 6) {
      return 'BK-${id.substring(id.length - 6).toUpperCase()}';
    }
    return 'BK-$id';
  }
}
