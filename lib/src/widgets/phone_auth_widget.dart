import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/phone_auth_service.dart';
import '../screens/auth/onboarding_screen.dart';
import '../theme/app_theme.dart';

class PhoneAuthWidget extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool isSignUp;

  const PhoneAuthWidget({super.key, this.onSuccess, this.isSignUp = false});

  @override
  State<PhoneAuthWidget> createState() => _PhoneAuthWidgetState();
}

class _PhoneAuthWidgetState extends State<PhoneAuthWidget> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  final PhoneAuthService _phoneAuthService = PhoneAuthService();

  bool _isLoading = false;
  bool _showOtpInput = false;
  String _errorMessage = '';
  String _phoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final phone = _phoneController.text.trim();
      final result = await _phoneAuthService.sendOTP(phone);

      if (result['success'] == true) {
        setState(() {
          _showOtpInput = true;
          _phoneNumber = result['phoneNumber'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to $phone'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final otp = _otpController.text.trim();
      final result = await _phoneAuthService.verifyOTP(otp);

      if (result['success'] == true) {
        final actionRequired = result['actionRequired'] ?? 'PROCEED';

        if (actionRequired == 'ONBOARDING') {
          // Navigate to onboarding screen
          final user = result['user'];
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(user: user),
            ),
          );
        } else {
          // Navigate to home screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone authentication successful!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSuccess?.call();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_phoneNumber.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _phoneAuthService.resendOTP(_phoneNumber);

      if (result['success'] == true) {
        setState(() {
          _otpController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goBackToPhoneInput() {
    setState(() {
      _showOtpInput = false;
      _otpController.clear();
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_showOtpInput) ...[
            // Phone input section
            if (widget.isSignUp) ...[
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: AppTheme.brown500),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.brown400),
                  labelStyle: TextStyle(color: AppTheme.brown300),
                  hintStyle: TextStyle(color: AppTheme.brown200),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _phoneController,
              style: TextStyle(color: AppTheme.brown500),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.brown400),
                labelStyle: TextStyle(color: AppTheme.brown300),
                hintStyle: TextStyle(color: AppTheme.brown200),
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
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.trim().length != 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDefault,
                foregroundColor: AppTheme.beige4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.beige4),
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ] else ...[
            // OTP input section
            Text(
              'Enter the 6-digit OTP sent to $_phoneNumber',
              style: TextStyle(fontSize: 16, color: AppTheme.brown300),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _otpController,
              style: TextStyle(color: AppTheme.brown500),
              decoration: InputDecoration(
                labelText: 'OTP Code',
                hintText: 'Enter 6-digit OTP',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.brown400),
                labelStyle: TextStyle(color: AppTheme.brown300),
                hintStyle: TextStyle(color: AppTheme.brown200),
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                if (value == null || value.trim().length != 6) {
                  return 'Please enter a valid 6-digit OTP';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _goBackToPhoneInput,
                  child: Text(
                    'Change Phone Number',
                    style: TextStyle(color: AppTheme.primaryDefault),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isLoading ? null : _resendOTP,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(color: AppTheme.primaryDefault),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.error),
                    onPressed: () {
                      setState(() {
                        _errorMessage = '';
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
