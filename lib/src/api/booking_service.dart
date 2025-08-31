import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/booking.dart';
import '../models/cart_item.dart';

class BookingService {
  static final ApiClient _apiClient = ApiClient();

  /// Create a new booking from cart items
  static Future<Booking> createBooking(
    List<CartItem> items,
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
      print('BookingService: Creating booking...');

      if (items.isEmpty) {
        throw Exception('Cannot create booking with empty items');
      }

      // Use real user profile data
      final customerInfo = {
        'name': userProfile['name'] ?? 'Unknown',
        'email': userProfile['email'] ?? 'unknown@email.com',
        'phone': userProfile['phone'] ?? '+0000000000',
        'address': address ?? userProfile['address'] ?? 'Address not provided',
      };

      // Calculate total duration from services
      String calculateDuration() {
        int totalMinutes = 0;
        for (final item in items) {
          if (item.duration != null) {
            // Parse duration like "2 hours" or "30 minutes"
            final duration = item.duration!.toLowerCase();
            if (duration.contains('hour')) {
              final hours =
                  int.tryParse(duration.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
              totalMinutes += hours * 60 * item.quantity;
            } else if (duration.contains('minute')) {
              final minutes =
                  int.tryParse(duration.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
              totalMinutes += minutes * item.quantity;
            }
          }
        }

        if (totalMinutes == 0) return '2 hours'; // Default fallback

        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;

        if (hours > 0 && minutes > 0) {
          return '${hours}h ${minutes}m';
        } else if (hours > 0) {
          return '$hours hours';
        } else {
          return '$minutes minutes';
        }
      }

      // Prepare request data matching backend expectations
      final requestData = {
        'userId': userId,
        'cartId': cartId, // Use the actual cart ID from cart provider
        'services': items
            .map(
              (item) => {
                'serviceId': item.serviceId,
                'packageId': item.packageId,
                'quantity': item.quantity,
                'customizations': item.customizations ?? {},
                'price': item.price,
              },
            )
            .toList(),
        'totalAmount': total,
        'bookingDate': bookingDate?.toIso8601String(),
        'bookingTime': bookingTime,
        'customerInfo': customerInfo,
        'address': address ?? 'Default Address',
        'duration': calculateDuration(),
      };

      print('BookingService: Request data: $requestData');

      final response = await _apiClient.instance.post(
        '/bookings/cart',
        data: requestData,
        options: Options(headers: {'X-Auth-Type': 'user'}),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;
        print('BookingService: Raw response: $responseData');

        if (responseData['booking'] != null) {
          final booking = Booking.fromJson(responseData['booking']);
          print('BookingService: Booking created successfully: ${booking.id}');
          return booking;
        } else {
          throw Exception('Invalid response format: missing booking data');
        }
      } else {
        print(
          'BookingService: Error creating booking - Status: ${response.statusCode}',
        );
        throw Exception('Failed to create booking');
      }
    } catch (e) {
      print('BookingService: Exception while creating booking - $e');

      if (e is DioException) {
        print('BookingService: DioException type: ${e.type}');
        print('BookingService: DioException message: ${e.message}');

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
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 400) {
              final errorData = e.response?.data;
              if (errorData is Map<String, dynamic> &&
                  errorData['message'] != null) {
                throw Exception(errorData['message']);
              }
              throw Exception(
                'Invalid booking data. Please check your information.',
              );
            } else if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 404) {
              throw Exception('Cart not found. Please refresh your cart.');
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get all bookings for the current user
  static Future<List<Booking>> getMyBookings([String? userId]) async {
    try {
      print('BookingService: Fetching user bookings...');
      print('BookingService: Base URL: ${_apiClient.instance.options.baseUrl}');
      print('BookingService: User ID: $userId');
      print('BookingService: Headers: ${_apiClient.instance.options.headers}');

      // Use the correct endpoint based on documentation
      final endpoint = userId != null
          ? '/bookings/user/$userId'
          : '/bookings/user/me';

      print('BookingService: Using endpoint: $endpoint');
      print(
        'BookingService: Full URL: ${_apiClient.instance.options.baseUrl}$endpoint',
      );

      // Make the request with proper headers
      final response = await _apiClient.instance.get(
        endpoint,
        options: Options(headers: {'X-Auth-Type': 'user'}),
      );

      if (response.statusCode == 200) {
        // Handle the response structure from backend: { bookings: [...], pagination: {...} }
        final Map<String, dynamic> responseData = response.data;
        print('BookingService: Raw response data: $responseData');

        // Extract bookings from the response - handle both formats
        final List<dynamic> bookingsData =
            responseData['bookings'] ?? responseData;
        print('BookingService: Extracted bookings data: $bookingsData');

        final bookings = bookingsData.map((json) {
          try {
            return Booking.fromJson(json);
          } catch (e) {
            print('BookingService: Error parsing booking: $e');
            print('BookingService: Booking data: $json');
            rethrow;
          }
        }).toList();

        print(
          'BookingService: Successfully fetched ${bookings.length} bookings',
        );
        return bookings;
      } else {
        throw Exception(
          'Failed to load bookings: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('BookingService: Exception while fetching bookings - $e');

      if (e is DioException) {
        print('BookingService: DioException type: ${e.type}');
        print('BookingService: DioException message: ${e.message}');
        print('BookingService: Request URL: ${e.requestOptions.uri}');
        print('BookingService: Request headers: ${e.requestOptions.headers}');
        print('BookingService: Response status: ${e.response?.statusCode}');
        print('BookingService: Response data: ${e.response?.data}');

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
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 403) {
              throw Exception(
                'Access forbidden. Please check your authentication or contact support.',
              );
            } else if (e.response?.statusCode == 404) {
              throw Exception('User not found or no bookings available.');
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to load bookings: $e');
    }
  }

  /// Get a specific booking by ID
  static Future<Booking> getBookingById(String id) async {
    try {
      print('BookingService: Fetching booking with ID: $id');

      final response = await _apiClient.instance.get(
        '/bookings/$id',
        options: Options(headers: {'X-Auth-Type': 'user'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> bookingData = response.data;
        print('BookingService: Raw booking response: $bookingData');

        final booking = Booking.fromJson(bookingData);
        print('BookingService: Successfully fetched booking: ${booking.id}');
        return booking;
      } else {
        print(
          'BookingService: Error fetching booking - Status: ${response.statusCode}',
        );
        throw Exception('Failed to load booking');
      }
    } catch (e) {
      print('BookingService: Exception while fetching booking - $e');

      if (e is DioException) {
        print('BookingService: DioException type: ${e.type}');
        print('BookingService: DioException message: ${e.message}');

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
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 404) {
              throw Exception('Booking not found.');
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to load booking: $e');
    }
  }

  /// Update booking status
  static Future<Booking> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    try {
      print('BookingService: Updating booking status to: $status');

      final response = await _apiClient.instance.put(
        '/bookings/$bookingId/status',
        data: {'status': status},
        options: Options(headers: {'X-Auth-Type': 'user'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> bookingData = response.data;
        print('BookingService: Raw update response: $bookingData');

        final booking = Booking.fromJson(bookingData);
        print('BookingService: Successfully updated booking status');
        return booking;
      } else {
        print(
          'BookingService: Error updating booking - Status: ${response.statusCode}',
        );
        throw Exception('Failed to update booking');
      }
    } catch (e) {
      print('BookingService: Exception while updating booking - $e');

      if (e is DioException) {
        print('BookingService: DioException type: ${e.type}');
        print('BookingService: DioException message: ${e.message}');

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
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 404) {
              throw Exception('Booking not found.');
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to update booking: $e');
    }
  }

  /// Cancel a booking
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      print('BookingService: Cancelling booking: $bookingId');

      final response = await _apiClient.instance.delete(
        '/bookings/$bookingId',
        options: Options(headers: {'X-Auth-Type': 'user'}),
      );

      if (response.statusCode == 200) {
        print('BookingService: Successfully cancelled booking');
        return true;
      } else {
        print(
          'BookingService: Error cancelling booking - Status: ${response.statusCode}',
        );
        throw Exception('Failed to cancel booking');
      }
    } catch (e) {
      print('BookingService: Exception while cancelling booking - $e');

      if (e is DioException) {
        print('BookingService: DioException type: ${e.type}');
        print('BookingService: DioException message: ${e.message}');

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
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 404) {
              throw Exception('Booking not found.');
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Reschedule a booking
  static Future<Booking> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    String newTime,
  ) async {
    try {
      print('BookingService: Rescheduling booking: $bookingId');

      final response = await _apiClient.instance.put(
        '/bookings/$bookingId/status',
        data: {
          'scheduledDate': newDate.toIso8601String(),
          'scheduledTime': newTime,
        },
        options: Options(headers: {'X-Auth-Type': 'user'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> bookingData = response.data;
        print('BookingService: Raw reschedule response: $bookingData');

        final booking = Booking.fromJson(bookingData);
        print('BookingService: Successfully rescheduled booking');
        return booking;
      } else {
        print(
          'BookingService: Error rescheduling booking - Status: ${response.statusCode}',
        );
        throw Exception('Failed to reschedule booking');
      }
    } catch (e) {
      print('BookingService: Exception while rescheduling booking - $e');

      if (e is DioException) {
        print('BookingService: DioException type: ${e.type}');
        print('BookingService: DioException message: ${e.message}');

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
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 404) {
              throw Exception('Booking not found.');
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to reschedule booking: $e');
    }
  }

  /// Update payment status for a booking
  static Future<bool> updatePaymentStatus(
    String bookingId,
    String paymentStatus,
    String paymentMethod,
    String cardLast4,
  ) async {
    try {
      print('BookingService: Updating payment status for booking: $bookingId');

      final response = await _apiClient.instance.put(
        '/bookings/$bookingId/payment',
        data: {
          'paymentStatus': paymentStatus,
          'paymentMethod': paymentMethod,
          'cardLast4': cardLast4,
        },
        options: Options(headers: {'X-Auth-Type': 'user'}),
      );

      if (response.statusCode == 200) {
        print('BookingService: Successfully updated payment status');
        return true;
      } else {
        print(
          'BookingService: Error updating payment status - Status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('BookingService: Exception while updating payment status - $e');

      if (e is DioException) {
        print('BookingService: DioException type: ${e.type}');
        print('BookingService: DioException message: ${e.message}');

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
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 404) {
              throw Exception('Booking not found.');
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to update payment status: $e');
    }
  }
}
