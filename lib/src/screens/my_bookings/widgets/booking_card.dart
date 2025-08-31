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
    final progress = _getCompletionProgress();
    final canCancel = _canCancel();
    final isUnpaid = widget.booking.paymentStatus != 'completed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          // Booking Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top row - Booking ID and Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatBookingId(widget.booking.id ?? ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: StatusUtils.getStatusColor(
                                widget.booking.status,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: StatusUtils.getStatusColor(
                                  widget.booking.status,
                                ).withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  StatusUtils.getStatusIcon(
                                    widget.booking.status,
                                  ),
                                  size: 16,
                                  color: StatusUtils.getStatusColor(
                                    widget.booking.status,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.booking.status.toUpperCase(),
                                  style: TextStyle(
                                    color: StatusUtils.getStatusColor(
                                      widget.booking.status,
                                    ),
                                    fontSize: 12,
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
                        Text(
                          '₹${widget.booking.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress['completedServices']}/${progress['totalServices']} completed',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: progress['percentage']! / 100,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF8C11FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Middle row - Date and Location
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF8C11FF),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormatter.formatDateTime(
                                widget.booking.bookingDate,
                                widget.booking.bookingTime,
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.booking.customerInfo.address,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Bottom row - Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleExpansion,
                        icon: Icon(
                          _isExpanded ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        label: Text(
                          _isExpanded ? 'Hide Details' : 'View Details',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C11FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isUnpaid && widget.booking.status != 'cancelled') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to payment screen
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Pay Now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (canCancel)
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => CancelBookingModal(
                              booking: widget.booking,
                              onCancelled: widget.onRefresh,
                            ),
                          );
                        },
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
              return SizeTransition(
                sizeFactor: _heightAnimation,
                child: _isExpanded
                    ? ServiceDetailsSection(
                        booking: widget.booking,
                        onRefresh: widget.onRefresh,
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
        ],
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
