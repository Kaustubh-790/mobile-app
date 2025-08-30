// providers/services_provider.dart
import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';

class ServicesProvider with ChangeNotifier {
  List<ServiceModel> _popularServices = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceModel> get popularServices => _popularServices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch popular services from the API
  Future<void> fetchPopularServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _popularServices = await ApiService.getPopularServices();
      _error = null;
      print(
        'ServicesProvider: Successfully loaded ${_popularServices.length} popular services',
      );
    } catch (e) {
      _error = e.toString();
      _popularServices = [];
      print('ServicesProvider: Error loading popular services - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh popular services
  Future<void> refreshPopularServices() async {
    await fetchPopularServices();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
