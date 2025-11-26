import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_item.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import 'payment_screen.dart';
import '../../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  // Date and time selection
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    // Pre-fill address if available from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser?.address != null &&
          authProvider.currentUser!.address!.isNotEmpty) {
        _addressController.text = authProvider.currentUser!.address!;
      }
    });

    // Set default date to tomorrow and time to 10:00 AM (after 9:00 AM constraint)
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Date picker method
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryDefault,
              onPrimary: AppTheme.beige4,
              surface: AppTheme.sand40,
              onSurface: AppTheme.brown500,
            ),
            dialogBackgroundColor: AppTheme.sand40,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Time picker method
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryDefault,
              onPrimary: AppTheme.beige4,
              surface: AppTheme.sand40,
              onSurface: AppTheme.brown500,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTheme.sand40,
              hourMinuteTextColor: AppTheme.brown500,
              dayPeriodTextColor: AppTheme.brown500,
              dialHandColor: AppTheme.primaryDefault,
              dialBackgroundColor: AppTheme.beige10,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Validate time constraint (no bookings before 9:00 AM IST)
  String? _validateTime() {
    if (_selectedTime == null) {
      return 'Please select a preferred time';
    }

    // Check if time is before 9:00 AM
    if (_selectedTime!.hour < 9) {
      return 'Bookings cannot be scheduled before 9:00 AM IST';
    }

    return null;
  }

  // Validate date
  String? _validateDate() {
    if (_selectedDate == null) {
      return 'Please select a preferred date';
    }

    // Check if date in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    if (selected.isBefore(today)) {
      return 'Cannot select a date in the past';
    }

    return null;
  }

  // Format time for backend (HH:MM format)
  String _formatTimeForBackend(TimeOfDay time) {
    // Convert to 24-hour format and ensure two digits
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        title: Text(
          'CHECKOUT',
          style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 1.2),
        ),
        backgroundColor: AppTheme.beigeDefault,
        foregroundColor: AppTheme.brown500,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brown500),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryDefault,
                ),
              ),
            );
          }

          if (cartProvider.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: AppTheme.brown200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.brown500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some services to your cart before checkout',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.brown300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDefault,
                      foregroundColor: AppTheme.beige4,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Section
                  _buildOrderSummary(cartProvider, theme),
                  const SizedBox(height: 24),

                  // Address Section
                  _buildAddressSection(theme),
                  const SizedBox(height: 24),

                  // Date and Time Section
                  _buildDateTimeSection(theme),
                  const SizedBox(height: 24),

                  // Notes Section
                  _buildNotesSection(theme),
                  const SizedBox(height: 32),

                  // Total and Confirm Button
                  _buildTotalAndConfirmButton(cartProvider, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 16),
            ...cartProvider.cartItems.map(
              (item) => _buildCartItemTile(item, theme),
            ),
            const Divider(height: 32, color: AppTheme.beige10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brown500,
                  ),
                ),
                Text(
                  '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDefault,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemTile(CartItem item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.packageName ?? 'Service',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brown500,
                  ),
                ),
                if (item.duration != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.duration!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.brown300,
                    ),
                  ),
                ],
                if (item.customizations != null &&
                    item.customizations!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Customizations: ${item.customizations!.keys.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.brown300,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Qty: ${item.quantity}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.brown400,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.brown500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Address',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'Enter the address where you want the service',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.beige10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.beige10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryDefault),
                ),
                prefixIcon: Icon(Icons.location_on, color: AppTheme.brown400),
                filled: true,
                fillColor: AppTheme.sand50,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a service address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Preferred Date & Time',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brown500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '*',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bookings cannot be scheduled before 9:00 AM IST',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.clay,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Date Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brown400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.beige10),
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.sand50,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.brown400,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select Date',
                                style: TextStyle(
                                  color: _selectedDate != null
                                      ? AppTheme.brown500
                                      : AppTheme.brown300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_validateDate() != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _validateDate()!,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Time Selection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brown400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.beige10),
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.sand50,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppTheme.brown400,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime != null
                                    ? _formatTimeForBackend(_selectedTime!)
                                    : 'Select Time',
                                style: TextStyle(
                                  color: _selectedTime != null
                                      ? AppTheme.brown500
                                      : AppTheme.brown300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_validateTime() != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _validateTime()!,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Any special instructions or requirements',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.beige10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.beige10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryDefault),
                ),
                prefixIcon: Icon(Icons.note, color: AppTheme.brown400),
                filled: true,
                fillColor: AppTheme.sand50,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAndConfirmButton(
    CartProvider cartProvider,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Total Summary
        Container(
          decoration: BoxDecoration(
            color: AppTheme.sand40,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brown500,
                  ),
                ),
                Text(
                  '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDefault,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Confirm Booking Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _confirmBooking(cartProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDefault,
              foregroundColor: AppTheme.beige4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.beige4,
                      ),
                    ),
                  )
                : const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        // Terms and Conditions
        const SizedBox(height: 16),
        Text(
          'By proceeding to payment, you agree to our terms and conditions.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.brown300),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _confirmBooking(CartProvider cartProvider) async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate date and time
    final dateError = _validateDate();
    final timeError = _validateTime();

    if (dateError != null || timeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dateError ?? timeError ?? 'Please select valid date and time',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final bookingProvider = context.read<BookingProvider>();
      final authProvider = context.read<AuthProvider>();

      final userId = authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final cartId = cartProvider.cartId;
      if (cartId == null) {
        throw Exception('Cart ID not found. Please refresh your cart.');
      }

      // Get user profile data
      final user = authProvider.currentUser!;
      final userProfile = {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'address': user.address,
      };

      // Create booking first
      final booking = await bookingProvider.createBooking(
        cartProvider.cartItems,
        cartProvider.totalPrice,
        userId: userId,
        userProfile: userProfile,
        cartId: cartId,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        bookingDate: _selectedDate!,
        bookingTime: _formatTimeForBackend(_selectedTime!),
      );

      if (booking == null) {
        throw Exception(bookingProvider.error ?? 'Failed to create booking');
      }

      // Navigate to payment screen with the created booking
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              existingBooking: booking,
              cartItems: cartProvider.cartItems,
              totalAmount: cartProvider.totalPrice,
              address: _addressController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              bookingDate: _selectedDate!,
              bookingTime: _formatTimeForBackend(_selectedTime!),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class CheckoutSuccessScreen extends StatelessWidget {
  final Booking booking;

  const CheckoutSuccessScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        title: Text(
          'BOOKING CONFIRMED',
          style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 1.2),
        ),
        backgroundColor: AppTheme.primaryDefault,
        foregroundColor: AppTheme.beige4,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Booking Confirmed!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brown500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your booking has been successfully created.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.brown300,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Booking Details Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.sand40,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDetailRow('Booking ID', booking.id ?? 'N/A', theme),
                      _buildDetailRow(
                        'Total Amount',
                        '₹${booking.totalAmount.toStringAsFixed(2)}',
                        theme,
                        isHighlight: true,
                      ),
                      _buildDetailRow(
                        'Status',
                        booking.status.toUpperCase(),
                        theme,
                      ),
                      _buildDetailRow(
                        'Address',
                        booking.address ?? 'Not Specified',
                        theme,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to home and clear stack
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDefault,
                    foregroundColor: AppTheme.beige4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.brown300,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isHighlight
                    ? AppTheme.primaryDefault
                    : AppTheme.brown500,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
