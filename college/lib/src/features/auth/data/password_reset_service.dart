import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/hash_service.dart';

class ResetStepResult {
  final bool success;
  final String message;

  const ResetStepResult({
    required this.success,
    required this.message,
  });
}

class PasswordResetService {
  static const String _userDbKey = 'secure_user_db_v2';

  static Future<void> seedUserDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_userDbKey);
    if (existing != null) return;

    // No seed users — users are added dynamically via the admin panel
    await prefs.setString(_userDbKey, jsonEncode({}));
  }

  static Future<Map<String, dynamic>?> _getUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final dbJson = prefs.getString(_userDbKey);
    if (dbJson == null) return null;

    final db = jsonDecode(dbJson) as Map<String, dynamic>;
    return db[userId.toUpperCase()] as Map<String, dynamic>?;
  }

  static String? _validatePasswordStrength(String password) {
    if (password.length < 8) return 'Minimum 8 characters required';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Uppercase letter required';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Lowercase letter required';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Number required';
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      return 'Special character required';

    final commonPasswords = [
      'password',
      'password123',
      'qwerty',
      '123456',
      'admin',
      'letmein',
      'welcome'
    ];
    if (commonPasswords.contains(password.toLowerCase())) {
      return 'This password is too common';
    }

    return null;
  }

  static Future<String?> verifyCredentials(String userId, String password) async {
    final user = await _getUser(userId);
    if (user == null) return null;

    final salt = user['salt'] as String;
    final storedHash = user['passwordHash'] as String?;
    if (storedHash == null) return null;

    if (HashService.verifyPassword(password, storedHash, salt)) {
      return user['role'] as String;
    }
    return null;
  }

  static Future<ResetStepResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      return const ResetStepResult(
        success: false,
        message: 'New passwords do not match.',
      );
    }

    if (currentPassword == newPassword) {
      return const ResetStepResult(
        success: false,
        message: 'New password must be different from current password.',
      );
    }

    final strengthIssue = _validatePasswordStrength(newPassword);
    if (strengthIssue != null) {
      return ResetStepResult(
        success: false,
        message: strengthIssue,
      );
    }

    final role = await verifyCredentials(userId, currentPassword);
    if (role == null) {
      return const ResetStepResult(
        success: false,
        message: 'Current password is incorrect.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final dbJson = prefs.getString(_userDbKey);
    if (dbJson == null) {
      return const ResetStepResult(
        success: false,
        message: 'System error. Please contact administrator.',
      );
    }

    final db = jsonDecode(dbJson) as Map<String, dynamic>;
    final userKey = userId.toUpperCase();
    if (!db.containsKey(userKey)) {
      return const ResetStepResult(
        success: false,
        message: 'User not found in database.',
      );
    }

    final newSalt = HashService.generateSalt();
    final newHash = HashService.hashPassword(newPassword, newSalt);

    final userData = db[userKey] as Map<String, dynamic>;
    userData['salt'] = newSalt;
    userData['passwordHash'] = newHash;
    userData['lastPasswordChange'] = DateTime.now().toIso8601String();

    db[userKey] = userData;
    await prefs.setString(_userDbKey, jsonEncode(db));

    return const ResetStepResult(
      success: true,
      message: 'Password changed successfully!',
    );
  }
}
