/// API Configuration for KSRCE ERP
class ApiConfig {
  // Base URL for API endpoints
  // Change this to your actual backend server URL
  static const String baseUrl = 'https://ksrce-erp-app.onrender.com';
  
  // Or use environment-specific URLs
  static const String devBaseUrl = 'http://localhost:8000';
  static const String prodBaseUrl = 'https://ksrce-erp-app.onrender.com';
  
  // API Endpoints
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String logoutEndpoint = '$baseUrl/auth/logout';
  static const String studentDataEndpoint = '$baseUrl/students';
  static const String attendanceEndpoint = '$baseUrl/attendance';
  static const String assignmentsEndpoint = '$baseUrl/assignments';
  static const String timetableEndpoint = '$baseUrl/timetable';
  static const String notificationsEndpoint = '$baseUrl/notifications';
  

  /// Get the appropriate base URL based on environment
  static String getBaseUrl({bool isProd = true}) {
    return isProd ? prodBaseUrl : devBaseUrl;
  }
}
