import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../../core/data_service.dart';

/// Result of a login attempt with security metadata.
@immutable
class LoginResult {
  final bool success;
  final String message;
  final int? lockDuration;
  final int? remainingAttempts;

  const LoginResult({
    required this.success,
    this.message = '',
    this.lockDuration,
    this.remainingAttempts,
  });
}

/// Hardened authentication service with multi-layer brute force protection.
///
/// Security features:
/// - Exponential backoff lockout (30s → 60s → 120s → 300s → 600s)
/// - Max 5 attempts before lockout (progressive)
/// - Credentials hashed at rest (SHA-256 with pepper + salt)
/// - Login attempt logging with timestamps
/// - Anti-automation delay randomization
/// - Lockout state integrity verification
class AuthService {
  static const String _rememberedUserKey = 'remembered_user_id';
  static const String _failedAttemptsKey = 'auth_failed_attempts';
  static const String _lockoutUntilKey = 'auth_lockout_until_ms';
  static const String _lockoutLevelKey = 'auth_lockout_level';
  static const String _loginAttemptsLogKey = 'auth_login_attempts_log';
  static const String _lockIntegrityKey = 'auth_lock_integrity';
  static const int _maxAttempts = 5;

  // Exponential backoff durations in seconds
  static const List<int> _lockoutDurations = [30, 60, 120, 300, 600];

  /// Performs login with enhanced security using DataService hashed credentials.
  Future<LoginResult> login(String userId, String password, bool rememberMe) async {
    // Anti-automation: random delay between 600ms-1500ms
    final delay = 600 + Random.secure().nextInt(900);
    await Future.delayed(Duration(milliseconds: delay));

    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Check lockout with integrity verification
    final lockoutUntilMs = prefs.getInt(_lockoutUntilKey);
    if (lockoutUntilMs != null && lockoutUntilMs > nowMs) {
      // Verify lockout integrity (prevent client-side tampering)
      if (!_verifyLockIntegrity(prefs, lockoutUntilMs)) {
        // Tampering detected! Extend lockout to maximum
        final maxLockout = nowMs + (_lockoutDurations.last * 1000);
        await _setLockout(prefs, maxLockout, _lockoutDurations.length - 1);
        return LoginResult(
          success: false,
          message: 'Security violation detected. Account locked.',
          lockDuration: _lockoutDurations.last,
          remainingAttempts: 0,
        );
      }
      final remainingSeconds = ((lockoutUntilMs - nowMs) / 1000).ceil();
      return LoginResult(
        success: false,
        message: 'Too many attempts. Try again later.',
        lockDuration: remainingSeconds,
        remainingAttempts: 0,
      );
    }

    // Clear expired lockout
    if (lockoutUntilMs != null && lockoutUntilMs <= nowMs) {
      await _clearLockState(prefs);
    }

    final normalizedUserId = userId.trim();

    // Use DataService's secure login (SHA-256 hash comparison)
    final ds = DataService();
    final errorMsg = ds.loginSecure(normalizedUserId, password);

    if (errorMsg == null) {
      // Login successful
      await _handleSuccessfulLogin(normalizedUserId, rememberMe, prefs);
      await _logLoginAttempt(prefs, normalizedUserId, true);
      return const LoginResult(success: true);
    }

    // Failed login
    await _logLoginAttempt(prefs, normalizedUserId, false);
    return _handleFailedLogin(prefs, errorMsg);
  }

  /// Retrieves the remembered user ID.
  Future<String?> getRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberedUserKey);
  }

  Future<void> _handleSuccessfulLogin(String userId, bool rememberMe, SharedPreferences prefs) async {
    await _clearLockState(prefs);
    if (rememberMe) {
      await prefs.setString(_rememberedUserKey, userId);
    } else {
      await prefs.remove(_rememberedUserKey);
    }
  }

  Future<LoginResult> _handleFailedLogin(SharedPreferences prefs, String serverMsg) async {
    final attempts = (prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
    final remainingAttempts = _maxAttempts - attempts;

    if (remainingAttempts <= 0) {
      // Calculate lockout level (escalating)
      final currentLevel = prefs.getInt(_lockoutLevelKey) ?? 0;
      final nextLevel = (currentLevel + 1).clamp(0, _lockoutDurations.length - 1);
      final lockoutSeconds = _lockoutDurations[nextLevel];
      final lockoutUntilMs = DateTime.now().millisecondsSinceEpoch + (lockoutSeconds * 1000);

      await _setLockout(prefs, lockoutUntilMs, nextLevel);
      await prefs.remove(_failedAttemptsKey);

      return LoginResult(
        success: false,
        message: 'Too many attempts. Account locked for ${_formatDuration(lockoutSeconds)}.',
        lockDuration: lockoutSeconds,
        remainingAttempts: 0,
      );
    }

    await prefs.setInt(_failedAttemptsKey, attempts);
    // Use the message from DataService which is already generic enough
    return LoginResult(
      success: false,
      message: serverMsg,
      remainingAttempts: remainingAttempts,
    );
  }

  /// Sets lockout with integrity hash to detect tampering
  Future<void> _setLockout(SharedPreferences prefs, int lockoutUntilMs, int level) async {
    await prefs.setInt(_lockoutUntilKey, lockoutUntilMs);
    await prefs.setInt(_lockoutLevelKey, level);
    // Store integrity hash so we can detect if user clears localStorage selectively
    final integrity = _computeLockIntegrity(lockoutUntilMs);
    await prefs.setString(_lockIntegrityKey, integrity);
  }

  /// Verifies that the lockout state hasn't been tampered with
  bool _verifyLockIntegrity(SharedPreferences prefs, int lockoutUntilMs) {
    final stored = prefs.getString(_lockIntegrityKey);
    if (stored == null) return false;
    final expected = _computeLockIntegrity(lockoutUntilMs);
    return stored == expected;
  }

  String _computeLockIntegrity(int lockoutUntilMs) {
    final salt = 'ksrce_lock_v2';
    return sha256.convert(utf8.encode('$lockoutUntilMs:$salt')).toString().substring(0, 16);
  }

  /// Logs login attempts for audit trail
  Future<void> _logLoginAttempt(SharedPreferences prefs, String userId, bool success) async {
    try {
      final log = prefs.getStringList(_loginAttemptsLogKey) ?? [];
      final entry = '${DateTime.now().toIso8601String()}|${success ? "OK" : "FAIL"}|${userId.substring(0, (userId.length).clamp(0, 3))}***';
      log.add(entry);
      // Keep only last 50 entries
      if (log.length > 50) log.removeRange(0, log.length - 50);
      await prefs.setStringList(_loginAttemptsLogKey, log);
    } catch (_) {}
  }

  Future<void> _clearLockState(SharedPreferences prefs) async {
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutUntilKey);
    // Don't clear lockout level - keeps escalating across lockout cycles
  }

  String _formatDuration(int seconds) {
    if (seconds >= 60) return '${seconds ~/ 60} minute${seconds >= 120 ? "s" : ""}';
    return '$seconds seconds';
  }
}
