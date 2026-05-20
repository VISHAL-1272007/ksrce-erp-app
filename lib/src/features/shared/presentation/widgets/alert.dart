import 'package:flutter/material.dart';

/// Types of alert messages displayed in the UI
enum AlertType { destructive, warning, info }

/// A reusable alert widget for displaying messages with different severity levels.
/// 
/// Supports three types:
/// - [AlertType.destructive]: For errors (red)
/// - [AlertType.warning]: For warnings (orange)
/// - [AlertType.info]: For informational messages (blue)
class Alert extends StatelessWidget {
  final AlertType type;
  final String message;

  const Alert({
    super.key,
    required this.type,
    required this.message,
  });

  IconData get _icon {
    switch (type) {
      case AlertType.destructive:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_outlined;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  Color _getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case AlertType.destructive:
        return theme.colorScheme.error;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
