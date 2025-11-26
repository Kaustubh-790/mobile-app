import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../models/user.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final User user;

  const OnboardingScreen({super.key, required this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Determine if user is email user (has email but no phone)
  bool get _isEmailUser =>
      widget.user.email != null &&
      widget.user.email!.isNotEmpty &&
      (widget.user.phone == null || widget.user.phone!.isEmpty);

  @override
  void initState() {
    super.initState();
    // Pre-fill name if available
    if (widget.user.name != null && widget.user.name!.startsWith('User-')) {
      _nameController.text = '';
    } else {
      _nameController.text = widget.user.name ?? '';
    }
    _emailController.text = widget.user.email ?? '';
    _phoneController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clean phone number: remove all non-numeric characters
      final phoneText = _phoneController.text.trim();
      final cleanedPhone = phoneText.replaceAll(RegExp(r'[^0-9]'), '');

      // Prepare request data
      final requestData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
      };

      // Always include phone if it's an email user (required field)
      // For email users, phone should always be sent if provided
      if (_isEmailUser && cleanedPhone.isNotEmpty) {
        requestData['phone'] = cleanedPhone;
      } else if (!_isEmailUser && cleanedPhone.isNotEmpty) {
        // For phone users, also send if they're updating it
        requestData['phone'] = cleanedPhone;
      } else if (_isEmailUser && cleanedPhone.isEmpty) {
        // Email user must provide phone - this should be caught by validation
        throw Exception('Phone number is required');
      }

      print('OnboardingScreen: Submitting profile data:');
      print('OnboardingScreen: - name: ${requestData['name']}');
      print('OnboardingScreen: - email: ${requestData['email']}');
      print('OnboardingScreen: - phone: ${requestData['phone'] ?? 'not sent'}');
      print('OnboardingScreen: - address: ${requestData['address']}');
      print('OnboardingScreen: - isEmailUser: $_isEmailUser');

      final response = await ApiClient.dio.put(
        '/auth/profile-completion/${widget.user.firebaseUid}',
        data: requestData,
        options: Options(headers: {'x-platform': 'mobile'}),
      );

      print(
        'OnboardingScreen: Profile update response status: ${response.statusCode}',
      );
      print('OnboardingScreen: Profile update response data: ${response.data}');

      if (response.statusCode == 200) {
        // Check if phone was updated in response
        if (response.data['user'] != null) {
          final updatedUser = response.data['user'];
          print(
            'OnboardingScreen: Updated user phone: ${updatedUser['phone'] ?? 'not in response'}',
          );

          // If phone was sent but not in response, log warning
          if (requestData.containsKey('phone') &&
              (updatedUser['phone'] == null ||
                  updatedUser['phone'].toString().isEmpty)) {
            print(
              'OnboardingScreen: WARNING - Phone was sent but not updated in backend response',
            );
            print(
              'OnboardingScreen: This indicates the backend updateUserProfileCompletion endpoint needs to be updated to accept phone parameter',
            );
          }
        }

        // Refresh user profile from backend to get latest data
        try {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          print(
            'OnboardingScreen: Refreshing user profile after onboarding...',
          );
          await authProvider.refreshUserData();
          print('OnboardingScreen: User profile refreshed successfully');
          if (authProvider.currentUser != null) {
            print(
              'OnboardingScreen: Refreshed user phone: ${authProvider.currentUser!.phone ?? 'not set'}',
            );
          }
        } catch (e) {
          print('OnboardingScreen: Error refreshing user profile: $e');
          // Continue anyway - profile update was successful
        }

        // Profile updated successfully, navigate to home
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('OnboardingScreen: Error updating profile: $e');
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          'COMPLETE PROFILE',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        automaticallyImplyLeading: false, // Prevent back navigation
        backgroundColor: AppTheme.beigeDefault,
        foregroundColor: AppTheme.brown500,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDefault.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 48,
                        color: AppTheme.primaryDefault,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome! Let\'s get to know you better',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.brown500,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide some basic information to complete your profile',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.brown300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Phone number field (editable for email users, read-only for phone users)
              if (!_isEmailUser)
                // Display phone as read-only for phone users
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.sand50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.beige10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: AppTheme.brown400),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.brown300,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.user.phone ?? 'Not available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brown500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                // Editable phone field for email users
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(Icons.phone, color: AppTheme.brown400),
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
                    filled: true,
                    fillColor: AppTheme.sand50,
                    labelStyle: TextStyle(color: AppTheme.brown300),
                    hintStyle: TextStyle(color: AppTheme.brown200),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Basic phone validation (at least 10 digits)
                    final phoneRegex = RegExp(r'^[0-9]{10,}$');
                    final cleanedPhone = value.trim().replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    if (!phoneRegex.hasMatch(cleanedPhone)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: AppTheme.brown500),
                ),

              if (!_isEmailUser) const SizedBox(height: 24),
              if (_isEmailUser) const SizedBox(height: 20),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person, color: AppTheme.brown400),
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
                  filled: true,
                  fillColor: AppTheme.sand50,
                  labelStyle: TextStyle(color: AppTheme.brown300),
                  hintStyle: TextStyle(color: AppTheme.brown200),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                style: TextStyle(color: AppTheme.brown500),
              ),

              const SizedBox(height: 20),

              // Email field (read-only for email users, optional for phone users)
              if (_isEmailUser)
                // Display email as read-only for email users
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.sand50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.beige10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: AppTheme.brown400),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.brown300,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.user.email ?? 'Not available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brown500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                // Editable email field for phone users (optional)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email (optional)',
                    prefixIcon: Icon(Icons.email, color: AppTheme.brown400),
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
                    filled: true,
                    fillColor: AppTheme.sand50,
                    labelStyle: TextStyle(color: AppTheme.brown300),
                    hintStyle: TextStyle(color: AppTheme.brown200),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      // Basic email validation
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: AppTheme.brown500),
                ),

              const SizedBox(height: 20),

              // Address field (required)
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Enter your address',
                  prefixIcon: Icon(Icons.location_on, color: AppTheme.brown400),
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
                  filled: true,
                  fillColor: AppTheme.sand50,
                  labelStyle: TextStyle(color: AppTheme.brown300),
                  hintStyle: TextStyle(color: AppTheme.brown200),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  if (value.trim().length < 10) {
                    return 'Address must be at least 10 characters';
                  }
                  return null;
                },
                style: TextStyle(color: AppTheme.brown500),
              ),

              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDefault,
                  foregroundColor: AppTheme.beige4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.beige4,
                          ),
                        ),
                      )
                    : const Text(
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Info text
              Text(
                'You can update this information later in your profile settings',
                style: TextStyle(color: AppTheme.brown300, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
