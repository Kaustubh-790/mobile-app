import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../api/api_client.dart';
import '../models/user.dart' as app_user;
import '../models/user.dart';

class PhoneAuthService {
  static final PhoneAuthService _instance = PhoneAuthService._internal();
  factory PhoneAuthService() => _instance;
  PhoneAuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      // Format phone number to include country code if not present
      final formattedPhone = phoneNumber.startsWith('+91')
          ? phoneNumber
          : '+91$phoneNumber';

      // Set up reCAPTCHA verifier
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
              // Auto-verification completed (Android only)
              print('PhoneAuthService: Auto-verification completed');
            },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          print('PhoneAuthService: Verification failed: ${e.message}');
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('PhoneAuthService: OTP code sent to $formattedPhone');
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('PhoneAuthService: Auto-retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );

      // Wait a bit for the code to be sent
      await Future.delayed(const Duration(seconds: 2));

      if (_verificationId == null) {
        throw Exception('Failed to send OTP. Please try again.');
      }

      return {
        'success': true,
        'message': 'OTP sent successfully',
        'phoneNumber': formattedPhone,
      };
    } catch (e) {
      print('PhoneAuthService: Error sending OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP and complete authentication
  Future<Map<String, dynamic>> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception(
          'No OTP confirmation available. Please send OTP first.',
        );
      }

      // Create credential with OTP
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign in with credential
      firebase_auth.UserCredential? userCredential;
      firebase_auth.User? user;

      try {
        userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user;
      } catch (firebaseError) {
        print('PhoneAuthService: Firebase sign-in error: $firebaseError');
        // Check if this is a type casting error
        if (firebaseError.toString().contains('PigeonUserDetails') ||
            firebaseError.toString().contains('type cast')) {
          print(
            'PhoneAuthService: Detected type casting error, attempting recovery...',
          );
          // Try to get the current user if available
          user = _auth.currentUser;
          if (user == null) {
            throw Exception(
              'Firebase authentication failed due to type casting issue: $firebaseError',
            );
          }
        } else {
          throw Exception('Firebase authentication failed: $firebaseError');
        }
      }

      if (user == null) {
        throw Exception('Failed to authenticate user');
      }

      // Get Firebase ID token
      String? idToken;
      try {
        idToken = await user.getIdToken();
      } catch (tokenError) {
        print('PhoneAuthService: Error getting ID token: $tokenError');
        // If we can't get the token, we can still proceed with the user object
        idToken = null;
      }

      if (idToken == null) {
        print(
          'PhoneAuthService: Warning: Could not get Firebase ID token, proceeding without it',
        );
      }

      // Call backend to ensure user exists and get user data
      final response = await _handleBackendSync(user, idToken ?? '');

      return {
        'success': true,
        'message': 'Phone authentication successful',
        'user': response['user'],
        'firebaseToken': idToken,
        'requiresProfileCompletion':
            response['requiresProfileCompletion'] ?? false,
      };
    } catch (e) {
      print('PhoneAuthService: Error verifying OTP: $e');

      // Provide more specific error messages for type casting issues
      if (e.toString().contains('PigeonUserDetails')) {
        print(
          'PhoneAuthService: Detected PigeonUserDetails error - this is a Firebase type casting issue',
        );
        throw Exception(
          'Authentication completed but encountered a data type issue. Please try again or contact support.',
        );
      } else if (e.toString().contains('type cast')) {
        print('PhoneAuthService: Detected type casting error');
        throw Exception(
          'Authentication completed but encountered a data processing issue. Please try again.',
        );
      } else {
        throw Exception('Failed to verify OTP: $e');
      }
    }
  }

  /// Handle backend synchronization for phone authentication
  // Future<Map<String, dynamic>> _handleBackendSync(
  //   firebase_auth.User user,
  //   String idToken,
  // ) async {
  //   try {
  //     final phone = user.phoneNumber ?? '';
  //     if (phone.isEmpty) {
  //       throw Exception('Phone number not available from Firebase');
  //     }

  //     // Call backend phone login endpoint
  //     final response = await ApiClient.dio.post(
  //       '/auth/phone-login',
  //       data: {'phone': phone, 'firebaseUid': user.uid},
  //     );

  //     print('PhoneAuthService: Backend response: ${response.data}');
  //     print('PhoneAuthService: Response type: ${response.data.runtimeType}');

  //     // Handle different response structures
  //     dynamic userData;
  //     if (response.data['user'] != null) {
  //       userData = response.data['user'];
  //     } else if (response.data is List) {
  //       // If response is a list, take the first item
  //       userData = response.data.isNotEmpty ? response.data.first : null;
  //     } else {
  //       // If response is the user object directly
  //       userData = response.data;
  //     }

  //     if (userData != null) {
  //       try {
  //         // Ensure userData is a Map
  //         if (userData is Map<String, dynamic>) {
  //           return {
  //             'user': app_user.User.fromJson(userData),
  //             'requiresProfileCompletion':
  //                 !(userData['profileCompleted'] ?? false),
  //           };
  //         } else {
  //           print(
  //             'PhoneAuthService: Unexpected userData type: ${userData.runtimeType}',
  //           );
  //           throw Exception('Invalid user data format');
  //         }
  //       } catch (parseError) {
  //         print('PhoneAuthService: User data parsing error: $parseError');
  //         print('PhoneAuthService: Raw user data: $userData');
  //         // Fall back to creating a basic user object
  //         return {
  //           'user': app_user.User(
  //             id: user.uid,
  //             name: 'User-${user.uid.substring(0, 6)}',
  //             email: null,
  //             phone: phone,
  //             firebaseUid: user.uid,
  //             profileCompleted: false,
  //             role: 'user',
  //           ),
  //           'requiresProfileCompletion': true,
  //         };
  //       }
  //     } else {
  //       throw Exception(
  //         'Backend sync failed: ${response.data['message'] ?? 'No user data received'}',
  //       );
  //     }
  //   } catch (e) {
  //     print('PhoneAuthService: Backend sync error: $e');
  //     // If backend sync fails, create a basic user object
  //     final phone = user.phoneNumber ?? '';
  //     return {
  //       'user': app_user.User(
  //         id: user.uid,
  //         name: 'User-${user.uid.substring(0, 6)}',
  //         email: null,
  //         phone: phone,
  //         firebaseUid: user.uid,
  //         profileCompleted: false,
  //         role: 'user',
  //       ),
  //       'requiresProfileCompletion': true,
  //     };
  //   }
  // }

  /// Handle backend synchronization for phone authentication
  Future<Map<String, dynamic>> _handleBackendSync(
    firebase_auth.User user,
    String idToken,
  ) async {
    try {
      print('PhoneAuthService: Attempting backend sync...');

      final phone = user.phoneNumber ?? '';
      if (phone.isEmpty) {
        throw Exception('Phone number not available from Firebase');
      }

      // Call backend phone login endpoint
      final response = await ApiClient.dio.post(
        '/auth/phone-login',
        data: {'phone': phone, 'firebaseUid': user.uid},
      );

      print('PhoneAuthService: Backend response: ${response.data}');
      print('PhoneAuthService: Response type: ${response.data.runtimeType}');

      // Add additional type checking and error handling
      if (response.data == null) {
        throw Exception('Backend response is null');
      }

      // Ensure response.data is a Map
      if (response.data is! Map<String, dynamic>) {
        print(
          'PhoneAuthService: Response data is not a Map: ${response.data.runtimeType}',
        );
        // If it's a List, try to extract the first item
        if (response.data is List) {
          final listData = response.data as List;
          if (listData.isNotEmpty && listData.first is Map<String, dynamic>) {
            response.data = listData.first;
          } else {
            throw Exception(
              'Response data is a List but contains no valid user data',
            );
          }
        } else {
          throw Exception(
            'Invalid response format: expected Map but got ${response.data.runtimeType}',
          );
        }
      }

      // Based on your Postman response, the format is: { "user": { user_data } }
      if (response.data.containsKey('user')) {
        final userData = response.data['user'];

        if (userData is Map<String, dynamic>) {
          // Convert MongoDB _id to id for Flutter User model
          final userMap = Map<String, dynamic>.from(userData);

          // Handle MongoDB _id field
          if (userMap.containsKey('_id') && !userMap.containsKey('id')) {
            userMap['id'] = userMap['_id'].toString();
          }

          // Ensure all required fields exist with proper types
          userMap['id'] =
              userMap['id']?.toString() ??
              userMap['_id']?.toString() ??
              user.uid;
          userMap['name'] =
              userMap['name']?.toString() ?? 'User-${user.uid.substring(0, 6)}';
          userMap['firebaseUid'] =
              userMap['firebaseUid']?.toString() ?? user.uid;
          userMap['profileCompleted'] = userMap['profileCompleted'] ?? false;
          userMap['role'] = userMap['role']?.toString() ?? 'user';
          userMap['numberOfBookings'] = userMap['numberOfBookings'] ?? 0;
          userMap['hasFirstBooking'] = userMap['hasFirstBooking'] ?? false;

          // Convert phone and email to strings if they exist
          if (userMap['phone'] != null) {
            userMap['phone'] = userMap['phone'].toString();
          }
          if (userMap['email'] != null) {
            userMap['email'] = userMap['email'].toString();
          }

          print('PhoneAuthService: Processed user map: $userMap');

          try {
            final userObject = app_user.User.fromJson(userMap);
            print('PhoneAuthService: Successfully created User object');

            return {
              'user': userObject,
              'requiresProfileCompletion':
                  !(userMap['profileCompleted'] ?? false),
            };
          } catch (userCreationError) {
            print(
              'PhoneAuthService: Error creating User object: $userCreationError',
            );

            // Create User object manually if fromJson fails
            return {
              'user': User(
                id: userMap['id']?.toString() ?? user.uid,
                name:
                    userMap['name']?.toString() ??
                    'User-${user.uid.substring(0, 6)}',
                email: userMap['email']?.toString(),
                phone: userMap['phone']?.toString(),
                firebaseUid: userMap['firebaseUid']?.toString() ?? user.uid,
                profileCompleted: userMap['profileCompleted'] ?? false,
                role: userMap['role']?.toString() ?? 'user',
                numberOfBookings: userMap['numberOfBookings'] ?? 0,
                hasFirstBooking: userMap['hasFirstBooking'] ?? false,
              ),
              'requiresProfileCompletion':
                  !(userMap['profileCompleted'] ?? false),
            };
          }
        } else {
          throw Exception(
            'User data is not a valid Map: ${userData.runtimeType}',
          );
        }
      } else {
        // If the response doesn't have a 'user' key, try to use the response directly
        if (response.data is Map<String, dynamic>) {
          final userMap = Map<String, dynamic>.from(response.data);

          // Handle MongoDB _id field
          if (userMap.containsKey('_id') && !userMap.containsKey('id')) {
            userMap['id'] = userMap['_id'].toString();
          }

          // Ensure all required fields exist with proper types
          userMap['id'] =
              userMap['id']?.toString() ??
              userMap['_id']?.toString() ??
              user.uid;
          userMap['name'] =
              userMap['name']?.toString() ?? 'User-${user.uid.substring(0, 6)}';
          userMap['firebaseUid'] =
              userMap['firebaseUid']?.toString() ?? user.uid;
          userMap['profileCompleted'] = userMap['profileCompleted'] ?? false;
          userMap['role'] = userMap['role']?.toString() ?? 'user';
          userMap['numberOfBookings'] = userMap['numberOfBookings'] ?? 0;
          userMap['hasFirstBooking'] = userMap['hasFirstBooking'] ?? false;

          // Convert phone and email to strings if they exist
          if (userMap['phone'] != null) {
            userMap['phone'] = userMap['phone'].toString();
          }
          if (userMap['email'] != null) {
            userMap['email'] = userMap['email'].toString();
          }

          try {
            final userObject = app_user.User.fromJson(userMap);
            print(
              'PhoneAuthService: Successfully created User object from direct response',
            );

            return {
              'user': userObject,
              'requiresProfileCompletion':
                  !(userMap['profileCompleted'] ?? false),
            };
          } catch (userCreationError) {
            print(
              'PhoneAuthService: Error creating User object from direct response: $userCreationError',
            );

            // Create User object manually if fromJson fails
            return {
              'user': User(
                id: userMap['id']?.toString() ?? user.uid,
                name:
                    userMap['name']?.toString() ??
                    'User-${user.uid.substring(0, 6)}',
                email: userMap['email']?.toString(),
                phone: userMap['phone']?.toString(),
                firebaseUid: userMap['firebaseUid']?.toString() ?? user.uid,
                profileCompleted: userMap['profileCompleted'] ?? false,
                role: userMap['role']?.toString() ?? 'user',
                numberOfBookings: userMap['numberOfBookings'] ?? 0,
                hasFirstBooking: userMap['hasFirstBooking'] ?? false,
              ),
              'requiresProfileCompletion':
                  !(userMap['profileCompleted'] ?? false),
            };
          }
        } else {
          throw Exception(
            'Invalid response format: missing user field or not a Map',
          );
        }
      }
    } catch (e) {
      print('PhoneAuthService: Backend sync error: $e');

      // If backend sync fails, create a basic user object
      final phone = user.phoneNumber ?? '';
      return {
        'user': User(
          id: user.uid,
          name: 'User-${user.uid.substring(0, 6)}',
          email: user.email,
          phone: phone,
          firebaseUid: user.uid,
          profileCompleted: false,
          role: 'user',
          numberOfBookings: 0,
          hasFirstBooking: false,
        ),
        'requiresProfileCompletion': true,
      };
    }
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    try {
      // Clear previous verification data
      _verificationId = null;
      _resendToken = null;

      // Send new OTP
      return await sendOTP(phoneNumber);
    } catch (e) {
      print('PhoneAuthService: Error resending OTP: $e');
      throw Exception('Failed to resend OTP: $e');
    }
  }

  /// Clear verification data
  void clearVerificationData() {
    _verificationId = null;
    _resendToken = null;
  }

  /// Clear Firebase cache and force refresh
  Future<void> clearFirebaseCache() async {
    try {
      print('PhoneAuthService: Clearing Firebase cache...');
      // Sign out to clear any cached user data
      await _auth.signOut();
      print('PhoneAuthService: Firebase cache cleared successfully');
    } catch (e) {
      print('PhoneAuthService: Error clearing Firebase cache: $e');
    }
  }

  /// Check if OTP verification is available
  bool get hasVerificationId => _verificationId != null;
}
