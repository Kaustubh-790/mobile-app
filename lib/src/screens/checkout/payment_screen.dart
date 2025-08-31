import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_item.dart';
import '../../models/booking.dart';
import '../../api/payment_service.dart';
import '../../api/api_client.dart';
import '../../providers/booking_provider.dart';

class PaymentScreen extends StatefulWidget {
  final Booking? existingBooking;
  final List<CartItem> cartItems;
  final double totalAmount;
  final String address;
  final String? notes;
  final DateTime bookingDate;
  final String bookingTime;

  const PaymentScreen({
    super.key,
    this.existingBooking,
    required this.cartItems,
    required this.totalAmount,
    required this.address,
    this.notes,
    required this.bookingDate,
    required this.bookingTime,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isProcessing = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if available from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser?.email != null) {
        _emailController.text = authProvider.currentUser!.email!;
      }

      // For testing: pre-fill with test data
      _cardNumberController.text = '4111111111111111';
      _cardNameController.text = 'Test User';
      _expiryController.text = '12/25';
      _cvvController.text = '123';
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Format card number with spaces
  void _formatCardNumber(String value) {
    // Remove all non-digits first
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Limit to 19 digits (longest card number)
    final limitedDigits = digitsOnly.length > 19
        ? digitsOnly.substring(0, 19)
        : digitsOnly;

    // Format with spaces every 4 digits
    final groups = <String>[];
    for (int i = 0; i < limitedDigits.length; i += 4) {
      groups.add(
        limitedDigits.substring(
          i,
          i + 4 > limitedDigits.length ? limitedDigits.length : i + 4,
        ),
      );
    }
    final result = groups.join(' ');

    // Update the controller only if the value changed
    if (result != value) {
      _cardNumberController.value = TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }
  }

  // Format expiry date
  void _formatExpiryDate(String value) {
    if (value.length <= 5) {
      final formatted = value.replaceAll('/', '');
      if (formatted.length >= 2) {
        final month = formatted.substring(0, 2);
        final year = formatted.substring(2);
        final result = '$month/$year';
        if (result != value) {
          _expiryController.value = TextEditingValue(
            text: result,
            selection: TextSelection.collapsed(offset: result.length),
          );
        }
      }
    }
  }

  bool _isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');

    // For testing: just check if it's 13-19 digits
    if (cleanNumber.length < 13 || cleanNumber.length > 19) return false;

    // For testing: just check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) return false;

    return true;
  }

