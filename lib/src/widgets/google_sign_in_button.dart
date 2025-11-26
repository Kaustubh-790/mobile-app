import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: authProvider.isLoading
                ? null
                : () => _handleGoogleSignIn(context, authProvider),
            icon: Image.asset(
              'assets/images/google_logo.png', // You'll need to add this asset
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if asset is not available
                return const Icon(Icons.g_mobiledata, size: 24, color: AppTheme.brown500);
              },
            ),
            label: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brown500,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sand40,
              foregroundColor: AppTheme.brown500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: AppTheme.beige10, width: 1),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    try {
      print('Starting Google Sign-In process...');
      final success = await authProvider.loginWithGoogle();

      if (success && context.mounted) {
        print('Google Sign-In successful, navigating to home...');
        // Navigate to home screen on success
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        print('Google Sign-In failed or returned false');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Google sign in failed: ${authProvider.error ?? 'Unknown error'}',
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Exception during Google Sign-In: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
