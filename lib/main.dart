import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/services_provider.dart';
import 'src/providers/cart_provider.dart';
import 'src/providers/booking_provider.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/home/home_screen.dart';
import 'src/screens/service/service_detail_screen.dart';
import 'src/screens/settings/contact_us.dart';
import 'src/screens/settings/my_profile.dart';
import 'src/screens/settings/settings_screen.dart';
import 'src/config/firebase_config.dart';
import 'src/screens/checkout/checkout_screen.dart';

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
        title: 'User App',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/service-detail': (context) =>
              const ServiceDetailScreen(serviceSlug: ''),
          '/contact-us': (context) => const ContactUsScreen(),
          '/my-profile': (context) => const MyProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/checkout': (context) => const CheckoutScreen(),
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

        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
