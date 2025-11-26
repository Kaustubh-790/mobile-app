import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'my_profile.dart';
import 'contact_us.dart';
import '../about/about_us.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.sand50, // Specifically mentioned Sand 50
      appBar: AppBar(
        backgroundColor: AppTheme.sand50,
        title: Text(
          'SETTINGS',
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Account Section
            _buildSectionHeader(context, 'ACCOUNT'),
            _buildSettingsGroup(
              context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.person_outline,
                  title: 'Personal Details',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.payment_outlined,
                  title: 'Payment Methods',
                  onTap: () {
                    // Navigate to payment methods
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'Address Book',
                  onTap: () {
                    // Navigate to address book
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  onTap: () {
                    // Navigate to notifications
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Support Section
            _buildSectionHeader(context, 'SUPPORT'),
            _buildSettingsGroup(
              context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {
                    // Navigate to help center
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.headset_mic_outlined,
                  title: 'Contact Us',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactUsScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.feedback_outlined,
                  title: 'Leave Feedback',
                  onTap: () {
                    // Navigate to feedback
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Info Section
            _buildSectionHeader(context, 'APP INFORMATION'),
            _buildSettingsGroup(
              context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.gavel_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    // Navigate to terms
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    // Navigate to privacy
                  },
                ),
                _buildDivider(),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About this App',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Logout Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isAuthenticated) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.sand40,
                            title: Text(
                              'Logout',
                              style: theme.textTheme.titleLarge,
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: theme.textTheme.bodyMedium,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: AppTheme.brown300),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDefault,
                                  foregroundColor: AppTheme.beige4,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', 
                              (route) => false,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDefault,
                        foregroundColor: AppTheme.beige4,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Logout',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.beige4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.brown300,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.beige4, // Using lighter beige for card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.brown500, size: 22),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.brown500,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.brown200, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.beige10,
      indent: 20,
      endIndent: 20,
    );
  }
}
