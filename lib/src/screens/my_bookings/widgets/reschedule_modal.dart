import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../models/booking.dart';
import '../../../utils/date_formatter.dart';

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

class _RescheduleModalState extends State<RescheduleModal>
    with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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

    // Initialize with current service date/time or booking date/time
    final service = widget.booking.services[widget.serviceIndex];
    _selectedDate = service.scheduledDate ?? widget.booking.bookingDate;
    final timeString = service.scheduledTime ?? widget.booking.bookingTime;
    try {
      final timeParts = timeString.split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    } catch (e) {
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;
    final theme = Theme.of(context);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? originalDate,
      firstDate: DateTime.now(),
      lastDate: originalDate.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
            ),
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
    final theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      // Validate time constraint (no bookings before 9:00 AM)
      if (picked.hour < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookings cannot be scheduled before 9:00 AM IST'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
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

    // Validate time constraint
    if (_selectedTime!.hour < 9) {
      setState(() {
        _errorMessage = 'Bookings cannot be scheduled before 9:00 AM IST';
      });
      return;
    }

    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;
    final selectedDateObj = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    final originalDateObj = DateTime(
      originalDate.year,
      originalDate.month,
      originalDate.day,
    );

    if (selectedDateObj.isBefore(originalDateObj.subtract(const Duration(days: 1)))) {
      setState(() {
        _errorMessage = 'Cannot reschedule to more than 1 day before original date';
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
          SnackBar(
            content: const Text('Service rescheduled successfully!'),
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
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    final theme = Theme.of(context);
    final service = widget.booking.services[widget.serviceIndex];
    final originalDate = service.scheduledDate ?? widget.booking.bookingDate;
    final originalTime = service.scheduledTime ?? widget.booking.bookingTime;

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
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.schedule,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reschedule Service',
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
                        // Service Info Card
                        Card(
                          color: theme.colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.serviceId.toUpperCase(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Original: ${DateFormatter.formatDate(originalDate)} at $originalTime',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                if (service.rescheduleCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rescheduled ${service.rescheduleCount} time(s)',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // New Date Selection
                        Text(
                          'New Date *',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? DateFormatter.formatDate(_selectedDate!)
                                        : 'Select Date',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: _selectedDate != null
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // New Time Selection
                        Text(
                          'New Time *',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectTime(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedTime != null
                                        ? _formatTime(_selectedTime!)
                                        : 'Select Time',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: _selectedTime != null
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting ||
                                      _selectedDate == null ||
                                      _selectedTime == null
                                  ? null
                                  : _submitReschedule,
                          style: ElevatedButton.styleFrom(
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
                              : const Text('Confirm Reschedule'),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
