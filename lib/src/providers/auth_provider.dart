import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/auth_service.dart';
import '../api/api_client.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _error;
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  // Getters
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  // Private constructor
  AuthProvider._();

  // Singleton instance
  static final AuthProvider _instance = AuthProvider._();
  factory AuthProvider() => _instance;

  /// Initialize auth state from SharedPreferences and Firebase
  Future<void> initialize() async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();

      // Check if user is signed in with Firebase
      if (_firebaseAuth.isSignedIn) {
        final idToken = await _firebaseAuth.getIdToken();
        if (idToken != null) {
          _authToken = idToken;
          ApiClient().setAuthToken(idToken);

          // Try to get user profile from backend
          try {
            final user = await AuthService().getProfile();
            _currentUser = user;
          } catch (e) {
            // If backend fails, create user from Firebase data
            _currentUser = _createUserFromFirebase();
          }
        }
      } else {
        // Load saved token from SharedPreferences
        final savedToken = prefs.getString('auth_token');
        if (savedToken != null) {
          _authToken = savedToken;
          ApiClient().setAuthToken(savedToken);

          // Try to get user profile
          try {
            final user = await AuthService().getProfile();
            _currentUser = user;
          } catch (e) {
            // Token might be expired, clear it
            await _clearStoredData();
          }
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Login user with email and password
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await AuthService().login(
        email: email,
        password: password,
      );

      final user = result['user'] as User;
      final message = result['message'] as String;
      final firebaseToken = result['firebaseToken'] as String?;

      // Save user and token
      _currentUser = user;

      // Use the firebaseToken from backend response
      if (firebaseToken != null) {
        _authToken = firebaseToken;
        await _saveTokenToStorage(_authToken!);
        ApiClient().setAuthToken(_authToken!);
      } else if (user.firebaseUid != null) {
        // Fallback to firebaseUid if no token provided
        _authToken = user.firebaseUid;
        await _saveTokenToStorage(_authToken!);
        ApiClient().setAuthToken(_authToken!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with Google - improved version
  Future<bool> loginWithGoogle() async {
    try {
      print('AuthProvider: Starting Google login...');
      _setLoading(true);
      _clearError();

      // Try the improved Firebase auth method
      final result = await _firebaseAuth.signInWithGoogle();

      print('AuthProvider: Firebase auth result: $result');

      if (result['success'] == true) {
        print('AuthProvider: Google login successful, processing result...');

        final userData = result['user'];
        final firebaseToken = result['firebaseToken'] as String;
        final backendSync = result['backendSync'] as bool? ?? false;

        // Convert userData to User object
        User user = _convertToUserObject(userData);

        print('AuthProvider: User: ${user.name}, Email: ${user.email}');
        print('AuthProvider: Firebase UID: ${user.firebaseUid}');
        print('AuthProvider: Backend sync: $backendSync');

        // If backend sync failed, try to sync manually
        if (!backendSync && user.firebaseUid != null) {
          print('AuthProvider: Backend sync failed, attempting manual sync...');
          try {
            final manualSyncResult = await _manualBackendSync(
              user,
              firebaseToken,
            );
            if (manualSyncResult != null) {
              user = manualSyncResult;
              print('AuthProvider: Manual backend sync successful!');
            }
          } catch (e) {
            print('AuthProvider: Manual backend sync failed: $e');
            // Continue with local user data
          }
        }

        // Save user and token
        _currentUser = user;
        _authToken = firebaseToken;
        await _saveTokenToStorage(_authToken!);
        ApiClient().setAuthToken(_authToken!);

        notifyListeners();
        return true;
      } else {
        print(
          'AuthProvider: Google login failed with error: ${result['error']}',
        );
        _setError(result['error'] ?? 'Google login failed');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Exception during Google login: $e');
      _setError('Google login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Convert user data to User object
  User _convertToUserObject(dynamic userData) {
    if (userData is User) {
      return userData;
    } else if (userData is Map<String, dynamic>) {
      return User(
        id: userData['id']?.toString() ?? '',
        name: userData['name']?.toString() ?? 'User',
        email: userData['email']?.toString() ?? '',
        role: userData['role']?.toString() ?? 'user',
        firebaseUid: userData['firebaseUid']?.toString(),
        profilePic: userData['profilePic']?.toString(),
        profileCompleted: userData['profileCompleted'] as bool? ?? false,
        hasFirstBooking: userData['hasFirstBooking'] as bool? ?? false,
        numberOfBookings: userData['numberOfBookings'] as int? ?? 0,
      );
    } else {
      throw Exception('Invalid user data format: ${userData.runtimeType}');
    }
  }

  /// Manual backend sync when automatic sync fails
  Future<User?> _manualBackendSync(User localUser, String firebaseToken) async {
    try {
      print('AuthProvider: Attempting manual backend sync...');

      // Retry Firebase auth to get proper UID
      final retryUid = await _firebaseAuth.retryFirebaseAuth();
      if (retryUid != null) {
        print('AuthProvider: Retry successful, using Firebase UID: $retryUid');

        // Update local user with proper Firebase UID
        final updatedUser = User(
          id: localUser.id,
          name: localUser.name,
          email: localUser.email,
          role: localUser.role,
          firebaseUid: retryUid, // Use the proper Firebase UID
          profilePic: localUser.profilePic,
          profileCompleted: localUser.profileCompleted,
          hasFirstBooking: localUser.hasFirstBooking,
          numberOfBookings: localUser.numberOfBookings,
        );

        // Try backend sync with proper UID
        final syncResult = await AuthService().googleLogin(firebaseToken);
        if (syncResult['user'] != null) {
          return User.fromJson(syncResult['user']);
        }
      }

      return null;
    } catch (e) {
      print('AuthProvider: Manual backend sync failed: $e');
      return null;
    }
  }

  /// Create user from Firebase data
  User _createUserFromFirebase() {
    return User(
      id: _firebaseAuth.currentFirebaseUser?.uid ?? '',
      name: _firebaseAuth.currentUserDisplayName ?? 'User',
      email: _firebaseAuth.currentUserEmail ?? '',
      role: 'user',
      firebaseUid: _firebaseAuth.currentFirebaseUser?.uid,
      profilePic: _firebaseAuth.currentUserPhotoURL,
      profileCompleted: false,
      hasFirstBooking: false,
      numberOfBookings: 0,
    );
  }

  /// Register new user
  Future<bool> register(String name, String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await AuthService().register(
        name: name,
        email: email,
        password: password,
      );

      final user = result['user'] as User;
      final message = result['message'] as String;

      // For registration, user might need to verify email first
      // So we don't automatically log them in
      // But we can store the user data for later use
      _currentUser = user;

      // Note: Registration might not return a token immediately
      // depending on your backend flow (email verification required)

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _setLoading(true);

      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Call logout on backend
      try {
        await AuthService().logout();
      } catch (e) {
        print('Backend logout failed: $e');
        // Continue with local logout even if backend fails
      }

      // Clear local state
      await _clearStoredData();

      notifyListeners();
    } catch (e) {
      // Even if logout fails, clear local state
      await _clearStoredData();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Update current user profile
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedUser = await AuthService().updateProfile(profileData);
      _currentUser = updatedUser;

      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user data from backend
  Future<void> refreshUserData() async {
    try {
      if (_authToken == null) return;

      final user = await AuthService().getProfile();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      // If refresh fails, user might be logged out
      await _clearStoredData();
      notifyListeners();
    }
  }

  /// Set Firebase ID token (called after Firebase authentication)
  Future<void> setFirebaseToken(String token) async {
    _authToken = token;
    await _saveTokenToStorage(token);
    ApiClient().setAuthToken(token);

    // Try to get user profile
    try {
      final user = await AuthService().getProfile();
      _currentUser = user;
    } catch (e) {
      _setError('Failed to get user profile: $e');
    }

    notifyListeners();
  }

  /// Test and debug Google login flow
  Future<Map<String, dynamic>> debugGoogleLogin() async {
    try {
      print('AuthProvider: Starting debug Google login...');

      final debugResult = <String, dynamic>{};

      // Step 1: Test Firebase connection
      final firebaseTest = await _firebaseAuth.testFirebaseConnection();
      debugResult['firebase_test'] = firebaseTest;
      print('AuthProvider: Firebase test: $firebaseTest');

      // Step 2: Attempt Google login
      final loginResult = await _firebaseAuth.signInWithGoogle();
      debugResult['login_result'] = loginResult;
      print('AuthProvider: Login result: $loginResult');

      // Step 3: If login successful, test backend sync
      if (loginResult['success'] == true) {
        final userData = loginResult['user'];
        final user = _convertToUserObject(userData);

        debugResult['converted_user'] = {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'firebaseUid': user.firebaseUid,
          'profileCompleted': user.profileCompleted,
        };

        // Test if we can get profile from backend
        if (loginResult['backendSync'] == true) {
          try {
            ApiClient().setAuthToken(loginResult['firebaseToken']);
            final backendUser = await AuthService().getProfile();
            debugResult['backend_profile'] = {
              'success': true,
              'user': {
                'id': backendUser.id,
                'name': backendUser.name,
                'email': backendUser.email,
                'firebaseUid': backendUser.firebaseUid,
              },
            };
          } catch (e) {
            debugResult['backend_profile'] = {
              'success': false,
              'error': e.toString(),
            };
          }
        }
      }

      return debugResult;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear stored data (token and user)
  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      _authToken = null;
      _currentUser = null;

      // Clear token from ApiClient
      ApiClient().clearAuthToken();
    } catch (e) {
      // Ignore errors when clearing data
    }
  }

  /// Save token to SharedPreferences
  Future<void> _saveTokenToStorage(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      _setError('Failed to save authentication token: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear error manually (for UI)
  void clearError() {
    _clearError();
  }
}
