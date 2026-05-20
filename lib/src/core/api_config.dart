/// API Configuration for KSRCE ERP
class ApiConfig {
  // Base URL for API endpoints
  // Change this to your actual backend server URL
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Or use environment-specific URLs
  static const String devBaseUrl = 'http://localhost:8080/api';
  static const String prodBaseUrl = 'https://api.ksrce-erp.com/api';
  
  // API Endpoints
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String logoutEndpoint = '$baseUrl/auth/logout';
  static const String studentDataEndpoint = '$baseUrl/students';
  static const String attendanceEndpoint = '$baseUrl/attendance';
  static const String assignmentsEndpoint = '$baseUrl/assignments';
  
  /// Get the appropriate base URL based on environment
  static String getBaseUrl({bool isProd = false}) {
    return isProd ? prodBaseUrl : devBaseUrl;
  }
}
