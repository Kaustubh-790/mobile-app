import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? verificationToken; // For deep linking

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.verificationToken,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  final _tokenController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  String? _successMessage;
  
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set token if provided from deep link
    if (widget.verificationToken != null) {
      _tokenController.text = widget.verificationToken!;
      // Auto-verify if token is provided
      Future.delayed(const Duration(seconds: 1), () {
        _verifyEmail();
      });
    }

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Pulse animation for icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.repeat(reverse: true);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _error = 'Please enter the verification token';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
      _successMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.verifyEmail(token);

    if (result['success'] == true && mounted) {
      setState(() {
        _successMessage = 'Email verified successfully!';
        _isVerifying = false;
      });

      final actionRequired = result['action_required'] as String?;
      final requiresProfileCompletion = result['requiresProfileCompletion'] as bool? ?? false;
      final user = result['user'] as User?;

      print('EmailVerificationScreen: Verification successful');
      print('EmailVerificationScreen: actionRequired: $actionRequired');
      print('EmailVerificationScreen: requiresProfileCompletion: $requiresProfileCompletion');
      print('EmailVerificationScreen: user: ${user?.name}');
      print('EmailVerificationScreen: user.profileCompleted: ${user?.profileCompleted}');

      // Check if onboarding is required - check both the result flags and the user object directly
      final needsOnboarding = actionRequired == 'ONBOARDING' || 
                              requiresProfileCompletion || 
                              (user != null && !user.profileCompleted);

      print('EmailVerificationScreen: needsOnboarding: $needsOnboarding');

      if (needsOnboarding && user != null) {
        // Navigate to onboarding screen after a short delay
        print('EmailVerificationScreen: Navigating to onboarding screen');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/onboarding',
              arguments: user,
            );
          }
        });
      } else {
        // Navigate to home after a short delay
        print('EmailVerificationScreen: Navigating to home screen');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      }
    } else {
      // Check if user is actually authenticated (verification might have succeeded despite error)
      if (authProvider.isAuthenticated && mounted) {
        // Verification succeeded and user is logged in
        final user = authProvider.currentUser;
        final needsOnboarding = user != null && !user.profileCompleted;
        
        setState(() {
          _successMessage = 'Email verified successfully!';
          _isVerifying = false;
        });
        
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            if (needsOnboarding) {
              // Navigate to onboarding (user is guaranteed to not be null when isAuthenticated is true)
              Navigator.pushReplacementNamed(
                context,
                '/onboarding',
                arguments: user,
              );
            } else {
              // Navigate to home
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        });
      } else {
        // Check if error suggests verification succeeded but login failed
        final error = result['error'] as String? ?? authProvider.error ?? 'Email verification failed';
        if (error.contains('Verification completed') || 
            error.contains('try logging in') ||
            error.contains('Please login')) {
          // Verification succeeded, but auto-login failed - suggest manual login
          setState(() {
            _successMessage = 'Email verified! Please sign in to continue.';
            _isVerifying = false;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        } else {
          setState(() {
            _error = error;
            _isVerifying = false;
          });
        }
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _error = null;
      _successMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendVerificationEmail(widget.email);

    if (success && mounted) {
      setState(() {
        _successMessage = 'Verification email sent! Please check your inbox.';
        _isResending = false;
      });
    } else {
      setState(() {
        _error = authProvider.error ?? 'Failed to resend verification email';
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.beigeDefault,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Animated Email Icon
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDefault.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.email_outlined,
                              size: 60,
                              color: AppTheme.primaryDefault,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Verify Your Email',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'We\'ve sent a verification link to',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.brown300,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Email
                  Text(
                    widget.email,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDefault,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Please check your email and click the verification link, or enter the token below.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.brown300,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Token Input Field
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Verification Token',
                      hintText: 'Enter verification token from email',
                      prefixIcon: const Icon(Icons.vpn_key, color: AppTheme.brown400),
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
                    style: TextStyle(color: AppTheme.brown500),
                    enabled: !_isVerifying,
                  ),

                  const SizedBox(height: 24),

                  // Verify Button
                  ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDefault,
                      foregroundColor: AppTheme.beige4,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: _isVerifying
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
                            'Verify Email',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Resend Button
                  TextButton(
                    onPressed: _isResending ? null : _resendVerificationEmail,
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDefault),
                            ),
                          )
                        : const Text(
                            'Resend Verification Email',
                            style: TextStyle(
                              color: AppTheme.primaryDefault,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (_error != null)
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
                              _error!,
                              style: TextStyle(color: AppTheme.error),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: AppTheme.error),
                            onPressed: () {
                              setState(() {
                                _error = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  // Success Message
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already verified? ',
                        style: TextStyle(
                          color: AppTheme.brown300,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppTheme.primaryDefault,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
