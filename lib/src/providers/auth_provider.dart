import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/auth_service.dart';
import '../api/api_client.dart';
import '../services/firebase_auth_service.dart';
import '../services/phone_auth_service.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _error;
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  final PhoneAuthService _phoneAuthService = PhoneAuthService();

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

          // Try to get user profile from backend using Firebase UID
          try {
            final firebaseUser = _firebaseAuth.currentFirebaseUser;
            if (firebaseUser != null) {
              final user = await AuthService().getProfileByFirebaseUid(
                firebaseUser.uid,
              );
              _currentUser = user;
            } else {
              // If no Firebase user, create user from Firebase data
              _currentUser = _createUserFromFirebase();
            }
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

          // Try to get user profile (this is for saved token, might not have Firebase UID)
          try {
            // For saved tokens, we can't use Firebase UID, so we'll need to handle this differently
            // For now, we'll clear the token and let the user re-authenticate
            await _clearStoredData();
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
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await AuthService().login(
        email: email,
        password: password,
      );

      final user = result['user'] as User;
      final firebaseToken = result['firebaseToken'] as String?;
      final actionRequired = result['action_required'] as String?;
      final requiresProfileCompletion = result['requiresProfileCompletion'] as bool? ?? false;

      // Save user
      _currentUser = user;

      // Handle Firebase custom token: Sign in to Firebase and get ID token
      if (firebaseToken != null) {
        try {
          // Sign in to Firebase with custom token
          final signInResult = await _firebaseAuth.signInWithCustomToken(firebaseToken);
          if (signInResult['success'] == true) {
            // Get the ID token from Firebase (this is what the backend expects)
            final idToken = signInResult['idToken'] as String?;
            if (idToken != null) {
              _authToken = idToken;
              await _saveTokenToStorage(_authToken!);
              ApiClient().setAuthToken(_authToken!);
              print('AuthProvider: Successfully signed in with Firebase and got ID token');
            } else {
              // Fallback: Get ID token from current Firebase user
              final idTokenFromFirebase = await _firebaseAuth.getIdToken();
              if (idTokenFromFirebase != null) {
                _authToken = idTokenFromFirebase;
                await _saveTokenToStorage(_authToken!);
                ApiClient().setAuthToken(_authToken!);
              } else {
                throw Exception('Failed to get ID token from Firebase');
              }
            }
          } else {
            // Even if signInWithCustomToken reports failure, check if user is actually signed in
            // This handles the case where the Firebase plugin throws but auth succeeds
            print('AuthProvider: signInWithCustomToken reported failure, checking auth state...');
            await Future.delayed(const Duration(milliseconds: 500));
            
            final idTokenFromFirebase = await _firebaseAuth.getIdToken();
            if (idTokenFromFirebase != null) {
              print('AuthProvider: User is actually signed in, using ID token');
              _authToken = idTokenFromFirebase;
              await _saveTokenToStorage(_authToken!);
              ApiClient().setAuthToken(_authToken!);
            } else {
              throw Exception('Failed to sign in with Firebase custom token');
            }
          }
        } catch (e) {
          print('AuthProvider: Error signing in with Firebase custom token: $e');
          
          // Last resort: Check if user is actually signed in despite the error
          // This is a workaround for a known Firebase Auth plugin issue
          print('AuthProvider: Checking if user is signed in despite error...');
          await Future.delayed(const Duration(milliseconds: 500));
          
          try {
            final idTokenFromFirebase = await _firebaseAuth.getIdToken();
            if (idTokenFromFirebase != null) {
              print('AuthProvider: User is signed in! Using ID token despite error');
              _authToken = idTokenFromFirebase;
              await _saveTokenToStorage(_authToken!);
              ApiClient().setAuthToken(_authToken!);
            } else {
              throw Exception('Failed to authenticate with Firebase: $e');
            }
          } catch (fallbackError) {
            print('AuthProvider: Fallback also failed: $fallbackError');
            throw Exception('Failed to authenticate with Firebase: $e');
          }
        }
      } else if (user.firebaseUid != null) {
        // If no custom token but we have Firebase UID, try to get ID token directly
        final idToken = await _firebaseAuth.getIdToken();
        if (idToken != null) {
          _authToken = idToken;
          await _saveTokenToStorage(_authToken!);
          ApiClient().setAuthToken(_authToken!);
        } else {
          throw Exception('No Firebase authentication available');
        }
      } else {
        throw Exception('No authentication token available');
      }

      notifyListeners();

      // Return result with onboarding info
      return {
        'success': true,
        'user': user,
        'action_required': actionRequired,
        'requiresProfileCompletion': requiresProfileCompletion,
      };
    } catch (e) {
      _setError('Login failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Login with phone number
  Future<bool> loginWithPhone(String phoneNumber) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _phoneAuthService.sendOTP(phoneNumber);

      if (result['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _setError('Failed to send OTP');
        return false;
      }
    } catch (e) {
      _setError('Phone login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP for phone authentication
  Future<bool> verifyPhoneOTP(String otp) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _phoneAuthService.verifyOTP(otp);

      if (result['success'] == true) {
        final user = result['user'] as User;
        final firebaseToken = result['firebaseToken'] as String;

        // Save user and token
        _currentUser = user;
        _authToken = firebaseToken;
        await _saveTokenToStorage(_authToken!);
        ApiClient().setAuthToken(_authToken!);

        notifyListeners();
        return true;
      } else {
        _setError('OTP verification failed');
        return false;
      }
    } catch (e) {
      _setError('OTP verification failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resend OTP for phone authentication
  Future<bool> resendPhoneOTP(String phoneNumber) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _phoneAuthService.resendOTP(phoneNumber);

      if (result['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _setError('Failed to resend OTP');
        return false;
      }
    } catch (e) {
      _setError('Failed to resend OTP: $e');
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
        phone: userData['phone']?.toString(),
        firebaseUid: userData['firebaseUid']?.toString(),
        profilePic: userData['profilePic']?.toString(),
        numberOfBookings: userData['numberOfBookings'] ?? 0,
        hasFirstBooking: userData['hasFirstBooking'] ?? false,
        profileCompleted: userData['profileCompleted'] ?? false,
        role: userData['role']?.toString() ?? 'user',
        address: userData['address']?.toString(),
        city: userData['city']?.toString(),
        state: userData['state']?.toString(),
        zipCode: userData['zipCode']?.toString(),
        country: userData['country']?.toString(),
        dateOfBirth: userData['dateOfBirth']?.toString(),
        gender: userData['gender']?.toString(),
        createdAt: userData['createdAt'] != null
            ? DateTime.parse(userData['createdAt'].toString())
            : null,
        updatedAt: userData['updatedAt'] != null
            ? DateTime.parse(userData['updatedAt'].toString())
            : null,
      );
    } else {
      throw Exception('Invalid user data format');
    }
  }

  /// Create user from Firebase data
  User _createUserFromFirebase() {
    final firebaseUser = _firebaseAuth.currentFirebaseUser;
    if (firebaseUser == null) {
      throw Exception('No Firebase user available');
    }

    return User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email,
      phone: firebaseUser.phoneNumber,
      firebaseUid: firebaseUser.uid,
      profilePic: firebaseUser.photoURL,
      numberOfBookings: 0,
      hasFirstBooking: false,
      profileCompleted: false,
      role: 'user',
    );
  }

  /// Manual backend sync for Google login
  Future<User?> _manualBackendSync(User user, String firebaseToken) async {
    try {
      print('AuthProvider: Attempting manual backend sync...');

      final dio = Dio();
      dio.options.baseUrl = 'https://kariighar.onrender.com/api';

      final response = await dio.post(
        '/auth/google-login',
        data: {
          'firebaseUid': user.firebaseUid,
          'name': user.name,
          'email': user.email,
        },
      );

      if (response.data['user'] != null) {
        print('AuthProvider: Manual backend sync successful!');
        return User.fromJson(response.data['user']);
      } else {
        print('AuthProvider: Manual backend sync failed - no user data');
        return null;
      }
    } catch (e) {
      print('AuthProvider: Manual backend sync error: $e');
      return null;
    }
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

      // Store user data temporarily (will be cleared after verification)
      // User doesn't have Firebase UID yet, so we store locally
      _currentUser = user;
      // Don't set auth token yet - user needs to verify email first

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify email with token
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await AuthService().verifyEmail(token);

      if (result['success'] == true) {
        final user = result['user'] as User?;
        final firebaseToken = result['firebaseToken'] as String?;
        final actionRequired = result['action_required'] as String?;

        // If we have firebaseToken, verification succeeded - proceed with login
        if (firebaseToken != null) {
          // Sign in with Firebase custom token first
          try {
            final signInResult = await _firebaseAuth.signInWithCustomToken(firebaseToken);
            if (signInResult['success'] == true) {
              print('AuthProvider: Successfully signed in with Firebase custom token');
              // Use the ID token from Firebase for API calls
              if (signInResult['idToken'] != null) {
                _authToken = signInResult['idToken'] as String;
              } else {
                // Fallback: Get ID token from current Firebase user
                final idTokenFromFirebase = await _firebaseAuth.getIdToken();
                if (idTokenFromFirebase != null) {
                  _authToken = idTokenFromFirebase;
                } else {
                  // Last resort: Use custom token
                  _authToken = firebaseToken;
                }
              }
            } else {
              // Fallback: Get ID token from current Firebase user
              final idTokenFromFirebase = await _firebaseAuth.getIdToken();
              if (idTokenFromFirebase != null) {
                _authToken = idTokenFromFirebase;
              } else {
                _authToken = firebaseToken;
              }
            }
          } catch (e) {
            print('AuthProvider: Error signing in with Firebase token: $e');
            // Check if user is actually signed in despite error
            await Future.delayed(const Duration(milliseconds: 500));
            final idTokenFromFirebase = await _firebaseAuth.getIdToken();
            if (idTokenFromFirebase != null) {
              _authToken = idTokenFromFirebase;
            } else {
              _authToken = firebaseToken;
            }
          }

          // If user object is null, try to fetch it from backend using Firebase UID
          if (user == null) {
            try {
              // Get Firebase UID from the signed-in user
              final firebaseUser = _firebaseAuth.currentFirebaseUser;
              if (firebaseUser != null) {
                print('AuthProvider: Fetching user profile from backend after verification...');
                final fetchedUser = await AuthService().getProfileByFirebaseUid(firebaseUser.uid);
                _currentUser = fetchedUser;
                print('AuthProvider: Fetched user - profileCompleted: ${fetchedUser.profileCompleted}');
              }
            } catch (e) {
              print('AuthProvider: Error fetching user profile: $e');
              // Continue without user - token is set, user can proceed
            }
          } else {
            _currentUser = user;
            print('AuthProvider: User from verification - profileCompleted: ${user.profileCompleted}');
          }

          // Save token and update API client
          if (_authToken != null) {
            await _saveTokenToStorage(_authToken!);
            ApiClient().setAuthToken(_authToken!);
          }

          notifyListeners();

          // Determine final onboarding status from the actual user object
          final finalUser = _currentUser ?? user;
          final finalNeedsOnboarding = finalUser != null && !finalUser.profileCompleted;
          final finalActionRequired = finalNeedsOnboarding ? 'ONBOARDING' : (actionRequired ?? 'PROCEED');
          
          print('AuthProvider: Final onboarding check - needsOnboarding: $finalNeedsOnboarding, actionRequired: $finalActionRequired');

          // Return result with onboarding info
          return {
            'success': true,
            'user': finalUser,
            'action_required': finalActionRequired,
            'requiresProfileCompletion': finalNeedsOnboarding,
          };
        } else if (user != null) {
          // User object exists but no firebaseToken - email verified but need to login
          _currentUser = user;
          notifyListeners();
          return {
            'success': false,
            'error': 'Email verified. Please login to continue.',
            'user': user,
          };
        } else if (result['alreadyVerified'] == true) {
          // Email already verified, but no token returned
          // User should login normally
          return {
            'success': false,
            'error': 'Email already verified. Please login to continue.',
          };
        }
      }

      return {
        'success': false,
        'error': 'Email verification failed',
      };
    } catch (e) {
      // Check if error message suggests verification succeeded
      final errorStr = e.toString();
      if (errorStr.contains('Verification completed') || 
          errorStr.contains('try logging in')) {
        // Verification likely succeeded, but we can't complete auto-login
        // User should try logging in manually
        return {
          'success': false,
          'error': 'Verification completed. Please login to continue.',
        };
      } else {
        return {
          'success': false,
          'error': 'Email verification failed: $e',
        };
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await AuthService().resendVerificationEmail(email);

      if (result['success'] == true) {
        notifyListeners();
        return true;
      }

      _setError('Failed to resend verification email');
      return false;
    } catch (e) {
      _setError('Failed to resend verification email: $e');
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

      // Clear stored data
      await _clearStoredData();

      // Clear phone auth data
      _phoneAuthService.clearVerificationData();

      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
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

      // Try to get user profile using Firebase UID
      final firebaseUser = _firebaseAuth.currentFirebaseUser;
      if (firebaseUser != null) {
        final user = await AuthService().getProfileByFirebaseUid(
          firebaseUser.uid,
        );
        _currentUser = user;
        notifyListeners();
      } else {
        // If no Firebase user, clear data and let user re-authenticate
        await _clearStoredData();
        notifyListeners();
      }
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

    // Try to get user profile using Firebase UID
    try {
      final firebaseUser = _firebaseAuth.currentFirebaseUser;
      if (firebaseUser != null) {
        final user = await AuthService().getProfileByFirebaseUid(
          firebaseUser.uid,
        );
        _currentUser = user;
      } else {
        _setError('No Firebase user available for profile fetch');
      }
    } catch (e) {
      _setError('Failed to get user profile: $e');
    }

    notifyListeners();
  }

  /// Get fresh ID token from Firebase (refreshes if needed)
  Future<String?> getFreshIdToken() async {
    try {
      if (_firebaseAuth.isSignedIn) {
        // Force refresh to get a new token
        final idToken = await _firebaseAuth.getIdToken();
        if (idToken != null) {
          _authToken = idToken;
          await _saveTokenToStorage(idToken);
          ApiClient().setAuthToken(idToken);
          return idToken;
        }
      }
      return _authToken;
    } catch (e) {
      print('AuthProvider: Error getting fresh ID token: $e');
      return _authToken;
    }
  }

  /// Debug method for testing authentication flow
  Future<Map<String, dynamic>> debugAuthFlow() async {
    try {
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
            final backendUser = await AuthService().getProfileByFirebaseUid(
              user.firebaseUid!,
            );
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
