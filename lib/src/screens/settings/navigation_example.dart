import 'package:flutter/material.dart';
import 'my_profile.dart';

/// Example of how to navigate to the MyProfileScreen
///
/// You can use this in your settings menu or anywhere else in your app:
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => const MyProfileScreen(),
///   ),
/// );
/// ```
///
/// Or if you want to replace the current screen:
///
/// ```dart
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(
///     builder: (context) => const MyProfileScreen(),
///   ),
/// );
/// ```
///
/// Or if you want to navigate and clear the stack:
///
/// ```dart
/// Navigator.pushAndRemoveUntil(
///   context,
///   MaterialPageRoute(
///     builder: (context) => const MyProfileScreen(),
///   ),
///   (route) => false,
/// );
/// ```

class SettingsNavigationExample {
  /// Navigate to My Profile screen
  static void navigateToMyProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyProfileScreen()),
    );
  }

  /// Navigate to My Profile screen and replace current screen
  static void navigateToMyProfileReplace(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyProfileScreen()),
    );
  }

  /// Navigate to My Profile screen and clear navigation stack
  static void navigateToMyProfileClearStack(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyProfileScreen()),
      (route) => false,
    );
  }
}
