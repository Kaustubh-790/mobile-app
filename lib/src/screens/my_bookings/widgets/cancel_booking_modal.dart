import 'package:flutter/material.dart';
import '../../../models/booking.dart';

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

class _CancelBookingModalState extends State<CancelBookingModal> {
  String _selectedReason = '';
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingCancellationDetails = true;
  Map<String, dynamic>? _cancellationDetails;

  final List<Map<String, String>> _cancellationReasons = [
    {'value': 'change-of-plans', 'label': 'Change of plans'},
    {'value': 'another-provider', 'label': 'Found another provider'},
    {'value': 'unavailable', 'label': 'Service provider unavailable'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCancellationDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCancellationDetails() async {
    setState(() {
      _isLoadingCancellationDetails = true;
    });

    try {
      // TODO: Implement API call to get cancellation details
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Calculate cancellation details based on booking
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
        // Free cancellation within 15 minutes of booking
        final timeSinceBooking = now
            .difference(widget.booking.createdAt)
            .inMinutes;
        isFreeCancellation = timeSinceBooking <= 15;
      } else {
        type = 'future';
        isFreeCancellation = timeToBooking > 3;
      }

      setState(() {
        _cancellationDetails = {
          'type': type,
          'isFreeCancellation': isFreeCancellation,
          'feeAmount': widget.booking.cancellationFee ?? 0.0,
        };
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoadingCancellationDetails = false;
      });
    }
  }

  Future<void> _submitCancellation() async {
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cancellation reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement cancellation API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        widget.onCancelled();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling booking: $e'),
            backgroundColor: Colors.red,
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
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancel Booking?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cancellation Policy Information
            if (_isLoadingCancellationDetails) ...[
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF8C11FF)),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Checking cancellation policy...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ] else if (_cancellationDetails != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cancellationDetails!['isFreeCancellation']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _cancellationDetails!['isFreeCancellation']
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
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
                              : Icons.info,
                          color: _cancellationDetails!['isFreeCancellation']
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _cancellationDetails!['isFreeCancellation']
                              ? 'Free Cancellation'
                              : 'Cancellation Fee Applies',
                          style: TextStyle(
                            color: _cancellationDetails!['isFreeCancellation']
                                ? Colors.green
                                : Colors.red,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cancellation Reason
            Text(
              'Cancellation Reason *',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedReason.isEmpty ? null : _selectedReason,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Select a reason',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
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
            const SizedBox(height: 16),

            // Additional Message
            Text(
              'Additional Message (Optional)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Provide additional details...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF8C11FF),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _selectedReason.isEmpty
                        ? null
                        : _submitCancellation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Confirm Cancellation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
