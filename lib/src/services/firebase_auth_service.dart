import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: null, // Let it use the default from google-services.json
  );

  /// Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  /// Get current Firebase user stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google (with proper error handling and fallback)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('FirebaseAuthService: Starting Google Sign-In...');

      // Step 1: Get Google user credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google Sign-In was cancelled'};
      }

      print('FirebaseAuthService: Google user obtained: ${googleUser.email}');

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return {'success': false, 'error': 'Failed to get Google auth tokens'};
      }

      print('FirebaseAuthService: Google auth tokens obtained');

      // Step 3: Try Firebase authentication with better error handling
      String? firebaseUid;
      String? firebaseToken;

      try {
        print('FirebaseAuthService: Attempting Firebase authentication...');

        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Use a more robust approach to handle the Firebase sign-in
        final userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          firebaseUid = userCredential.user!.uid;
          firebaseToken = await userCredential.user!.getIdToken();

          print('FirebaseAuthService: Firebase authentication successful!');
          print('FirebaseAuthService: Firebase UID: $firebaseUid');
        }
      } catch (firebaseError) {
        print(
          'FirebaseAuthService: Firebase authentication failed: $firebaseError',
        );

        // Check if user is already signed in to Firebase
        if (_auth.currentUser != null) {
          firebaseUid = _auth.currentUser!.uid;
          firebaseToken = await _auth.currentUser!.getIdToken();
          print(
            'FirebaseAuthService: Using existing Firebase user: $firebaseUid',
          );
        }
      }

      // Step 4: Prepare user data for backend sync
      final requestData = {
        'firebaseUid':
            firebaseUid ??
            googleUser.id, // Use Firebase UID or fallback to Google ID
        'name': googleUser.displayName ?? 'User',
        'email': googleUser.email,
      };

      print('FirebaseAuthService: Prepared data for backend: $requestData');

      // Step 5: Try to sync with backend
      bool backendSync = false;
      Map<String, dynamic>? backendUserData;

      try {
        print('FirebaseAuthService: Attempting backend sync...');

        final dio = Dio();
        dio.options.baseUrl = 'https://kariighar.onrender.com/api';
        dio.options.connectTimeout = const Duration(seconds: 15);
        dio.options.receiveTimeout = const Duration(seconds: 15);

        final response = await dio.post(
          '/auth/google-login',
          data: requestData,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        print(
          'FirebaseAuthService: Backend response status: ${response.statusCode}',
        );
        print('FirebaseAuthService: Backend response: ${response.data}');

        if (response.statusCode == 200 && response.data['user'] != null) {
          backendSync = true;
          backendUserData = response.data['user'];
          print('FirebaseAuthService: Backend sync successful!');
        }
      } catch (backendError) {
        print('FirebaseAuthService: Backend sync failed: $backendError');
        if (backendError is DioException) {
          print(
            'FirebaseAuthService: Status code: ${backendError.response?.statusCode}',
          );
          print(
            'FirebaseAuthService: Response data: ${backendError.response?.data}',
          );
        }
      }

      // Step 6: Return result with full user data
      final userData = backendSync && backendUserData != null
          ? backendUserData
          : {
              'id': firebaseUid ?? googleUser.id,
              'name': googleUser.displayName ?? 'User',
              'email': googleUser.email,
              'role': 'user',
              'firebaseUid': firebaseUid ?? googleUser.id,
              'profilePic': googleUser.photoUrl,
              'profileCompleted': false,
              'hasFirstBooking': false,
              'numberOfBookings': 0,
            };

      print('FirebaseAuthService: Final user data: $userData');

      return {
        'success': true,
        'user': userData,
        'message': backendSync
            ? 'Google login successful'
            : 'Google login successful (offline mode)',
        'firebaseToken': firebaseToken ?? googleAuth.idToken,
        'backendSync': backendSync,
      };
    } catch (e) {
      print('FirebaseAuthService: Google sign in failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Alternative method: Direct backend call with Google credentials
  Future<Map<String, dynamic>> signInWithGoogleDirect() async {
    try {
      print('FirebaseAuthService: Starting direct Google Sign-In...');

      // Step 1: Get Google user credentials
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google Sign-In was cancelled'};
      }

      print('FirebaseAuthService: Google user obtained: ${googleUser.email}');

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Step 3: Skip Firebase and go directly to backend
      final requestData = {
        'googleId': googleUser.id,
        'name': googleUser.displayName ?? 'User',
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
      };

      print(
        'FirebaseAuthService: Sending direct request to backend: $requestData',
      );

      final dio = Dio();
      dio.options.baseUrl = 'https://kariighar.onrender.com/api';
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);

      final response = await dio.post(
        '/auth/google-login-direct', // New endpoint for direct Google login
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['user'] != null) {
        return {
          'success': true,
          'user': response.data['user'],
          'message': 'Google login successful',
          'firebaseToken': googleAuth.idToken,
          'backendSync': true,
        };
      } else {
        throw Exception('Invalid response from backend: ${response.data}');
      }
    } catch (e) {
      print('FirebaseAuthService: Direct Google sign in failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      print('Signed out successfully');
    } catch (e) {
      print('Sign out failed: $e');
      rethrow;
    }
  }

  /// Get current user's ID token
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken(true);
      }
      return null;
    } catch (e) {
      print('Failed to get ID token: $e');
      return null;
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Get current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Get current user's display name
  String? get currentUserDisplayName => _auth.currentUser?.displayName;

  /// Get current user's photo URL
  String? get currentUserPhotoURL => _auth.currentUser?.photoURL;

  /// Test Firebase connection and get current user info
  Future<Map<String, dynamic>> testFirebaseConnection() async {
    try {
      print('FirebaseAuthService: Testing Firebase connection...');

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final idToken = await currentUser.getIdToken();
        return {
          'success': true,
          'user': {
            'uid': currentUser.uid,
            'email': currentUser.email,
            'displayName': currentUser.displayName,
            'photoURL': currentUser.photoURL,
          },
          'idToken': idToken,
          'message': 'Firebase user is signed in',
        };
      } else {
        return {'success': false, 'message': 'No Firebase user signed in'};
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Firebase connection test failed',
      };
    }
  }

  /// Retry Firebase authentication for current Google user
  Future<String?> retryFirebaseAuth() async {
    try {
      print('FirebaseAuthService: Retrying Firebase authentication...');

      // Check if we have a current Firebase user
      if (_auth.currentUser != null) {
        print(
          'FirebaseAuthService: Firebase user already exists: ${_auth.currentUser!.uid}',
        );
        return _auth.currentUser!.uid;
      }

      // Check if Google user is signed in
      final googleUser = _googleSignIn.currentUser;
      if (googleUser == null) {
        print(
          'FirebaseAuthService: No Google user found, cannot retry Firebase auth',
        );
        return null;
      }

      // Get fresh Google auth tokens
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Try Firebase sign in again with timeout
      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 10));

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        print('FirebaseAuthService: Retry successful, Firebase UID: $uid');
        return uid;
      }

      return null;
    } catch (e) {
      print('FirebaseAuthService: Retry Firebase auth failed: $e');
      return null;
    }
  }
}
