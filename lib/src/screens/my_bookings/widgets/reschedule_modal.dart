import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
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
    // Initialize with current service date/time or booking date/time
    final service = widget.booking.services[widget.serviceIndex];
    _selectedDate = service.rescheduledDate ?? widget.booking.bookingDate;
    _selectedTime = service.rescheduledTime != null
        ? TimeOfDay.fromDateTime(
            DateTime.parse('2000-01-01 ${service.rescheduledTime}:00'),
          )
        : TimeOfDay.fromDateTime(
            DateTime.parse('2000-01-01 ${widget.booking.bookingTime}:00'),
          );
  }

  Future<void> _selectDate(BuildContext context) async {
    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? originalDate,
      firstDate: originalDate,
      lastDate: originalDate.add(const Duration(days: 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8C11FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A2E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8C11FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1A1A2E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitReschedule() async {
    if (_selectedDate == null || _selectedTime == null) {
      setState(() {
        _errorMessage = 'Please select both date and time';
      });
      return;
    }

    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;
    final originalDateObj = DateTime(
      originalDate.year,
      originalDate.month,
      originalDate.day,
    );
    final selectedDateObj = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    final maxDateObj = originalDateObj.add(const Duration(days: 2));

    if (selectedDateObj.isBefore(originalDateObj)) {
      setState(() {
        _errorMessage = 'Cannot reschedule to before original date';
      });
      return;
    } else if (selectedDateObj.isAfter(maxDateObj)) {
      setState(() {
        _errorMessage =
            'You can only reschedule up to 2 days after original date';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final newTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final success = await context.read<BookingProvider>().rescheduleService(
        widget.booking.id!,
        widget.serviceIndex,
        _selectedDate!,
        newTime,
      );

      if (success && mounted) {
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
          _errorMessage = e.toString();
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

            // Service Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
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
                    'Original: ${_formatDate(originalDate)} at $originalTime',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (service.rescheduleCount > 0) ...[
                    const SizedBox(height: 4),
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
            const SizedBox(height: 24),

            // New Date Selection
            Text(
              'New Date *',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF8C11FF)),
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
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // New Time Selection
            Text(
              'New Time *',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF8C11FF)),
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
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
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
                    onPressed:
                        _isSubmitting ||
                            _selectedDate == null ||
                            _selectedTime == null
                        ? null
                        : _submitReschedule,
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
