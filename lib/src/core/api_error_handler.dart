/// API Error Handler
class ApiErrorHandler {
  /// Parse HTTP error codes and return user-friendly messages
  static String getErrorMessage(int statusCode, String? responseBody) {
    switch (statusCode) {
      case 404:
        return 'API endpoint not found (404). Your backend server may not be running or is incorrectly configured.';
      case 500:
        return 'Server error (500). The backend server encountered an issue.';
      case 503:
        return 'Service unavailable (503). The backend server is temporarily down.';
      case 401:
        return 'Unauthorized (401). Invalid credentials.';
      case 403:
        return 'Forbidden (403). You do not have permission to access this resource.';
      default:
        return 'Request failed with status code: $statusCode';
    }
  }

  /// Determine if an error is retrievable or fatal
  static bool isRecoverable(dynamic error) {
    final message = error.toString().toLowerCase();
    // Connection errors are usually recoverable
    return message.contains('failed') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket');
  }

  /// Get a suggestion message for 404 errors
  static String get error404Suggestion {
    return 'Please ensure:\n'
        '1. Backend server is running\n'
        '2. API endpoint URL is correct\n'
        '3. Server is accessible at http://localhost:8080';
  }
}