  // Validate expiry date
  bool _isValidExpiryDate(String expiry) {
    if (expiry.length != 5) return false;

    try {
      final parts = expiry.split('/');
      if (parts.length != 2) return false;

      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      if (month < 1 || month > 12) return false;

      // For testing: remove date validation
      // final now = DateTime.now();
      // final currentYear = now.year % 100;
      // final currentMonth = now.month;

      // if (year < currentYear || (year == currentYear && month < currentMonth)) {
      //   return false;
      // }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Validate card number
      if (!_isValidCardNumber(_cardNumberController.text)) {
        throw Exception('Invalid card number');
      }

      // Validate expiry date
      if (!_isValidExpiryDate(_expiryController.text)) {
        throw Exception('Invalid expiry date');
      }

      // Check if we have an existing booking
      if (widget.existingBooking == null) {
        throw Exception('No booking found. Please go back and try again.');
      }

      // Check if booking has required fields
      if (widget.existingBooking!.id == null) {
        throw Exception('Invalid booking: missing booking ID');
      }

      // Process payment for the existing booking
      final paymentService = PaymentService(ApiClient.dio);

      await paymentService.processPayment(
        bookingId: widget.existingBooking!.id!,
        cartId: widget.existingBooking!.cartId,
        amount: widget.totalAmount,
        paymentMethod: 'card',
        cardLast4: _cardNumberController.text
            .replaceAll(' ', '')
            .substring(
              _cardNumberController.text.replaceAll(' ', '').length - 4,
            ),
        transactionDetails: {
          'email': _emailController.text.trim(),
          'cardName': _cardNameController.text.trim(),
          'expiryDate': _expiryController.text.trim(),
        },
      );

      // Update booking payment status to completed
      if (mounted) {
        final bookingProvider = context.read<BookingProvider>();
        await bookingProvider.updatePaymentStatus(
          widget.existingBooking!.id!,
          'completed',
          'card',
          _cardNumberController.text
              .replaceAll(' ', '')
              .substring(
                _cardNumberController.text.replaceAll(' ', '').length - 4,
              ),
        );
      }

      // Payment successful - navigate to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              booking: widget.existingBooking,
              cartItems: widget.cartItems,
              totalAmount: widget.totalAmount,
              address: widget.address,
              notes: widget.notes,
              bookingDate: widget.bookingDate,
              bookingTime: widget.bookingTime,
              paymentMethod: 'card',
              cardLast4: _cardNumberController.text
                  .replaceAll(' ', '')
                  .substring(
                    _cardNumberController.text.replaceAll(' ', '').length - 4,
                  ),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              _buildOrderSummaryCard(),
              const SizedBox(height: 24),

              // Payment Details Card
              _buildPaymentDetailsCard(),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200] ?? Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 16),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Pay Securely',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Security Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200] ?? Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your payment information is secure and encrypted',
                        style: TextStyle(color: Colors.blue[700]),
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

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Details
            ...widget.cartItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.packageName ?? 'Service',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.duration != null)
                                Text(
                                  item.duration!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Qty: ${item.quantity}',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 32),

            // Booking Details
            _buildSummaryRow(
              'Date',
              '${widget.bookingDate.day}/${widget.bookingDate.month}/${widget.bookingDate.year}',
            ),
            _buildSummaryRow('Time', widget.bookingTime),
            _buildSummaryRow('Address', widget.address),
            if (widget.notes != null && widget.notes!.isNotEmpty)
              _buildSummaryRow('Notes', widget.notes!),

            const Divider(height: 32),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Card Number
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              maxLength: 19, // Remove spaces for testing
              // onChanged: _formatCardNumber, // Disable formatting for testing
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter card number';
                }
                final cleanNumber = value.replaceAll(' ', '');
                if (cleanNumber.length < 13) {
                  return 'Card number too short';
                }
                if (cleanNumber.length > 19) {
                  return 'Card number too long';
                }
                if (!_isValidCardNumber(value)) {
                  return 'Please enter a valid card number';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Card Name
            TextFormField(
              controller: _cardNameController,
              decoration: const InputDecoration(
                labelText: 'Name on Card',
                hintText: 'Cardholder name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter name on card';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Expiry and CVV
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    onChanged: _formatExpiryDate,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter expiry date';
                      }
                      if (value.length != 5) {
                        return 'Please enter MM/YY';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter CVV';
                      }
                      if (value.length != 3) {
                        return 'Please enter 3 digits';
                      }
                      return null;
                    },
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

class PaymentSuccessScreen extends StatelessWidget {
  final Booking? booking;
  final List<CartItem> cartItems;
  final double totalAmount;
  final String address;
  final String? notes;
  final DateTime bookingDate;
  final String bookingTime;
  final String paymentMethod;
  final String cardLast4;

  const PaymentSuccessScreen({
    super.key,
    this.booking,
    required this.cartItems,
    required this.totalAmount,
    required this.address,
    this.notes,
    required this.bookingDate,
    required this.bookingTime,
    required this.paymentMethod,
    required this.cardLast4,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Successful'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 32),

              // Success Message
              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your booking has been confirmed and payment processed successfully.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Payment Details Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Payment Method',
                        paymentMethod.toUpperCase(),
                      ),
                      _buildDetailRow(
                        'Card Number',
                        '**** **** **** $cardLast4',
                      ),
                      _buildDetailRow(
                        'Amount Paid',
                        '₹${totalAmount.toStringAsFixed(2)}',
                      ),
                      _buildDetailRow(
                        'Transaction ID',
                        'TXN${DateTime.now().millisecondsSinceEpoch}',
                      ),
                      _buildDetailRow(
                        'Date',
                        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to home
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Home'),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to bookings screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // TODO: Navigate to bookings screen
                  },
                  child: const Text('View My Bookings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
