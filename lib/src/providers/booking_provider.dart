import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/cart_item.dart';
import '../api/booking_service.dart' as api;
import '../providers/auth_provider.dart';
import '../api/api_client.dart';

class BookingProvider extends ChangeNotifier {
  List<Booking> _myBookings = [];
  Booking? _currentBooking;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Booking> get myBookings => _myBookings;
  Booking? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all bookings for the current user
  Future<void> fetchMyBookings() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if user is authenticated
      final authProvider = AuthProvider();
      print('BookingProvider: Checking authentication state...');
      print(
        'BookingProvider: isAuthenticated: ${authProvider.isAuthenticated}',
      );
      print(
        'BookingProvider: authToken: ${authProvider.authToken != null ? "Present" : "Missing"}',
      );
      print(
        'BookingProvider: currentUser: ${authProvider.currentUser?.name ?? "None"}',
      );

      if (!authProvider.isAuthenticated) {
        throw Exception('User not authenticated. Please log in again.');
      }

      // Get fresh ID token from Firebase before making API call
      print('BookingProvider: Getting fresh ID token from Firebase...');
      final freshToken = await authProvider.getFreshIdToken();
      
      if (freshToken != null) {
        print('BookingProvider: Setting fresh auth token in API client...');
        ApiClient().setAuthToken(freshToken);
      } else {
        print('BookingProvider: Warning - No auth token available');
        throw Exception(
          'Authentication token is missing. Please log in again.',
        );
      }

      print('BookingProvider: Making API call to fetch bookings...');

      // Check if user Firebase UID is available
      final userId = authProvider.currentUser?.firebaseUid;
      if (userId == null || userId.isEmpty) {
        print('BookingProvider: Warning - Firebase UID is not available');
        throw Exception('User profile not fully loaded. Please try again.');
      }

