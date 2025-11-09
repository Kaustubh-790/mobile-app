import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/service_model.dart';

class ApiService {
  static final ApiClient _apiClient = ApiClient();

  /// Fetch popular services from the backend
  static Future<List<ServiceModel>> getPopularServices() async {
    try {
      print('ApiService: Fetching popular services...');

      final response = await _apiClient.instance.get('/services/popular');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final services = data
            .map((json) => ServiceModel.fromJson(json))
            .toList();

        print(
          'ApiService: Successfully fetched ${services.length} popular services',
        );
        return services;
      } else {
        print(
          'ApiService: Error fetching services - Status: ${response.statusCode}',
        );
        throw Exception('Failed to load popular services');
      }
    } catch (e) {
      print('ApiService: Exception while fetching popular services - $e');

      if (e is DioException) {
        print('ApiService: DioException type: ${e.type}');
        print('ApiService: DioException message: ${e.message}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Unable to connect to server. Please try again later.',
            );
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to load popular services: $e');
    }
  }

  /// Fetch all services from the backend
  static Future<List<ServiceModel>> getAllServices() async {
    try {
      print('ApiService: Fetching all services...');

      final response = await _apiClient.instance.get('/services');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final services = data
            .map((json) => ServiceModel.fromJson(json))
            .toList();

        print(
          'ApiService: Successfully fetched ${services.length} services',
        );
        return services;
      } else {
        print(
          'ApiService: Error fetching services - Status: ${response.statusCode}',
        );
        throw Exception('Failed to load services');
      }
    } catch (e) {
      print('ApiService: Exception while fetching services - $e');

      if (e is DioException) {
        print('ApiService: DioException type: ${e.type}');
        print('ApiService: DioException message: ${e.message}');

        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            throw Exception(
              'Connection timeout. Please check your internet connection.',
            );
          case DioExceptionType.connectionError:
            throw Exception(
              'Unable to connect to server. Please try again later.',
            );
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to load services: $e');
    }
  }
}
