class EnvConfig {
  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyB4DppYbk-gAX_uwp7r5jZk9MlAp_xqs0o',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:636320315608:web:4aa582ef28e86aaf0bffad',
  );

  static const String firebaseSenderId = String.fromEnvironment(
    'FIREBASE_SENDER_ID',
    defaultValue: '636320315608',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'my-app-e802a',
  );

  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'my-app-e802a.firebaseapp.com',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'my-app-e802a.firebasestorage.app',
  );

  static const String firebaseIosClientId = String.fromEnvironment(
    'FIREBASE_IOS_CLIENT_ID',
    defaultValue:
        '636320315608-d6insd65sr3c1ef6lrui2q2pa1rdoo8n.apps.googleusercontent.com',
  );

  static const String firebaseAndroidClientId = String.fromEnvironment(
    'FIREBASE_ANDROID_CLIENT_ID',
    defaultValue:
        '636320315608-d6insd65sr3c1ef6lrui2q2pa1rdoo8n.apps.googleusercontent.com',
  );

  // Backend API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kariighar.onrender.com/api',
  );

  // Check if using default values (development mode)
  static bool get isDevelopment {
    return firebaseApiKey == 'YOUR_API_KEY' ||
        firebaseAppId == 'YOUR_APP_ID' ||
        firebaseProjectId == 'YOUR_PROJECT_ID';
  }

  // Validate configuration
  static bool get isValid {
    return firebaseApiKey.isNotEmpty &&
        firebaseApiKey != 'YOUR_API_KEY' &&
        firebaseAppId.isNotEmpty &&
        firebaseAppId != 'YOUR_APP_ID' &&
        firebaseProjectId.isNotEmpty &&
        firebaseProjectId != 'YOUR_PROJECT_ID';
  }
}
