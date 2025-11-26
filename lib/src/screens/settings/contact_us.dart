import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/api_client.dart';
import '../../theme/app_theme.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedService = '';
  List<Map<String, dynamic>> _services = [];
  bool _isSubmitting = false;
  bool _isLoadingServices = true;
  int _currentStep = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _successAnimationController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pageController = PageController();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _animationController.dispose();
    _successAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final response = await ApiClient.dio.get('/services');
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> apiServices =
            List<Map<String, dynamic>>.from(response.data);

        bool hasOther = apiServices.any(
          (service) =>
              service['title']?.toLowerCase() == 'other' ||
              service['code']?.toLowerCase() == 'other',
        );

        if (!hasOther) {
          apiServices.add({'title': 'Other', 'code': 'other'});
        }

        setState(() {
          _services = apiServices;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      print('Error loading services: $e');
      setState(() {
        _services = [
          {'title': 'Labour', 'code': 'labour'},
          {'title': 'Mason', 'code': 'mason'},
          {'title': 'Tile/Marble Worker', 'code': 'tile_marble'},
          {'title': 'Other', 'code': 'other'},
        ];
        _isLoadingServices = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'service': _selectedService,
      };

      final response = await ApiClient.dio.post(
        '/contact/contact-us',
        data: formData,
      );

      if (response.statusCode == 200) {
        _successAnimationController.forward();

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _resetForm();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    response.data['message'] ?? 'Message sent successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      String errorMsg = 'Something went wrong. Please try again.';

      if (e.toString().contains('DioException')) {
        errorMsg = 'Network error. Please check your connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedService = '';
      _currentStep = 0;
    });
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _subjectController.clear();
    _messageController.clear();
    _successAnimationController.reset();
    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        backgroundColor: AppTheme.beigeDefault,
        title: Text(
          'CONTACT US',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brown500),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Progress Indicator
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Ready to bring your ideas to life? We\'d love to hear from you.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: AppTheme.brown400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < 2 ? 8 : 0,
                          ),
                          height: 4,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppTheme.primaryDefault
                                : AppTheme.beige10,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.brown300,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme),
                ],
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppTheme.brown300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Previous',
                            style: TextStyle(color: AppTheme.brown500),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentStep > 0 ? 1 : 1,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDefault,
                          foregroundColor: AppTheme.beige4,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(AppTheme.beige4),
                                ),
                              )
                            : Text(
                                _currentStep == 2 ? 'Send Message' : 'Next',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.brown500,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name *',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address *',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.brown500,
            ),
          ),
          const SizedBox(height: 32),
          _buildServiceDropdown(theme),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _subjectController,
            label: 'Subject *',
            icon: Icons.subject_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a subject';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Message',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.brown500,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _messageController,
            label: 'Message *',
            icon: Icons.message_outlined,
            maxLines: 8,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your message';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          // Contact Information Card
          Container(
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContactItem(
                    Icons.phone_outlined,
                    'Call Us',
                    '+91 XXXXXXXXXX',
                    'Mon-Fri 9AM-6PM IST',
                    AppTheme.primaryDefault,
                    theme,
                  ),
                  const SizedBox(height: 20),
                  _buildContactItem(
                    Icons.email_outlined,
                    'Email Us',
                    'hello@company.com',
                    'We\'ll respond within 24hrs',
                    AppTheme.primaryDefault,
                    theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppTheme.brown400,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          enabled: !_isSubmitting,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.brown500,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(20),
            filled: true,
            fillColor: AppTheme.sand50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppTheme.beige10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppTheme.beige10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: AppTheme.primaryDefault),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work_outline,
              size: 18,
              color: AppTheme.brown400,
            ),
            const SizedBox(width: 8),
            Text(
              'Service',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.sand50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.beige10,
            ),
          ),
          child: _isLoadingServices
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDefault),
                      ),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedService.isEmpty ? null : _selectedService,
                    hint: Text(
                      'Select a service',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.brown300,
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: AppTheme.sand50,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.brown500,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.brown400,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(
                          'Select a service',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.brown300,
                          ),
                        ),
                      ),
                      ..._services.map<DropdownMenuItem<String>>((service) {
                        return DropdownMenuItem<String>(
                          value: service['code'] ?? service['title'],
                          child: Text(service['title']),
                        );
                      }).toList(),
                    ],
                    onChanged: _isSubmitting
                        ? null
                        : (String? newValue) {
                            setState(() {
                              _selectedService = newValue ?? '';
                            });
                          },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String detail,
    String subDetail,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brown500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.brown400,
                ),
              ),
              Text(
                subDetail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.brown300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
