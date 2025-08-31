# Settings Screens

This folder contains various settings-related screens for the mobile app.

## MyProfileScreen

The `MyProfileScreen` displays user profile information fetched from the backend. It shows the following user details:

- **Full Name** - User's display name
- **Email Address** - User's email
- **Phone Number** - User's phone number
- **Address** - Complete address including city, state, zip code, and country

### Features

- **Automatic Profile Loading** - Fetches profile data when the screen loads
- **Fallback Handling** - Multiple fallback strategies if backend fetch fails
- **Pull-to-Refresh** - Users can pull down to refresh profile data
- **Error Handling** - Graceful error handling with retry options
- **Loading States** - Shows loading indicators during data fetch
- **Responsive Design** - Clean, modern UI with cards and icons

### Usage

#### Basic Navigation

```dart
import 'package:your_app/src/screens/settings/my_profile.dart';

// Navigate to My Profile screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyProfileScreen(),
  ),
);
```

#### Using Navigation Helper

```dart
import 'package:your_app/src/screens/settings/navigation_example.dart';

// Simple navigation
SettingsNavigationExample.navigateToMyProfile(context);

// Replace current screen
SettingsNavigationExample.navigateToMyProfileReplace(context);

// Clear navigation stack
SettingsNavigationExample.navigateToMyProfileClearStack(context);
```

### Profile Data Sources

The screen tries to fetch profile data in the following order:

1. **Direct Backend Fetch** - Uses `AuthService().getProfile()` to get fresh data
2. **Provider Refresh** - Falls back to `AuthProvider.refreshUserData()`
3. **Current User** - Uses existing user data from `AuthProvider.currentUser`

### Error Handling

- **Backend Unavailable** - Shows error message with retry button
- **No Profile Data** - Displays appropriate message
- **Network Issues** - Graceful fallback to cached data

### UI Components

- **Profile Header** - Large avatar, name, email, and role badge
- **Profile Details** - Organized fields with icons and labels
- **Address Formatting** - Smart address concatenation from multiple fields
- **Loading States** - Circular progress indicators and skeleton screens
- **Error States** - Clear error messages with actionable buttons

### Dependencies

- `flutter/material.dart` - Core Flutter widgets
- `provider/provider.dart` - State management
- `../../providers/auth_provider.dart` - Authentication provider
- `../../models/user.dart` - User data model
- `../../api/auth_service.dart` - Backend API service

### Customization

The screen uses the app's primary color theme and can be easily customized by:

- Modifying the color scheme in the theme
- Adjusting card elevations and border radius
- Changing icon styles and sizes
- Modifying spacing and typography

### Future Enhancements

Potential improvements for the future:

- **Profile Editing** - Allow users to edit their profile
- **Profile Picture Upload** - Support for custom profile pictures
- **Additional Fields** - Show more user information
- **Profile Completion** - Progress indicator for incomplete profiles
- **Social Links** - Integration with social media profiles
