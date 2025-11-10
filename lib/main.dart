import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/services_provider.dart';
import 'src/providers/cart_provider.dart';
import 'src/providers/booking_provider.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/auth/register_screen.dart';
import 'src/screens/auth/email_verification_screen.dart';
import 'src/screens/service/service_detail_screen.dart';
import 'src/screens/settings/contact_us.dart';
import 'src/screens/settings/my_profile.dart';
import 'src/screens/settings/settings_screen.dart';
import 'src/config/firebase_config.dart';
import 'src/screens/checkout/checkout_screen.dart';
import 'src/screens/my_bookings/my_bookings_screen.dart';
import 'src/screens/payment/payment_screen.dart';
import 'src/screens/about/about_us.dart';
import 'src/theme/app_theme.dart';
import 'src/widgets/animated_splash_screen.dart';
import 'src/widgets/main_wrapper.dart';
import 'src/screens/search/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseConfig.initialize();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue without Firebase for now
  }

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'Service App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AnimatedSplashScreen(
          child: AuthWrapper(),
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainWrapper(),
          '/service-detail': (context) =>
              const ServiceDetailScreen(serviceSlug: ''),
          '/contact-us': (context) => const ContactUsScreen(),
          '/my-profile': (context) => const MyProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/my-bookings': (context) => const MyBookingsScreen(),
          '/payment': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return PaymentScreen(
              bookingId: args['bookingId'],
              cartId: args['cartId'],
              amount: args['amount'],
              fromBookings: args['fromBookings'] ?? false,
            );
          },
          '/about-us': (context) => const AboutUsScreen(),
          '/search': (context) => const SearchScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Always show home screen, login button will be shown if not authenticated
        return const MainWrapper();
      },
    );
  }
}
