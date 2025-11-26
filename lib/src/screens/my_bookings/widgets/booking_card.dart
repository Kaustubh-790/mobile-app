import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/status_utils.dart';
import 'service_details_section.dart';
import 'cancel_booking_modal.dart';
import '../../../theme/app_theme.dart';

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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40, // Card Background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpansion,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row - Booking ID and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatBookingId(widget.booking.id ?? ''),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brown500,
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
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
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
                                        letterSpacing: 0.5,
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
                                    color: AppTheme.brown500,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppTheme.brown300,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${progress['completedServices']}/${progress['totalServices']} completed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.brown300,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 80,
                              child: LinearProgressIndicator(
                                value: progress['percentage']! / 100,
                                backgroundColor: AppTheme.beige10,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryDefault,
                                ),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(color: AppTheme.beige10, thickness: 1),
                    const SizedBox(height: 24),
                    
                    // Date and Time
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.clay.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.brown500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormatter.formatDate(widget.booking.bookingDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.brown200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.booking.bookingTime,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.clay.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppTheme.brown500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.booking.address ?? widget.booking.customerInfo.address,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.brown400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Method
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.clay.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payment,
                            size: 16,
                            color: AppTheme.brown500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Payment Method: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.brown300,
                          ),
                        ),
                        Text(
                          widget.booking.paymentMethod ?? 'Card',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brown500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
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
                                foregroundColor: AppTheme.error,
                                side: const BorderSide(
                                  color: AppTheme.error,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                backgroundColor: AppTheme.primaryDefault,
                                foregroundColor: AppTheme.beige4,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
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
                          ? Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppTheme.beige10),
                                ),
                              ),
                              child: ServiceDetailsSection(
                                booking: widget.booking,
                                onRefresh: widget.onRefresh,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ],
          ),
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
