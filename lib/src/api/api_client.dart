import 'package:dio/dio.dart';
import 'dart:io';
import '../config/env_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static Dio? _dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(_createDioOptions());
  }

  static Dio get dio {
    if (_dio == null) {
      _dio = Dio(_createDioOptions());
    }
    return _dio!;
  }

  static BaseOptions _createDioOptions() {
    // Use the environment configuration for base URL
    final String baseUrl = EnvConfig.apiBaseUrl;

    print(
      'ApiClient: Using base URL: $baseUrl for ${Platform.operatingSystem}',
    );

    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-Auth-Type': 'user',
      },
    );
  }

  /// Sets the Authorization header with the provided token
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    // Also try alternative header formats that some backends expect
    dio.options.headers['X-Auth-Token'] = token;
    dio.options.headers['X-API-Key'] = token;
    print('ApiClient: Auth token set');
  }

  /// Clears the Authorization header
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
    print('ApiClient: Auth token cleared');
  }

  /// Gets the current Dio instancer
  Dio get instance => dio;

  /// Test the connection to the server
  Future<bool> testConnection() async {
    try {
      print('ApiClient: Testing connection to: ${dio.options.baseUrl}');

      // Try to connect to the root endpoint first
      final response = await dio.get(
        '/',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      print(
        'ApiClient: Connection test successful - Status: ${response.statusCode}',
      );
      print('ApiClient: Response data: ${response.data}');
      return true;
    } catch (e) {
      print('ApiClient: Connection test failed - $e');

      // Try to get more specific error information
      if (e is DioException) {
        print('ApiClient: Error type: ${e.type}');
        print('ApiClient: Error message: ${e.message}');
        print('ApiClient: Request URL: ${e.requestOptions.uri}');
        print('ApiClient: Request method: ${e.requestOptions.method}');
      }

      return false;
    }
  }
}
