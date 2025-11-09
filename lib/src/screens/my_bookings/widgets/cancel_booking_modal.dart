import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/booking.dart';
import '../../../providers/booking_provider.dart';

class CancelBookingModal extends StatefulWidget {
  final Booking booking;
  final VoidCallback onCancelled;

  const CancelBookingModal({
    super.key,
    required this.booking,
    required this.onCancelled,
  });

  @override
  State<CancelBookingModal> createState() => _CancelBookingModalState();
}

class _CancelBookingModalState extends State<CancelBookingModal>
    with SingleTickerProviderStateMixin {
  String _selectedReason = '';
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingCancellationDetails = true;
  Map<String, dynamic>? _cancellationDetails;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, String>> _cancellationReasons = [
    {'value': 'change-of-plans', 'label': 'Change of plans'},
    {'value': 'another-provider', 'label': 'Found another provider'},
    {'value': 'unavailable', 'label': 'Service provider unavailable'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
    _loadCancellationDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCancellationDetails() async {
    setState(() {
      _isLoadingCancellationDetails = true;
    });

    try {
      final details = await context
          .read<BookingProvider>()
          .getCancellationDetails(widget.booking.id!);

      if (mounted) {
        setState(() {
          _cancellationDetails = details;
        });
      }
    } catch (e) {
      // Handle error - use fallback calculation
      final now = DateTime.now();
      final bookingDateTime = DateTime(
        widget.booking.bookingDate.year,
        widget.booking.bookingDate.month,
        widget.booking.bookingDate.day,
      );

      final timeToBooking = bookingDateTime.difference(now).inHours;
      final isSameDay =
          now.year == bookingDateTime.year &&
          now.month == bookingDateTime.month &&
          now.day == bookingDateTime.day;

      bool isFreeCancellation;
      String type;

      if (isSameDay) {
        type = 'same-day';
        final timeSinceBooking = now
            .difference(widget.booking.createdAt)
            .inMinutes;
        isFreeCancellation = timeSinceBooking <= 15;
      } else {
        type = 'future';
        isFreeCancellation = timeToBooking > 3;
      }

      if (mounted) {
        setState(() {
          _cancellationDetails = {
            'type': type,
            'isFreeCancellation': isFreeCancellation,
            'feeAmount': widget.booking.cancellationFee ?? 200.0,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCancellationDetails = false;
        });
      }
    }
  }

  Future<void> _submitCancellation() async {
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a cancellation reason'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await context
          .read<BookingProvider>()
          .cancelBookingWithReason(
            widget.booking.id!,
            _selectedReason,
            _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );

      if (success && mounted) {
        widget.onCancelled();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking cancelled successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling booking: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Card(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.cancel_outlined,
                          color: theme.colorScheme.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cancel Booking?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cancellation Policy Information
                        if (_isLoadingCancellationDetails) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          const Center(
                            child: Text('Checking cancellation policy...'),
                          ),
                        ] else if (_cancellationDetails != null) ...[
                          Card(
                            color: _cancellationDetails!['isFreeCancellation']
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _cancellationDetails!['isFreeCancellation']
                                            ? Icons.check_circle
                                            : Icons.info_outline,
                                        color: _cancellationDetails!['isFreeCancellation']
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _cancellationDetails!['isFreeCancellation']
                                            ? 'Free Cancellation'
                                            : 'Cancellation Fee Applies',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: _cancellationDetails!['isFreeCancellation']
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _cancellationDetails!['isFreeCancellation']
                                        ? 'This is a ${_cancellationDetails!['type']} booking. Cancellation is currently free of charge.'
                                        : 'This is a ${_cancellationDetails!['type']} booking. A cancellation fee of ₹${_cancellationDetails!['feeAmount'].toStringAsFixed(2)} will be applied.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Cancellation Reason
                        Text(
                          'Cancellation Reason *',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedReason.isEmpty ? null : _selectedReason,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              hintText: 'Select a reason',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            dropdownColor: theme.colorScheme.surface,
                            style: theme.textTheme.bodyLarge,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            items: _cancellationReasons.map((reason) {
                              return DropdownMenuItem<String>(
                                value: reason['value'],
                                child: Text(reason['label']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedReason = value ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Additional Message
                        Text(
                          'Additional Message (Optional)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _messageController,
                          maxLines: 4,
                          maxLength: 200,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Provide additional details...',
                            counterText: '${_messageController.text.length}/200',
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting || _selectedReason.isEmpty
                              ? null
                              : _submitCancellation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Confirm Cancellation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
