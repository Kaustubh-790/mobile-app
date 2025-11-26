import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'widgets/booking_card.dart';
import '../search/search_screen.dart';
import '../../theme/app_theme.dart';

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
    
    return Scaffold(
      backgroundColor: AppTheme.beigeDefault,
      appBar: AppBar(
        backgroundColor: AppTheme.beigeDefault,
        title: Text(
          'MY BOOKINGS',
          style: theme.textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.brown500),
            onPressed: _fetchBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const LoadingWidget();
          }

          if (bookingProvider.error != null) {
            return _buildErrorWidget(bookingProvider.error!);
          }

          if (bookingProvider.myBookings.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _fetchBookings,
            color: AppTheme.primaryDefault,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 100, // Extra padding for bottom nav
                ),
                itemCount: bookingProvider.myBookings.length,
                itemBuilder: (context, index) {
                  final booking = bookingProvider.myBookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: BookingCard(
                      booking: booking,
                      onRefresh: _fetchBookings,
                    ),
                  );
                },
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading bookings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.brown300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDefault,
                foregroundColor: AppTheme.beige4,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.sand50,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.beige10),
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 64,
                color: AppTheme.brown200,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookings available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.brown500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse services and make a booking to see them here!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.brown300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                backgroundColor: AppTheme.primaryDefault,
                foregroundColor: AppTheme.beige4,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
