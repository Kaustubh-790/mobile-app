import 'package:dio/dio.dart';
import '../models/booking.dart';

class PaymentService {
  final Dio _dio;

  PaymentService(this._dio);

  /// Process payment for a booking
  Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required String cartId,
    required double amount,
    required String paymentMethod,
    required String cardLast4,
    Map<String, dynamic>? transactionDetails,
  }) async {
    try {
      print('PaymentService: Processing payment for booking $bookingId');

      final paymentData = {
        'bookingId': bookingId,
        'cartId': cartId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'cardLast4': cardLast4,
        if (transactionDetails != null)
          'transactionDetails': transactionDetails,
      };

      print('PaymentService: Payment data: $paymentData');

      final response = await _dio.post('/payments', data: paymentData);

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data;
        print(
          'PaymentService: Payment processed successfully: ${responseData['paymentId']}',
        );
        return responseData;
      } else {
        throw Exception('Failed to process payment');
      }
    } catch (e) {
      print('PaymentService: Exception while processing payment - $e');

      if (e is DioException) {
        print('PaymentService: DioException type: ${e.type}');
        print('PaymentService: DioException message: ${e.message}');

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
                'Invalid payment data. Please check your information.',
              );
            } else if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            } else if (e.response?.statusCode == 402) {
              throw Exception('Payment failed. Please try again.');
            } else if (e.response?.statusCode == 404) {
              throw Exception(
                'Booking not found. Please refresh and try again.',
              );
            }
            break;
          default:
            throw Exception('Network error occurred. Please try again.');
        }
      }

      throw Exception('Failed to process payment: $e');
    }
  }

  /// Get payment details by booking ID
  Future<Map<String, dynamic>> getPaymentByBookingId(String bookingId) async {
    try {
      print('PaymentService: Fetching payment for booking $bookingId');

      final response = await _dio.get('/payments/booking/$bookingId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        print('PaymentService: Payment details retrieved successfully');
        return responseData;
      } else {
        throw Exception('Failed to retrieve payment details');
      }
    } catch (e) {
      print('PaymentService: Exception while fetching payment - $e');

      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 404) {
              throw Exception('Payment not found for this booking');
            }
            break;
          default:
            throw Exception('Failed to retrieve payment details');
        }
      }

      throw Exception('Failed to retrieve payment details: $e');
    }
  }

  /// Get all payments for the current user
  Future<List<Map<String, dynamic>>> getUserPayments(String userId) async {
    try {
      print('PaymentService: Fetching payments for user $userId');

      final response = await _dio.get('/payments/user/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = response.data;
        print(
          'PaymentService: User payments retrieved successfully: ${responseData.length} payments',
        );
        return responseData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to retrieve user payments');
      }
    } catch (e) {
      print('PaymentService: Exception while fetching user payments - $e');

      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.badResponse:
            if (e.response?.statusCode == 401) {
              throw Exception('Authentication required. Please log in again.');
            }
            break;
          default:
            throw Exception('Failed to retrieve user payments');
        }
      }

      throw Exception('Failed to retrieve user payments: $e');
    }
  }
}
