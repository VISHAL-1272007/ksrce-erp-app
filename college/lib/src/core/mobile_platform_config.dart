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

}
