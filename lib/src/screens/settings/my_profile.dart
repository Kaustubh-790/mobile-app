import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../api/auth_service.dart';
import '../auth/login_screen.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        backgroundColor: AppTheme.beigeDefault,
        title: Text(
          'MY PROFILE',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.brown500),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
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
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDefault),
                    ),
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
              color: AppTheme.primaryDefault,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.sand50,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.beige10),
            ),
            child: Icon(
              Icons.person_outline,
              size: 64,
              color: AppTheme.brown300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sign in to view your profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.brown500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Login or create an account to access your profile, manage your information, and track your bookings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.brown300,
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
                backgroundColor: AppTheme.primaryDefault,
                foregroundColor: AppTheme.beige4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.beige200, width: 2),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.clay,
              child: Text(
                _userProfile!.name?.substring(0, 1).toUpperCase() ?? 'U',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.brown500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile!.name ?? 'No Name',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brown500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile!.email ?? 'No Email',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.brown300,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDefault.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryDefault.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    _userProfile!.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDefault,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.brown500,
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileField(
            theme,
            icon: Icons.person_outline,
            label: 'Full Name',
            value: _userProfile!.name ?? 'Not provided',
          ),
          _buildDivider(),
          _buildProfileField(
            theme,
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: _userProfile!.email ?? 'Not provided',
          ),
          _buildDivider(),
          _buildProfileField(
            theme,
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: _userProfile!.phone ?? 'Not provided',
          ),
          _buildDivider(),
          _buildProfileField(
            theme,
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _buildAddressText(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: AppTheme.beige10, height: 1),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.beige10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.brown400, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.brown300,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.brown500,
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
