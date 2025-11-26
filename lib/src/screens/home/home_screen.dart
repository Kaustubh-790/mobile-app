import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import '../../widgets/popular_services_section.dart';
import '../cart/cart_screen.dart';
import '../settings/contact_us.dart';
import '../settings/my_profile.dart';
import '../settings/settings_screen.dart';
import '../my_bookings/my_bookings_screen.dart';
import '../search/search_screen.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isAuthenticated = authProvider.isAuthenticated;

            return RefreshIndicator(
              onRefresh: () async {
                final servicesProvider = context.read<ServicesProvider>();
                await servicesProvider.refreshPopularServices();
              },
              color: AppTheme.primaryDefault,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppTheme.beigeDefault,
                      ),
                      child: isAuthenticated
                          ? _buildAuthenticatedHeader(context, authProvider, theme)
                          : _buildUnauthenticatedHeader(context, theme),
                    ),

                    // Popular Services Section - Show for everyone
                    const PopularServicesSection(),
                    const SizedBox(height: 32),

                    // Quick Actions Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAuthenticated ? 'Quick Actions' : 'Explore',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brown500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  context,
                                  icon: Icons.search,
                                  title: 'Search Services',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SearchScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildQuickActionCard(
                                  context,
                                  icon: Icons.contact_support_outlined,
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
                              ),
                            ],
                          ),
                          if (isAuthenticated) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickActionCard(
                                    context,
                                    icon: Icons.bookmark_border,
                                    title: 'My Bookings',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const MyBookingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildQuickActionCard(
                                    context,
                                    icon: Icons.shopping_cart_outlined,
                                    title: 'Shopping Cart',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CartScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickActionCard(
                                    context,
                                    icon: Icons.person_outline,
                                    title: 'Profile',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const MyProfileScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildQuickActionCard(
                                    context,
                                    icon: Icons.settings_outlined,
                                    title: 'Settings',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SettingsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthenticatedHeader(
    BuildContext context,
    AuthProvider authProvider,
    ThemeData theme,
  ) {
    final user = authProvider.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brown300, width: 1),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.clay,
                child: Text(
                  user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: AppTheme.brown500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.brown300,
                    ),
                  ),
                  Text(
                    user?.name ?? 'User',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppTheme.brown500, size: 28),
              onPressed: () {
                // Notification logic
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Find the perfect service\nfor your needs',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.brown500,
            fontWeight: FontWeight.w300,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.sand40,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.beige10),
              ),
              child: const Icon(
                Icons.home_outlined,
                size: 28,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.brown300,
                    ),
                  ),
                  Text(
                    'Service App',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brown500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Discover and book\nservices with ease',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.brown500,
            fontWeight: FontWeight.w300,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sand40,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.beige10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: AppTheme.brown400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brown500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
