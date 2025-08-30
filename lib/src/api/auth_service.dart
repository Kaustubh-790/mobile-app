import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

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

  /// Test the connection to the backend server
  Future<bool> testConnection() async {
    try {
      print('AuthService: Testing connection to backend server...');
      print('AuthService: Base URL: ${ApiClient.dio.options.baseUrl}');

      final response = await ApiClient.dio.get(
        '/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      print(
        'AuthService: Connection test successful - Status: ${response.statusCode}',
      );
      print('AuthService: Response data: ${response.data}');
      return true;
    } catch (e) {
      print('AuthService: Connection test failed - $e');

      // Add more specific debugging for DioException
      if (e is DioException) {
        print('AuthService: DioException type: ${e.type}');
        print('AuthService: DioException message: ${e.message}');
        print('AuthService: Request URL: ${e.requestOptions.uri}');
        print('AuthService: Request method: ${e.requestOptions.method}');

        if (e.response != null) {
          print('AuthService: Response status: ${e.response!.statusCode}');
          print('AuthService: Response data: ${e.response!.data}');
        }
      }

      return false;
    }
  }

  /// Test the specific auth endpoints
  Future<Map<String, dynamic>> testAuthEndpoints() async {
    final results = <String, dynamic>{};

    try {
      print('AuthService: Testing auth endpoints...');

      // Test login endpoint (without actual login)
      try {
        final response = await ApiClient.dio.get('/auth/login-email');
        results['login_endpoint'] = {
          'status': 'accessible',
          'statusCode': response.statusCode,
          'data': response.data,
        };
        print(
          'AuthService: Login endpoint accessible - Status: ${response.statusCode}',
        );
      } catch (e) {
        results['login_endpoint'] = {'status': 'error', 'error': e.toString()};
        print('AuthService: Login endpoint error - $e');
      }

      // Test register endpoint
      try {
        final response = await ApiClient.dio.get('/auth/register-email');
        results['register_endpoint'] = {
          'status': 'accessible',
          'statusCode': response.statusCode,
          'data': response.data,
        };
        print(
          'AuthService: Register endpoint accessible - Status: ${response.statusCode}',
        );
      } catch (e) {
        results['register_endpoint'] = {
          'status': 'error',
          'error': e.toString(),
        };
        print('AuthService: Register endpoint error - $e');
      }
    } catch (e) {
      print('AuthService: Error testing auth endpoints: $e');
      results['error'] = e.toString();
    }

    return results;
  }

  /// Google OAuth login
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      print(
        'AuthService: Starting Google login with idToken length: ${idToken.length}',
      );
      print('AuthService: Using base URL: ${ApiClient.dio.options.baseUrl}');

      // First, verify the Firebase ID token to get user details
      final firebaseAuth = firebase_auth.FirebaseAuth.instance;
      final user = firebaseAuth.currentUser;

      if (user == null) {
        throw Exception('No Firebase user found');
      }

      print(
        'AuthService: Firebase user found - UID: ${user.uid}, Name: ${user.displayName}, Email: ${user.email}',
      );

      // Based on the backend controller, it expects firebaseUid, name, and email
      // NOT idToken as shown in the API documentation
      final requestData = {
        'firebaseUid': user.uid,
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
      };

      print('AuthService: Sending request data: $requestData');
      print(
        'AuthService: Making POST request to: ${ApiClient.dio.options.baseUrl}/auth/google-login',
      );

      final response = await ApiClient.dio.post(
        '/auth/google-login',
        data: requestData,
      );

      print('AuthService: Response status: ${response.statusCode}');
      print('AuthService: Response data: ${response.data}');

      // Check if response has user data (successful login)
      if (response.data['user'] != null) {
        final userData = User.fromJson(response.data['user']);
        return {
          'user': userData,
          'message': response.data['message'] ?? 'Google login successful',
          'firebaseToken': idToken,
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: response.data['error'] ?? 'Google login failed',
        );
      }
    } on DioException catch (e) {
      print('AuthService: DioException in Google login: ${e.message}');
      print('AuthService: Status code: ${e.response?.statusCode}');
      print('AuthService: Response data: ${e.response?.data}');
      print('AuthService: Request URL: ${e.requestOptions.uri}');
      print('AuthService: Request method: ${e.requestOptions.method}');
      throw _handleDioError(e, 'Google login failed');
    } catch (e) {
      print('AuthService: Unexpected error in Google login: $e');
      throw Exception('Unexpected error during Google login: $e');
    }
  }

  /// Test the Google login endpoint specifically
  Future<Map<String, dynamic>> testGoogleLoginEndpoint() async {
    try {
      print('AuthService: Testing Google login endpoint...');
      print(
        'AuthService: Testing endpoint: ${ApiClient.dio.options.baseUrl}/auth/google-login',
      );

      // Test with a simple request to see what the endpoint expects
      final response = await ApiClient.dio.get('/auth/google-login');

      return {
        'status': 'accessible',
        'statusCode': response.statusCode,
        'data': response.data,
        'message': 'Endpoint is accessible',
      };
    } catch (e) {
      print('AuthService: Google login endpoint test failed: $e');

      if (e is DioException) {
        return {
          'status': 'error',
          'statusCode': e.response?.statusCode,
          'error': e.message,
          'data': e.response?.data,
        };
      }

      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Test the Google login endpoint with POST method
  Future<Map<String, dynamic>> testGoogleLoginEndpointPost() async {
    try {
      print('AuthService: Testing Google login endpoint with POST...');
      print(
        'AuthService: Testing endpoint: ${ApiClient.dio.options.baseUrl}/auth/google-login',
      );

      // Test with a POST request to see if the endpoint exists
      final response = await ApiClient.dio.post(
        '/auth/google-login',
        data: {'test': 'data'},
      );

      return {
        'status': 'accessible',
        'statusCode': response.statusCode,
        'data': response.data,
        'message': 'Endpoint is accessible with POST',
      };
    } catch (e) {
      print('AuthService: Google login endpoint POST test failed: $e');

      if (e is DioException) {
        return {
          'status': 'error',
          'statusCode': e.response?.statusCode,
          'error': e.message,
          'data': e.response?.data,
        };
      }

      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Test if the Google login route exists and is properly configured
  Future<Map<String, dynamic>> testGoogleLoginRoute() async {
    try {
      print('AuthService: Testing Google login route configuration...');
      print(
        'AuthService: Testing endpoint: ${ApiClient.dio.options.baseUrl}/auth/google-login',
      );

      // Test with a simple GET request to see if the route exists
      try {
        final response = await ApiClient.dio.get('/auth/google-login');
        print('AuthService: GET request successful: ${response.statusCode}');

        // Check if the response is HTML (indicating a frontend route) or JSON (indicating an API route)
        if (response.data is String &&
            response.data.toString().contains('<!DOCTYPE html>')) {
          return {
            'status': 'route_exists_but_frontend',
            'statusCode': response.statusCode,
            'data': response.data,
            'message':
                'Route exists but returns HTML (frontend route, not API)',
          };
        } else {
          return {
            'status': 'route_exists_api',
            'statusCode': response.statusCode,
            'data': response.data,
            'message': 'Route exists and returns API data',
          };
        }
      } catch (e) {
        print('AuthService: GET request failed: $e');

        // Try with a POST request to see if it's a POST-only route
        try {
          final response = await ApiClient.dio.post(
            '/auth/google-login',
            data: {'test': 'data'},
          );
          print('AuthService: POST request successful: ${response.statusCode}');
          return {
            'status': 'route_exists_post_only',
            'statusCode': response.statusCode,
            'data': response.data,
            'message': 'Route exists and accepts POST requests',
          };
        } catch (e2) {
          print('AuthService: POST request also failed: $e2');
          return {
            'status': 'route_not_found',
            'error':
                'Route /auth/google-login does not exist or is not accessible',
            'details': {'get_error': e.toString(), 'post_error': e2.toString()},
          };
        }
      }
    } catch (e) {
      print('AuthService: Route test failed: $e');
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Test different backend URLs to find the actual API endpoint
  Future<Map<String, dynamic>> testBackendUrls() async {
    final results = <String, dynamic>{};

    try {
      print('AuthService: Testing different backend URLs...');

      // Test the current URL
      try {
        final response = await ApiClient.dio.get('/');
        results['current_url'] = {
          'url': ApiClient.dio.options.baseUrl,
          'status': 'returns_html',
          'statusCode': response.statusCode,
          'isHtml': response.data.toString().contains('<!DOCTYPE html>'),
        };
      } catch (e) {
        results['current_url'] = {
          'url': ApiClient.dio.options.baseUrl,
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Test without /api prefix
      try {
        final dio = Dio();
        dio.options.baseUrl = 'https://kariighar.onrender.com';
        final response = await dio.get('/auth/google-login');
        results['without_api_prefix'] = {
          'url': 'https://kariighar.onrender.com',
          'status': 'accessible',
          'statusCode': response.statusCode,
          'isHtml': response.data.toString().contains('<!DOCTYPE html>'),
          'data': response.data,
        };
      } catch (e) {
        results['without_api_prefix'] = {
          'url': 'https://kariighar.onrender.com',
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Test with different API paths
      final testPaths = ['/api/v1', '/api/v2', '/v1', '/v2'];
      for (final path in testPaths) {
        try {
          final dio = Dio();
          dio.options.baseUrl = 'https://kariighar.onrender.com$path';
          final response = await dio.get('/auth/google-login');
          results[path] = {
            'url': 'https://kariighar.onrender.com$path',
            'status': 'accessible',
            'statusCode': response.statusCode,
            'isHtml': response.data.toString().contains('<!DOCTYPE html>'),
            'data': response.data,
          };
        } catch (e) {
          results[path] = {
            'url': 'https://kariighar.onrender.com$path',
            'status': 'error',
            'error': e.toString(),
          };
        }
      }
    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }

  /// Test server status and see if we can reach the backend
  Future<Map<String, dynamic>> testServerStatus() async {
    try {
      print('AuthService: Testing server status...');

      final results = <String, dynamic>{};

      // Test the main domain
      try {
        final dio = Dio();
        dio.options.baseUrl = 'https://kariighar.onrender.com';
        final response = await dio.get('/');
        results['main_domain'] = {
          'url': 'https://kariighar.onrender.com',
          'status': 'accessible',
          'statusCode': response.statusCode,
          'isHtml': response.data.toString().contains('<!DOCTYPE html>'),
          'title': response.data.toString().contains('<title>')
              ? response.data
                    .toString()
                    .split('<title>')[1]
                    .split('</title>')[0]
              : 'No title',
        };
      } catch (e) {
        results['main_domain'] = {
          'url': 'https://kariighar.onrender.com',
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Test if there's a health check endpoint
      final healthEndpoints = [
        '/health',
        '/status',
        '/ping',
        '/api/health',
        '/api/status',
      ];
      for (final endpoint in healthEndpoints) {
        try {
          final dio = Dio();
          dio.options.baseUrl = 'https://kariighar.onrender.com';
          final response = await dio.get(endpoint);
          results['health_$endpoint'] = {
            'url': 'https://kariighar.onrender.com$endpoint',
            'status': 'accessible',
            'statusCode': response.statusCode,
            'data': response.data,
          };
        } catch (e) {
          results['health_$endpoint'] = {
            'url': 'https://kariighar.onrender.com$endpoint',
            'status': 'error',
            'error': e.toString(),
          };
        }
      }

      // Test if there are any working API endpoints
      final apiEndpoints = ['/api', '/api/', '/v1', '/v1/'];
      for (final endpoint in apiEndpoints) {
        try {
          final dio = Dio();
          dio.options.baseUrl = 'https://kariighar.onrender.com';
          final response = await dio.get(endpoint);
          results['api_$endpoint'] = {
            'url': 'https://kariighar.onrender.com$endpoint',
            'status': 'accessible',
            'statusCode': response.statusCode,
            'isHtml': response.data.toString().contains('<!DOCTYPE html>'),
            'data': response.data,
          };
        } catch (e) {
          results['api_$endpoint'] = {
            'url': 'https://kariighar.onrender.com$endpoint',
            'status': 'error',
            'error': e.toString(),
          };
        }
      }

      return results;
    } catch (e) {
      return {'error': e.toString(), 'message': 'Server status test failed'};
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
          'Could not connect to the server. Please check your internet connection and try again.';
      // Add more specific debugging info for connection errors
      if (e.message != null && e.message!.contains('Connection refused')) {
        message +=
            '\n\nThis usually means:\n1. Your backend server is not running\n2. The server is running on a different port\n3. Firewall is blocking the connection\n4. For Android emulator, ensure server is accessible at 10.0.2.2:3000';
      }
    } else if (e.type == DioExceptionType.badResponse) {
      message = 'Bad response from server: ${e.response?.statusCode}';
    } else if (e.type == DioExceptionType.cancel) {
      message = 'Request was cancelled';
    } else if (e.type == DioExceptionType.unknown) {
      message = 'Unknown error occurred: ${e.message}';
    }

    // Add more context to the error message
    if (e.message != null && e.message!.isNotEmpty) {
      message = '$message\n\nTechnical details: ${e.message}';
    }

    // Log the error for debugging
    print('AuthService Error: $message');
    print('Error type: ${e.type}');
    print('Error message: ${e.message}');
    if (e.response != null) {
      print('Response status: ${e.response!.statusCode}');
      print('Response data: ${e.response!.data}');
    }

    return Exception(message);
  }

  /// Test Google login with exact Postman data format
  Future<Map<String, dynamic>> testGoogleLoginWithPostmanData() async {
    try {
      print('AuthService: Testing Google login with Postman data format...');

      // Use the exact same data format that works in Postman
      final testData = {
        'firebaseUid': 'M9e2mYZQutMI5kkTynQk1DHS2Gq1',
        'name': 'Kaustubh Sharma',
        'email': 'kaustubhsharma434@gmail.com',
      };

      print('AuthService: Sending test data: $testData');
      print(
        'AuthService: Making POST request to: ${ApiClient.dio.options.baseUrl}/auth/google-login',
      );

      final response = await ApiClient.dio.post(
        '/auth/google-login',
        data: testData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('AuthService: Response status: ${response.statusCode}');
      print('AuthService: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['user'] != null) {
        return {
          'status': 'success',
          'message': 'Google login test successful!',
          'user': response.data['user'],
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Unexpected response format',
          'data': response.data,
          'statusCode': response.statusCode,
        };
      }
    } on DioException catch (e) {
      print('AuthService: DioException in test: ${e.message}');
      print('AuthService: Status code: ${e.response?.statusCode}');
      print('AuthService: Response data: ${e.response?.data}');

      return {
        'status': 'error',
        'message': 'DioException: ${e.message}',
        'statusCode': e.response?.statusCode,
        'data': e.response?.data,
      };
    } catch (e) {
      print('AuthService: Unexpected error in test: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }
}
