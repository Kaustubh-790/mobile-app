import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/auth_service.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _error;

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

  /// Initialize auth state from SharedPreferences
  Future<void> initialize() async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();

      // Load saved token
      final savedToken = prefs.getString('auth_token');
      if (savedToken != null) {
        _authToken = savedToken;
        // Set token in ApiClient
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

      // Call logout on backend
      await AuthService().logout();

      // Clear local state
      await _clearStoredData();

      notifyListeners();
    } catch (e) {
      // Even if backend logout fails, clear local state
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