      print('BookingProvider: Using Firebase UID: $userId');
      final bookings = await api.BookingService.getMyBookings(userId);
      _myBookings = bookings;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('BookingProvider: Error in fetchMyBookings: $e');
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Create a new booking from cart items
  Future<Booking?> createBooking(
    List<CartItem> cartItems,
    double total, {
    required String userId,
    required Map<String, dynamic> userProfile,
    required String cartId,
    String? address,
    String? notes,
    DateTime? bookingDate,
    String? bookingTime,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final booking = await api.BookingService.createBooking(
        cartItems,
        total,
        userId: userId,
        userProfile: userProfile,
        cartId: cartId,
        address: address,
        notes: notes,
        bookingDate: bookingDate,
        bookingTime: bookingTime,
      );

      // Save as current booking
      _currentBooking = booking;

      // Add to my bookings list
      _myBookings.insert(0, booking);

      _setLoading(false);
      notifyListeners();

      return booking;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Get a specific booking by ID
  Future<Booking?> getBookingById(String id) async {
    try {
      _setLoading(true);
      _clearError();

      final booking = await api.BookingService.getBookingById(id);

      _setLoading(false);
      notifyListeners();

      return booking;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Update booking status
  Future<Booking?> updateBookingStatus(String bookingId, String status) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedBooking = await api.BookingService.updateBookingStatus(
        bookingId,
        status,
      );

      // Update in my bookings list
      final index = _myBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _myBookings[index] = updatedBooking;
      }

      // Update current booking if it's the same one
      if (_currentBooking?.id == bookingId) {
        _currentBooking = updatedBooking;
      }

      _setLoading(false);
      notifyListeners();

      return updatedBooking;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await api.BookingService.cancelBooking(bookingId);

      if (success) {
        // Remove from my bookings list
        _myBookings.removeWhere((b) => b.id == bookingId);

        // Clear current booking if it's the same one
        if (_currentBooking?.id == bookingId) {
          _currentBooking = null;
        }
      }

      _setLoading(false);
      notifyListeners();

      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Cancel a booking with reason and message
  Future<bool> cancelBookingWithReason(
    String bookingId,
    String reason,
    String? message,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await api.BookingService.cancelBookingWithReason(
        bookingId,
        reason,
        message,
      );

      if (success) {
        // Remove from my bookings list
        _myBookings.removeWhere((b) => b.id == bookingId);

        // Clear current booking if it's the same one
        if (_currentBooking?.id == bookingId) {
          _currentBooking = null;
        }
      }

      _setLoading(false);
      notifyListeners();

      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Rate a service
  Future<bool> rateService(
    String bookingId,
    int serviceIndex,
    double rating,
    String? review,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await api.BookingService.rateService(
        bookingId,
        serviceIndex,
        rating,
        review,
      );

      if (success) {
        // Update the local booking data
        final bookingIndex = _myBookings.indexWhere((b) => b.id == bookingId);
        if (bookingIndex != -1) {
          final booking = _myBookings[bookingIndex];
          final services = List<BookingService>.from(booking.services);

          if (serviceIndex < services.length) {
            services[serviceIndex] = services[serviceIndex].copyWith(
              serviceRating: rating,
              serviceReview: review,
            );

            final updatedBooking = booking.copyWith(services: services);
            _myBookings[bookingIndex] = updatedBooking;

            // Update current booking if it's the same
            if (_currentBooking?.id == bookingId) {
              _currentBooking = updatedBooking;
            }
          }
        }
      }

      _setLoading(false);
      notifyListeners();

      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Reschedule a service
  Future<bool> rescheduleService(
    String bookingId,
    int serviceIndex,
    DateTime newDate,
    String newTime,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await api.BookingService.rescheduleService(
        bookingId,
        serviceIndex,
        newDate,
        newTime,
      );

      if (success) {
        // Update the local booking data
        final bookingIndex = _myBookings.indexWhere((b) => b.id == bookingId);
        if (bookingIndex != -1) {
          final booking = _myBookings[bookingIndex];
          final services = List<BookingService>.from(booking.services);

          if (serviceIndex < services.length) {
            final currentService = services[serviceIndex];
            services[serviceIndex] = currentService.copyWith(
              rescheduleCount: currentService.rescheduleCount + 1,
              rescheduledDate: newDate,
              rescheduledTime: newTime,
              status: 'rescheduled',
            );

            final updatedBooking = booking.copyWith(services: services);
            _myBookings[bookingIndex] = updatedBooking;

            // Update current booking if it's the same
            if (_currentBooking?.id == bookingId) {
              _currentBooking = updatedBooking;
            }
          }
        }
      }

      _setLoading(false);
      notifyListeners();

      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Reschedule a booking (legacy method - use rescheduleService instead)
  @Deprecated('Use rescheduleService instead')
  Future<Booking?> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    String newTime,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      // Use the new rescheduleService method
      final success = await rescheduleService(bookingId, 0, newDate, newTime);

      if (success) {
        // Get the updated booking
        final updatedBooking = await getBookingById(bookingId);
        _setLoading(false);
        notifyListeners();
        return updatedBooking;
      } else {
        _setLoading(false);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Set current booking
  void setCurrentBooking(Booking? booking) {
    _currentBooking = booking;
    notifyListeners();
  }

  /// Clear current booking
  void clearCurrentBooking() {
    _currentBooking = null;
    notifyListeners();
  }

  /// Clear all bookings
  void clearBookings() {
    _myBookings.clear();
    _currentBooking = null;
    notifyListeners();
  }

  /// Get booking by ID from local list
  Booking? getBookingFromList(String id) {
    try {
      return _myBookings.firstWhere((booking) => booking.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get pending bookings
  List<Booking> get pendingBookings {
    return _myBookings.where((booking) => booking.status == 'pending').toList();
  }

  /// Get confirmed bookings
  List<Booking> get confirmedBookings {
    return _myBookings
        .where((booking) => booking.status == 'confirmed')
        .toList();
  }

  /// Get completed bookings
  List<Booking> get completedBookings {
    return _myBookings
        .where((booking) => booking.status == 'completed')
        .toList();
  }

  /// Get cancelled bookings
  List<Booking> get cancelledBookings {
    return _myBookings
        .where((booking) => booking.status == 'cancelled')
        .toList();
  }

  /// Get rescheduled bookings
  List<Booking> get rescheduledBookings {
    return _myBookings
        .where((booking) => booking.status == 'rescheduled')
        .toList();
  }

  /// Get bookings by status
  List<Booking> getBookingsByStatus(String status) {
    return _myBookings.where((booking) => booking.status == status).toList();
  }

  /// Get total amount of all bookings
  double get totalBookingsAmount {
    return _myBookings.fold(0.0, (sum, booking) => sum + booking.totalAmount);
  }

  /// Get total number of bookings
  int get totalBookingsCount => _myBookings.length;

  /// Check if user has any bookings
  bool get hasBookings => _myBookings.isNotEmpty;

  /// Update payment status for a booking
  Future<bool> updatePaymentStatus(
    String bookingId,
    String paymentStatus,
    String paymentMethod,
    String cardLast4,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await api.BookingService.updatePaymentStatus(
        bookingId,
        paymentStatus,
        paymentMethod,
        cardLast4,
      );

      if (success) {
        // Update local booking data
        final bookingIndex = _myBookings.indexWhere((b) => b.id == bookingId);
        if (bookingIndex != -1) {
          final updatedBooking = _myBookings[bookingIndex].copyWith(
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod,
            cardLast4: cardLast4,
          );
          _myBookings[bookingIndex] = updatedBooking;

          // Update current booking if it's the same
          if (_currentBooking?.id == bookingId) {
            _currentBooking = updatedBooking;
          }
        }
      }

      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Check if user has pending bookings
  bool get hasPendingBookings => pendingBookings.isNotEmpty;

  /// Check if user has confirmed bookings
  bool get hasConfirmedBookings => confirmedBookings.isNotEmpty;

  /// Check if user has completed bookings
  bool get hasCompletedBookings => completedBookings.isNotEmpty;

  /// Get cancellation details for a booking
  Future<Map<String, dynamic>?> getCancellationDetails(String bookingId) async {
    try {
      _setLoading(true);
      _clearError();

      final details = await api.BookingService.getCancellationDetails(
        bookingId,
      );

      _setLoading(false);
      notifyListeners();

      return details;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }

  /// Clear error manually
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // No custom disposal logic needed
}
