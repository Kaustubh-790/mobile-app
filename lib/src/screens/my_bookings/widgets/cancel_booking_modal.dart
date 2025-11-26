import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/booking.dart';
import '../../../providers/booking_provider.dart';
import '../../../theme/app_theme.dart';

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
          backgroundColor: AppTheme.error,
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
            backgroundColor: AppTheme.error,
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
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.beigeDefault,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cancel_outlined,
                        color: AppTheme.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Cancel Booking?',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brown500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: AppTheme.brown400),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.beige10),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
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
                        Center(
                          child: Text(
                            'Checking cancellation policy...',
                            style: TextStyle(color: AppTheme.brown300),
                          ),
                        ),
                      ] else if (_cancellationDetails != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cancellationDetails!['isFreeCancellation']
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _cancellationDetails!['isFreeCancellation']
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.brown500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Cancellation Reason
                      Text(
                        'Cancellation Reason *',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brown500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.sand50,
                          border: Border.all(
                            color: AppTheme.beige10,
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
                              color: AppTheme.brown300,
                            ),
                          ),
                          dropdownColor: AppTheme.sand50,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.brown500,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.brown400,
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
                          color: AppTheme.brown500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        maxLength: 200,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.brown500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Provide additional details...',
                          hintStyle: TextStyle(color: AppTheme.brown300),
                          counterText: '${_messageController.text.length}/200',
                          counterStyle: TextStyle(color: AppTheme.brown300),
                          contentPadding: const EdgeInsets.all(16),
                          filled: true,
                          fillColor: AppTheme.sand50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.beige10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.beige10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryDefault),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.beige10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: AppTheme.brown500,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting || _selectedReason.isEmpty
                            ? null
                            : _submitCancellation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
    );
  }
}
