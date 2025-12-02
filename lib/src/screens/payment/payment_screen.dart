import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/payment_service.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final String cartId;
  final double amount;
  final bool fromBookings;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.cartId,
    required this.amount,
    this.fromBookings = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardholderNameController =
      TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'card', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'value': 'upi', 'label': 'UPI', 'icon': Icons.account_balance},
    {
      'value': 'netbanking',
      'label': 'Net Banking',
      'icon': Icons.account_balance_wallet,
    },
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'card') {
      if (_cardNumberController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty ||
          _cardholderNameController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all card details';
        });
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Create payment service instance
      final paymentService = PaymentService(ApiClient().instance);

      // Process payment
      final paymentResult = await paymentService.processPayment(
        bookingId: widget.bookingId,
        cartId: widget.cartId,
        amount: widget.amount,
        paymentMethod: _selectedPaymentMethod,
        cardLast4: _cardNumberController.text.isNotEmpty
            ? _cardNumberController.text.substring(
                _cardNumberController.text.length - 4,
              )
            : '',
        transactionDetails: {
          'cardNumber': _cardNumberController.text,
          'expiry': _expiryController.text,
          'cvv': _cvvController.text,
          'cardholderName': _cardholderNameController.text,
        },
      );

      // Update booking payment status
      final success = await context.read<BookingProvider>().updatePaymentStatus(
        widget.bookingId,
        'completed',
        _selectedPaymentMethod,
        _cardNumberController.text.isNotEmpty
            ? _cardNumberController.text.substring(
                _cardNumberController.text.length - 4,
              )
            : '',
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate back or to bookings
        if (widget.fromBookings) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, '/bookings');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.brown500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount to Pay:',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.brown300,
                        ),
                      ),
                      Text(
                        '₹${widget.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryDefault,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: ${widget.bookingId.substring(widget.bookingId.length - 6).toUpperCase()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.brown300,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment Method Selection
            Text(
              'Select Payment Method',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.brown500,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_paymentMethods
                .map(
                  (method) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == method['value']
                            ? AppTheme.primaryDefault.withOpacity(0.1)
                            : AppTheme.sand40,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedPaymentMethod == method['value']
                              ? AppTheme.primaryDefault
                              : AppTheme.beige10,
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: method['value']!,
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                            _errorMessage = null;
                          });
                        },
                        title: Row(
                          children: [
                            // Icon(
                            //   IconData(
                            //     int.parse(method['icon']!.codePoint.toString()),
                            //   ),
                            //   color: _selectedPaymentMethod == method['value']
                            //       ? AppTheme.primaryDefault
                            //       : AppTheme.brown400,
                            //   size: 24,
                            // ),
                            Icon(
                              method['icon'] as IconData,
                              color: _selectedPaymentMethod == method['value']
                                  ? AppTheme.primaryDefault
                                  : AppTheme.brown400,
                              size: 24,
                            ),

                            const SizedBox(width: 12),
                            Text(
                              method['label']!,
                              style: TextStyle(
                                color: _selectedPaymentMethod == method['value']
                                    ? AppTheme.primaryDefault
                                    : AppTheme.brown500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        activeColor: AppTheme.primaryDefault,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                )
                .toList()),

            const SizedBox(height: 32),

            // Card Details (if card is selected)
            if (_selectedPaymentMethod == 'card') ...[
              Text(
                'Card Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.brown500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  labelStyle: TextStyle(color: AppTheme.brown300),
                  hintText: '1234 5678 9012 3456',
                  hintStyle: TextStyle(color: AppTheme.brown200),
                  filled: true,
                  fillColor: AppTheme.sand50,
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
                ),
                style: TextStyle(color: AppTheme.brown500),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        labelStyle: TextStyle(color: AppTheme.brown300),
                        hintText: '12/25',
                        hintStyle: TextStyle(color: AppTheme.brown200),
                        filled: true,
                        fillColor: AppTheme.sand50,
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
                          borderSide: BorderSide(
                            color: AppTheme.primaryDefault,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: AppTheme.brown400,
                        ),
                      ),
                      style: TextStyle(color: AppTheme.brown500),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        labelStyle: TextStyle(color: AppTheme.brown300),
                        hintText: '123',
                        hintStyle: TextStyle(color: AppTheme.brown200),
                        filled: true,
                        fillColor: AppTheme.sand50,
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
                          borderSide: BorderSide(
                            color: AppTheme.primaryDefault,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.security,
                          color: AppTheme.brown400,
                        ),
                      ),
                      style: TextStyle(color: AppTheme.brown500),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cardholderNameController,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  labelStyle: TextStyle(color: AppTheme.brown300),
                  hintText: 'John Doe',
                  hintStyle: TextStyle(color: AppTheme.brown200),
                  filled: true,
                  fillColor: AppTheme.sand50,
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
                ),
                style: TextStyle(color: AppTheme.brown500),
              ),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppTheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppTheme.error, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDefault,
                  foregroundColor: AppTheme.beige4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                    : Text(
                        'Pay ₹${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
