import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class HashService {
  static final Random _random = Random.secure();

  static String generateSalt([int length = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String password, String storedHash, String salt) {
    return hashPassword(password, salt) == storedHash;
  }

  static String hashData(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
