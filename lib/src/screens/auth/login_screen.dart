import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/auth_service.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/phone_auth_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Navigate to home screen on success
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handlePhoneAuthSuccess() {
    // Navigate to home screen on successful phone authentication
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              tabs: const [
                Tab(text: 'Email & Password'),
                Tab(text: 'Phone Number'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Email & Password Tab
                _buildEmailPasswordTab(),

                // Phone Authentication Tab
                _buildPhoneAuthTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Logo/Title
            const Icon(Icons.account_circle, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to your account',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
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
            const SizedBox(height: 20),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Google Sign-In Button
            const GoogleSignInButton(),
            const SizedBox(height: 24),

            // Test Google Sign-In Button (for debugging)
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  print('Testing Google Sign-In directly...');
                  final authProvider = context.read<AuthProvider>();
                  final success = await authProvider.loginWithGoogle();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Test successful!'
                              : 'Test failed: ${authProvider.error}',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Google Sign-In'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Google Login Endpoint Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  print('Testing Google login endpoint...');
                  final authService = AuthService();
                  final result = await authService.testGoogleLoginEndpoint();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['status'] == 'accessible'
                              ? 'Endpoint accessible: ${result['statusCode']}'
                              : 'Endpoint error: ${result['error']}',
                        ),
                        backgroundColor: result['status'] == 'accessible'
                            ? Colors.green
                            : Colors.red,
                      ),
                    );

                    // Show detailed results in console
                    print('Google login endpoint test results: $result');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Endpoint test error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.api),
              label: const Text('Test Google Login Endpoint'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Google Login Endpoint POST Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  print('Testing Google login endpoint with POST...');
                  final authService = AuthService();
                  final result = await authService
                      .testGoogleLoginEndpointPost();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['status'] == 'accessible'
                              ? 'POST endpoint accessible: ${result['statusCode']}'
                              : 'POST endpoint error: ${result['error']}',
                        ),
                        backgroundColor: result['status'] == 'accessible'
                            ? Colors.green
                            : Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );

                    // Show detailed results in console
                    print('Google login endpoint POST test results: $result');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('POST endpoint test error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.post_add),
              label: const Text('Test Google Login Endpoint POST'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Google Login Route Configuration Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  print('Testing Google login route configuration...');
                  final authService = AuthService();
                  final result = await authService.testGoogleLoginRoute();

                  if (mounted) {
                    String message;
                    Color backgroundColor;

                    switch (result['status']) {
                      case 'route_exists_api':
                        message = 'API route exists and working';
                        backgroundColor = Colors.green;
                        break;
                      case 'route_exists_but_frontend':
                        message = 'Route exists but returns HTML (not API)';
                        backgroundColor = Colors.orange;
                        break;
                      case 'route_exists_post_only':
                        message = 'POST-only route exists';
                        backgroundColor = Colors.green;
                        break;
                      case 'route_not_found':
                        message = 'Route not found: ${result['error']}';
                        backgroundColor = Colors.red;
                        break;
                      default:
                        message = 'Route test result: ${result['status']}';
                        backgroundColor = Colors.blue;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: backgroundColor,
                        duration: const Duration(seconds: 6),
                      ),
                    );

                    // Show detailed results in console
                    print(
                      'Google login route configuration test results: $result',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Route configuration test error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.route),
              label: const Text('Test Route Configuration'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Or Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // Connection Test Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final authService = AuthService();

                  // Test basic connection first
                  final isConnected = await authService.testConnection();

                  if (mounted) {
                    if (isConnected) {
                      // If basic connection works, test auth endpoints
                      final authResults = await authService.testAuthEndpoints();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Connection successful! Auth endpoints: ${authResults['login_endpoint']?['status'] ?? 'unknown'}',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 6),
                        ),
                      );

                      // Show detailed results in console
                      print('Auth endpoints test results: $authResults');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Connection failed. Check if your backend server is running on port 3000.',
                          ),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connection test error: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.wifi_find),
              label: const Text('Test Connection'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Backend URLs Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  print('Testing different backend URLs...');
                  final authService = AuthService();
                  final result = await authService.testBackendUrls();

                  if (mounted) {
                    // Show summary in snackbar
                    final workingUrls = <String>[];
                    final htmlUrls = <String>[];
                    final errorUrls = <String>[];

                    result.forEach((key, value) {
                      if (value is Map<String, dynamic>) {
                        if (value['status'] == 'accessible' &&
                            value['isHtml'] == false) {
                          workingUrls.add(value['url']);
                        } else if (value['status'] == 'accessible' &&
                            value['isHtml'] == true) {
                          htmlUrls.add(value['url']);
                        } else if (value['status'] == 'error') {
                          errorUrls.add(value['url']);
                        }
                      }
                    });

                    String message;
                    Color backgroundColor;

                    if (workingUrls.isNotEmpty) {
                      message = 'Found working API at: ${workingUrls.first}';
                      backgroundColor = Colors.green;
                    } else if (htmlUrls.isNotEmpty) {
                      message = 'All URLs return HTML (frontend routes)';
                      backgroundColor = Colors.orange;
                    } else {
                      message = 'All URLs failed';
                      backgroundColor = Colors.red;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: backgroundColor,
                        duration: const Duration(seconds: 6),
                      ),
                    );

                    // Show detailed results in console
                    print('Backend URL test results: $result');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test failed: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                  print('Backend URL test failed: $e');
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Test Backend URLs'),
            ),
            const SizedBox(height: 24),

            // Test Server Status Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  print('Testing server status...');
                  final authService = AuthService();
                  final result = await authService.testServerStatus();

                  if (mounted) {
                    // Show summary in snackbar
                    final accessibleEndpoints = <String>[];
                    final htmlEndpoints = <String>[];
                    final errorEndpoints = <String>[];

                    result.forEach((key, value) {
                      if (value is Map<String, dynamic>) {
                        if (value['status'] == 'accessible') {
                          if (value['isHtml'] == true) {
                            htmlEndpoints.add(value['url']);
                          } else {
                            accessibleEndpoints.add(value['url']);
                          }
                        } else if (value['status'] == 'error') {
                          errorEndpoints.add(value['url']);
                        }
                      }
                    });

                    String message;
                    Color backgroundColor;

                    if (accessibleEndpoints.isNotEmpty) {
                      message =
                          'Found ${accessibleEndpoints.length} working endpoints';
                      backgroundColor = Colors.green;
                    } else if (htmlEndpoints.isNotEmpty) {
                      message = 'Server running but all endpoints return HTML';
                      backgroundColor = Colors.orange;
                    } else {
                      message = 'Server not accessible';
                      backgroundColor = Colors.red;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: backgroundColor,
                        duration: const Duration(seconds: 6),
                      ),
                    );

                    // Show detailed results in console
                    print('Server status test results: $result');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test failed: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                  print('Server status test failed: $e');
                }
              },
              icon: const Icon(Icons.dns),
              label: const Text('Test Server Status'),
            ),
            const SizedBox(height: 16),

            // Test Google Login with Postman Data Button
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  print('Testing Google login with Postman data...');
                  final authService = AuthService();
                  final result = await authService
                      .testGoogleLoginWithPostmanData();

                  if (mounted) {
                    String message;
                    Color backgroundColor;

                    if (result['status'] == 'success') {
                      message =
                          '✅ ${result['message']} (${result['statusCode']})';
                      backgroundColor = Colors.green;
                    } else {
                      message = '❌ ${result['message']}';
                      backgroundColor = Colors.red;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: backgroundColor,
                        duration: const Duration(seconds: 6),
                      ),
                    );

                    // Show detailed results in console
                    print('Postman data test results: $result');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test failed: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                  print('Postman data test failed: $e');
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Test with Postman Data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: authProvider.isLoading
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
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Error Display
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.error != null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red.shade600),
                          onPressed: () => authProvider.clearError(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),

            // Register Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneAuthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Logo/Title for Phone Auth
          const Icon(Icons.phone_android, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Phone Authentication',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in with your phone number',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Phone Authentication Widget
          PhoneAuthWidget(isSignUp: false, onSuccess: _handlePhoneAuthSuccess),

          const SizedBox(height: 32),

          // Or Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),

          // Google Sign-In Button for Phone Tab
          const GoogleSignInButton(),
          const SizedBox(height: 24),

          // Register Link for Phone Tab
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.grey),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
