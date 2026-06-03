import 'package:flutter/foundation.dart';

/// A simple data class to hold demo credential information.
@immutable
class DemoCredential {
  final String label;
  final String id;
  final String password;

  const DemoCredential({
    required this.label,
    required this.id,
    required this.password,
  });
}
