import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Token storage keys
const _kJwtToken = 'jwt_token';
const _kTokenExpiry = 'jwt_token_expiry';

/// Production-grade HTTP client for all KSRCE ERP API calls.
///
/// Features:
/// - Automatically injects `Authorization: Bearer <token>` header
/// - Detects expired tokens and handles 401 responses
/// - Enforces a request timeout (15 s) suitable for a 30 k-user load
/// - Returns structured [ApiResponse] objects (no raw exceptions to callers)
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const Duration _timeout = Duration(seconds: 15);

  // ─── Token Management ────────────────────────────────────────────────────

  /// Persist an access token after a successful login.
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kJwtToken, token);
      // Store the expiry 55 minutes from now (typical JWT = 60 min)
      final expiry = DateTime.now().add(const Duration(minutes: 55));
      await prefs.setString(_kTokenExpiry, expiry.toIso8601String());
    } catch (e) {
      debugPrint('[ApiClient] Failed to save token: $e');
    }
  }

  /// Read the stored JWT token.  Returns null if absent or expired.
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kJwtToken);
      if (token == null) return null;

      final expiryStr = prefs.getString(_kTokenExpiry);
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          // Token is expired — clear it and force re-login
          await clearToken();
          return null;
        }
      }
      return token;
    } catch (e) {
      debugPrint('[ApiClient] Failed to read token: $e');
      return null;
    }
  }

  /// Clear stored token (on logout or 401 responses).
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kJwtToken);
      await prefs.remove(_kTokenExpiry);
    } catch (e) {
      debugPrint('[ApiClient] Failed to clear token: $e');
    }
  }

  /// Whether a valid, non-expired token is currently stored.
  static Future<bool> isAuthenticated() async {
    return (await getToken()) != null;
  }

  // ─── HTTP Helpers ─────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Performs a GET request against [path] (relative to [ApiConfig.baseUrl]).
  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final headers = await _authHeaders();
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on TimeoutException {
      return ApiResponse.timeout();
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Performs a POST request against [path] with [body] as JSON.
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(path, null);
      final headers = await _authHeaders();
      final response = await http
          .post(uri, headers: headers, body: body != null ? json.encode(body) : null)
          .timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on TimeoutException {
      return ApiResponse.timeout();
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Performs a PATCH request against [path] with [body] as JSON.
  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final uri = _buildUri(path, null);
      final headers = await _authHeaders();
      final response = await http
          .patch(uri, headers: headers, body: body != null ? json.encode(body) : null)
          .timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on TimeoutException {
      return ApiResponse.timeout();
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Performs a DELETE request against [path].
  Future<ApiResponse> delete(String path) async {
    try {
      final uri = _buildUri(path, null);
      final headers = await _authHeaders();
      final response = await http.delete(uri, headers: headers).timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on TimeoutException {
      return ApiResponse.timeout();
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
    final fullPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$fullPath');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
    }
    return uri;
  }

  ApiResponse _parse(http.Response response) {
    if (response.statusCode == 401) {
      // Token invalid or expired — clear it so the UI can redirect to login
      clearToken();
      return ApiResponse(
        statusCode: 401,
        success: false,
        error: 'Session expired. Please log in again.',
      );
    }

    if (response.statusCode == 429) {
      return ApiResponse(
        statusCode: 429,
        success: false,
        error: 'Too many requests. Please slow down.',
      );
    }

    final bool ok = response.statusCode >= 200 && response.statusCode < 300;
    dynamic body;
    try {
      body = json.decode(response.body);
    } catch (_) {
      body = response.body;
    }

    return ApiResponse(
      statusCode: response.statusCode,
      success: ok,
      data: ok ? body : null,
      error: ok ? null : _extractError(body, response.statusCode),
    );
  }

  String _extractError(dynamic body, int statusCode) {
    if (body is Map && body.containsKey('detail')) {
      return body['detail'].toString();
    }
    return 'Server error ($statusCode). Please try again.';
  }
}

// ─── Response Model ───────────────────────────────────────────────────────────

/// Structured result of every API call — callers never receive raw exceptions.
class ApiResponse {
  final int statusCode;
  final bool success;
  final dynamic data;
  final String? error;

  const ApiResponse({
    required this.statusCode,
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.networkError() => const ApiResponse(
        statusCode: 0,
        success: false,
        error: 'No internet connection. Using offline data.',
      );

  factory ApiResponse.timeout() => const ApiResponse(
        statusCode: 408,
        success: false,
        error: 'Request timed out. Check your connection.',
      );

  factory ApiResponse.error(String message) => ApiResponse(
        statusCode: -1,
        success: false,
        error: message,
      );

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;

  /// Tries to return [data] as a `List<Map<String, dynamic>>`.
  /// Returns an empty list on failure.
  List<Map<String, dynamic>> get dataAsList {
    if (data == null) return [];
    if (data is List) {
      return (data as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  /// Tries to return [data] as a `Map<String, dynamic>`.
  Map<String, dynamic>? get dataAsMap {
    if (data is Map) return Map<String, dynamic>.from(data as Map);
    return null;
  }

  @override
  String toString() => 'ApiResponse(status=$statusCode, ok=$success, error=$error)';
}
