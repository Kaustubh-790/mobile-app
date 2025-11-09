import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../api/auth_service.dart';
import '../auth/login_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isLoading = false;
  User? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // If not authenticated, don't load profile
    if (!authProvider.isAuthenticated) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get profile from backend first
      try {
        final user = await AuthService().getProfile();
        setState(() {
          _userProfile = user;
          _isLoading = false;
        });
        return;
      } catch (e) {
        print('Backend profile fetch failed: $e');
        // Continue to fallback options
      }

      // Fallback 1: Try to refresh user data from provider
      try {
        await authProvider.refreshUserData();
        final currentUser = authProvider.currentUser;
        if (currentUser != null) {
          setState(() {
            _userProfile = currentUser;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Provider refresh failed: $e');
        // Continue to next fallback
      }

      // Fallback 2: Use current user from provider
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        setState(() {
          _userProfile = currentUser;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // If not authenticated, show login prompt
            if (!authProvider.isAuthenticated) {
              return _buildLoginPrompt(theme);
            }

            // If loading, show loading indicator
            if (_isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading profile...'),
                  ],
                ),
              );
            }

            // If no user profile, show login prompt
            if (_userProfile == null) {
              return _buildLoginPrompt(theme);
            }

            // Show profile content
            return RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Profile',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadUserProfile,
                            tooltip: 'Refresh Profile',
                          ),
                        ],
                      ),
                    ),
                    _buildProfileHeader(theme),
                    const SizedBox(height: 24),
                    _buildProfileDetails(theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sign in to view your profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Login or create an account to access your profile, manage your information, and track your bookings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Login / Register'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userProfile!.name ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile!.email ?? 'No Email',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userProfile!.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetails(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildProfileField(
              theme,
              icon: Icons.person,
              label: 'Full Name',
              value: _userProfile!.name ?? 'Not provided',
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              theme,
              icon: Icons.email,
              label: 'Email Address',
              value: _userProfile!.email ?? 'Not provided',
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              theme,
              icon: Icons.phone,
              label: 'Phone Number',
              value: _userProfile!.phone ?? 'Not provided',
            ),
            const SizedBox(height: 16),
            _buildProfileField(
              theme,
              icon: Icons.location_on,
              label: 'Address',
              value: _buildAddressText(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildAddressText() {
    final address = _userProfile!.address;
    final city = _userProfile!.city;
    final state = _userProfile!.state;
    final zipCode = _userProfile!.zipCode;
    final country = _userProfile!.country;

    if (address == null &&
        city == null &&
        state == null &&
        zipCode == null &&
        country == null) {
      return 'Not provided';
    }

    final parts = <String>[];
    if (address != null && address.isNotEmpty) parts.add(address);
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);
    if (zipCode != null && zipCode.isNotEmpty) parts.add(zipCode);
    if (country != null && country.isNotEmpty) parts.add(country);

    return parts.join(', ');
  }
}
