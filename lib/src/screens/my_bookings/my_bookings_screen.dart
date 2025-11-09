import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'widgets/booking_card.dart';
import '../search/search_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Fetch bookings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookings();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      try {
        await context.read<BookingProvider>().fetchMyBookings();
        _animationController.forward();
      } catch (e) {
        print('MyBookingsScreen: Error fetching bookings: $e');

        // If it's an authentication error, try to refresh the auth state
        if (e.toString().contains('not authenticated') ||
            e.toString().contains('token is missing') ||
            e.toString().contains('profile not fully loaded')) {
          print(
            'MyBookingsScreen: Authentication issue detected, refreshing auth state...',
          );

          // Wait a bit and try again
          await Future.delayed(const Duration(seconds: 2));
          try {
            await context.read<BookingProvider>().fetchMyBookings();
            _animationController.forward();
          } catch (retryError) {
            print('MyBookingsScreen: Retry also failed: $retryError');
          }
        }
      }
    } else {
      print('MyBookingsScreen: No current user available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const LoadingWidget();
          }

          if (bookingProvider.error != null) {
            return _buildErrorWidget(bookingProvider.error!, isDark);
          }

          if (bookingProvider.myBookings.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: _fetchBookings,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header with refresh button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Bookings',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _fetchBookings,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 0,
                        bottom: 100, // Extra padding for bottom nav
                      ),
                      itemCount: bookingProvider.myBookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookingProvider.myBookings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BookingCard(
                            booking: booking,
                            onRefresh: _fetchBookings,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading bookings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchBookings,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookings available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse services and make a booking to see them here!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore),
              label: const Text('Browse Services'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
