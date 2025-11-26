import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/cart_item.dart';
import '../../models/booking.dart';
import '../../api/payment_service.dart';
import '../../api/api_client.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        title: Text(
          'PAYMENT',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              _buildOrderSummaryCard(theme),
              const SizedBox(height: 24),

              // Payment Details Card
              _buildPaymentDetailsCard(theme),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.error),
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
                  color: AppTheme.clay.withOpacity(0.1),
                  border: Border.all(color: AppTheme.clay.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: AppTheme.clay),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your payment information is secure and encrypted',
                        style: TextStyle(color: AppTheme.brown500),
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

  Widget _buildOrderSummaryCard(ThemeData theme) {
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
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.brown400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
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
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.brown500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.duration != null)
                                Text(
                                  item.duration!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.brown300,
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.brown400,
                            ),
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brown500,
                            ),
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

            const Divider(height: 32, color: AppTheme.beige10),

            // Booking Details
            _buildSummaryRow(
              'Date',
              '${widget.bookingDate.day}/${widget.bookingDate.month}/${widget.bookingDate.year}',
              theme,
            ),
            _buildSummaryRow('Time', widget.bookingTime, theme),
            _buildSummaryRow('Address', widget.address, theme),
            if (widget.notes != null && widget.notes!.isNotEmpty)
              _buildSummaryRow('Notes', widget.notes!, theme),

            const Divider(height: 32, color: AppTheme.beige10),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total Amount',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
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

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.brown300,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.brown500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(ThemeData theme) {
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
                Icon(
                  Icons.credit_card,
                  color: AppTheme.brown400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
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
                prefixIcon: Icon(Icons.email, color: AppTheme.brown400),
                filled: true,
                fillColor: AppTheme.sand50,
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
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
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
                prefixIcon: Icon(Icons.credit_card, color: AppTheme.brown400),
                filled: true,
                fillColor: AppTheme.sand50,
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
              decoration: InputDecoration(
                labelText: 'Name on Card',
                hintText: 'Cardholder name',
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
                prefixIcon: Icon(Icons.person, color: AppTheme.brown400),
                filled: true,
                fillColor: AppTheme.sand50,
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
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
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
                      prefixIcon: Icon(Icons.calendar_today, color: AppTheme.brown400),
                      filled: true,
                      fillColor: AppTheme.sand50,
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
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
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
                      prefixIcon: Icon(Icons.security, color: AppTheme.brown400),
                      filled: true,
                      fillColor: AppTheme.sand50,
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        title: Text(
          'PAYMENT SUCCESSFUL',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
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
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 60, color: Colors.green[600]),
              ),
              const SizedBox(height: 32),

              // Success Message
              Text(
                'Payment Successful!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brown500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your booking has been confirmed and payment processed successfully.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.brown300,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Payment Details Card
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
                      _buildDetailRow(
                        'Payment Method',
                        paymentMethod.toUpperCase(),
                        theme,
                      ),
                      _buildDetailRow(
                        'Card Number',
                        '**** **** **** $cardLast4',
                        theme,
                      ),
                      _buildDetailRow(
                        'Amount Paid',
                        '₹${totalAmount.toStringAsFixed(2)}',
                        theme,
                        isHighlight: true,
                      ),
                      _buildDetailRow(
                        'Transaction ID',
                        'TXN${DateTime.now().millisecondsSinceEpoch}',
                        theme,
                      ),
                      _buildDetailRow(
                        'Date',
                        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
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
  
  Widget _buildDetailRow(String label, String value, ThemeData theme, {bool isHighlight = false}) {
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
                color: isHighlight ? AppTheme.primaryDefault : AppTheme.brown500,
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
