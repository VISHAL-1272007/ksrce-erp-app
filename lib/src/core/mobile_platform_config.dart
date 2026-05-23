/// Mobile Platform Configuration Service
/// Handles platform-specific initialization and features for Android/iOS

class MobilePlatformConfig {
  static const String appName = 'KSRCE ERP';
  static const String packageName = 'com.ksrce.erp';
  
  // iOS specific
  static const String iosBundleId = 'com.ksrce.erp';
  static const String iosMinVersion = '11.0';
  static const String iosTeamId = 'YOUR_TEAM_ID'; // Add your Apple Team ID

  // Android specific
  static const String androidMinSdk = '21'; // Android 5.0+
  static const String androidTargetSdk = '34';
  static const String androidNamespace = 'com.ksrce.erp';

  // App versioning
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Permissions needed
  static const List<String> androidPermissions = [
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.POST_NOTIFICATIONS', // Android 13+
  ];

  static const List<String> iosPermissions = [
    'NSCameraUsageDescription',
    'NSPhotoLibraryUsageDescription',
    'NSPhotoLibraryAddOnlyUsageDescription',
    'NSLocalNetworkUsageDescription',
  ];

  // Firebase configuration for mobile
  static const Map<String, dynamic> firebaseConfig = {
    'ios': {
      'googleAppId': 'YOUR_GOOGLE_APP_ID',
      'gcmSenderId': 'YOUR_GCM_SENDER_ID',
      'apiKey': 'YOUR_API_KEY',
      'projectId': 'YOUR_PROJECT_ID',
      'storageBucket': 'YOUR_STORAGE_BUCKET',
      'databaseUrl': 'YOUR_DATABASE_URL',
    },
    'android': {
      'projectId': 'YOUR_PROJECT_ID',
      'apiKey': 'YOUR_API_KEY',
      'appId': 'YOUR_APP_ID',
      'storageBucket': 'YOUR_STORAGE_BUCKET',
      'databaseUrl': 'YOUR_DATABASE_URL',
      'gcmSenderId': 'YOUR_GCM_SENDER_ID',
    },
  };
}
