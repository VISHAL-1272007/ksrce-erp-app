import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Z++ Security Service for KSRCE ERP.
/// Provides password hashing, input sanitization, brute-force protection,
/// and session management.
class SecurityService {
  // ──────────────────── PASSWORD HASHING ────────────────────

  /// Global pepper — combined with password before hashing.
  /// In production, this should come from an environment variable.
  static const String _pepper = 'K5RC3_ERP_2026_P3PP3R';

  /// Hash a password using SHA-256 with pepper + salt (userId).
  /// Returns hex-encoded hash string.
  static String hashPassword(String password, String userId) {
    final salted = '$_pepper:$userId:$password';
    final bytes = utf8.encode(salted);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify a plaintext password against a stored hash.
  static bool verifyPassword(String password, String userId, String storedHash) {
    return hashPassword(password, userId) == storedHash;
  }

  // ──────────────────── BRUTE-FORCE PROTECTION ─────────────

  /// Track failed login attempts per userId.
  static final Map<String, _LoginAttempt> _attempts = {};

  /// Maximum failed attempts before lockout.
  static const int maxAttempts = 5;

  /// Lockout duration after max attempts exceeded.
  static const Duration lockoutDuration = Duration(minutes: 5);

  /// Check if a user is currently locked out.
  /// Returns remaining seconds if locked, 0 if not locked.
  static int getLockedOutSeconds(String userId) {
    final attempt = _attempts[userId];
    if (attempt == null) return 0;
    if (attempt.failedCount < maxAttempts) return 0;
    final elapsed = DateTime.now().difference(attempt.lastAttempt);
    if (elapsed >= lockoutDuration) {
      // Lockout expired, reset
      _attempts.remove(userId);
      return 0;
    }
    return (lockoutDuration - elapsed).inSeconds;
  }

  /// Record a failed login attempt. Returns true if now locked out.
  static bool recordFailedAttempt(String userId) {
    final attempt = _attempts[userId] ?? _LoginAttempt();
    attempt.failedCount++;
    attempt.lastAttempt = DateTime.now();
    _attempts[userId] = attempt;
    return attempt.failedCount >= maxAttempts;
  }

  /// Reset login attempts after successful login.
  static void resetAttempts(String userId) {
    _attempts.remove(userId);
  }

  // ──────────────────── SESSION MANAGEMENT ──────────────────

  /// Session timeout duration (30 minutes of inactivity).
  static const Duration sessionTimeout = Duration(minutes: 30);

  /// Timestamp of last user activity.
  static DateTime _lastActivity = DateTime.now();

  /// Update the last activity timestamp.
  static void touchSession() {
    _lastActivity = DateTime.now();
  }

  /// Check if the session has timed out.
  static bool isSessionExpired() {
    return DateTime.now().difference(_lastActivity) >= sessionTimeout;
  }

  // ──────────────────── INPUT SANITIZATION ──────────────────

  /// Sanitize a string input to prevent XSS and injection.
  /// Removes HTML tags, trims whitespace, limits length.
  static String sanitize(String input, {int maxLength = 500}) {
    // Remove HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove script patterns
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    // Remove SQL injection patterns
    sanitized = sanitized.replaceAll(RegExp(r"('|--|;|/\*|\*/)", caseSensitive: false), '');
    // Trim and limit length
    sanitized = sanitized.trim();
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    return sanitized;
  }

  /// Validate that a user ID matches expected format.
  static bool isValidUserId(String id) {
    return RegExp(r'^(STU|FAC|ADM)\d{3}$').hasMatch(id);
  }

  /// Validate password meets minimum requirements.
  static String? validatePasswordStrength(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Must contain a lowercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
    return null; // Valid
  }
}

/// Internal class for tracking login attempts.
class _LoginAttempt {
  int failedCount = 0;
  DateTime lastAttempt = DateTime.now();
}
