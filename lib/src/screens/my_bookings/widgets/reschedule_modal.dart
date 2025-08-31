import 'package:flutter/material.dart';
import '../../../models/booking.dart';

class RescheduleModal extends StatefulWidget {
  final Booking booking;
  final int serviceIndex;
  final VoidCallback onRescheduled;

  const RescheduleModal({
    super.key,
    required this.booking,
    required this.serviceIndex,
    required this.onRescheduled,
  });

  @override
  State<RescheduleModal> createState() => _RescheduleModalState();
}

class _RescheduleModalState extends State<RescheduleModal> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set default values
    final service = widget.booking.services[widget.serviceIndex];
    _selectedDate = service.scheduledDate ?? widget.booking.bookingDate;
    _selectedTime = _parseTimeString(
      service.scheduledTime ?? widget.booking.bookingTime,
    );
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return const TimeOfDay(hour: 10, minute: 0);
  }

  Future<void> _selectDate() async {
    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;
    final maxDate = originalDate.add(const Duration(days: 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? originalDate,
      firstDate: originalDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8C11FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8C11FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _errorMessage = null;
      });
    }
  }

  bool _validateReschedule() {
    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _errorMessage = 'Please select both date and time';
      });
      return false;
    }

    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;
    final maxDate = originalDate.add(const Duration(days: 2));

    if (_selectedDate!.isBefore(originalDate)) {
      setState(() {
        _errorMessage = 'Cannot reschedule to before original date';
      });
      return false;
    }

    if (_selectedDate!.isAfter(maxDate)) {
      setState(() {
        _errorMessage =
            'You can only reschedule up to 2 days after original date';
      });
      return false;
    }

    return true;
  }

  Future<void> _submitReschedule() async {
    if (!_validateReschedule()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement reschedule API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        widget.onRescheduled();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service rescheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error rescheduling service: $e';
        });
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
    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;
    final originalTime = service.scheduledTime ?? widget.booking.bookingTime;

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
                const Icon(Icons.schedule, color: Color(0xFF8C11FF), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reschedule Service',
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

            Text(
              'Service: ${service.serviceId}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Original: ${_formatDate(originalDate)} at $originalTime',
              style: const TextStyle(color: Colors.orange, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Date Selection
            Text(
              'New Date (within 2 days of original)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF8C11FF),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : 'Select Date',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? Colors.white
                            : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Selection
            Text(
              'New Time',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color(0xFF8C11FF),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select Time',
                      style: TextStyle(
                        color: _selectedTime != null
                            ? Colors.white
                            : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReschedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8C11FF),
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
                        : const Text('Confirm Reschedule'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
