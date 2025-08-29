import 'package:dio/dio.dart';

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
    return BaseOptions(
      baseUrl: "http://localhost:3000/api",
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );
  }

  /// Sets the Authorization header with the provided token
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clears the Authorization header
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }

  /// Gets the current Dio instance
  Dio get instance => dio;
}
