import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Register a new user with email and password
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/register-email',
        data: {'name': name, 'email': email, 'password': password},
      );

      // Check if response has user data (successful registration)
      if (response.data['user'] != null) {
        final user = User.fromJson(response.data['user']);
        return {
          'user': user,
          'message': response.data['message'] ?? 'Registration successful',
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['error'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Registration failed');
    } catch (e) {
      throw Exception('Unexpected error during registration: $e');
    }
  }

  /// Login user with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login-email',
        data: {'email': email, 'password': password},
      );

      // Check if response has user data (successful login)
      if (response.data['user'] != null) {
        final user = User.fromJson(response.data['user']);
        return {
          'user': user,
          'message': response.data['message'] ?? 'Login successful',
          'firebaseToken': response.data['firebaseToken'],
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['error'] ?? 'Login failed',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Login failed');
    } catch (e) {
      throw Exception('Unexpected error during login: $e');
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      final response = await ApiClient.dio.post('/auth/logout');

      if (response.data['success'] == true) {
        // Clear the auth token from ApiClient
        ApiClient().clearAuthToken();
        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      // Even if logout fails on backend, clear local token
      ApiClient().clearAuthToken();

      if (e.response?.statusCode == 401) {
        // Unauthorized - token might be expired, still consider logout successful
        return true;
      }

      throw _handleDioError(e, 'Logout failed');
    } catch (e) {
      // Clear token on any error
      ApiClient().clearAuthToken();
      throw Exception('Unexpected error during logout: $e');
    }
  }

  /// Get user profile
  Future<User> getProfile() async {
    try {
      final response = await ApiClient.dio.get('/auth/profile');

      if (response.data['success'] == true) {
        return User.fromJson(response.data['user']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['error'] ?? 'Failed to get profile',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get profile');
    } catch (e) {
      throw Exception('Unexpected error getting profile: $e');
    }
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await ApiClient.dio.put(
        '/auth/profile',
        data: profileData,
      );

      if (response.data['success'] == true) {
        return User.fromJson(response.data['user']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['error'] ?? 'Failed to update profile',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update profile');
    } catch (e) {
      throw Exception('Unexpected error updating profile: $e');
    }
  }

  /// Handle Dio errors and provide meaningful error messages
  Exception _handleDioError(DioException e, String defaultMessage) {
    String message = defaultMessage;

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      switch (statusCode) {
        case 400:
          message = responseData['error'] ?? 'Bad request';
          break;
        case 401:
          message = 'Unauthorized - Please login again';
          break;
        case 403:
          message = 'Access denied';
          break;
        case 404:
          message = 'Resource not found';
          break;
        case 409:
          message =
              responseData['error'] ?? 'Conflict - Resource already exists';
          break;
        case 422:
          message = responseData['error'] ?? 'Validation failed';
          break;
        case 500:
          message = 'Server error - Please try again later';
          break;
        default:
          message = responseData['error'] ?? defaultMessage;
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout - Please check your internet connection';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Request timeout - Please try again';
    } else if (e.type == DioExceptionType.connectionError) {
      message =
          'Backend server is not running. Please start the backend server at localhost:3000';
    } else if (e.type == DioExceptionType.badResponse) {
      message = 'Bad response from server: ${e.response?.statusCode}';
    } else if (e.type == DioExceptionType.cancel) {
      message = 'Request was cancelled';
    } else if (e.type == DioExceptionType.unknown) {
      message = 'Unknown error occurred: ${e.message}';
    }

    // Add more context to the error message
    if (e.message != null && e.message!.isNotEmpty) {
      message = '$message (${e.message})';
    }

    return Exception(message);
  }
}
