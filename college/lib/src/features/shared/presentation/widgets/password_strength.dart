import 'package:flutter/material.dart';

/// Enum representing the strength level of a password
enum PasswordStrengthLevel {
  weak,
  fair,
  good,
  strong,
  veryStrong,
}

/// Configuration class for password strength requirements
class PasswordStrengthConfig {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;

  const PasswordStrengthConfig({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
  });
}

/// A widget that displays password strength feedback with visual indicators
/// and a checklist of requirements.
class PasswordStrength extends StatefulWidget {
  final String password;
  final PasswordStrengthConfig config;
  final ValueChanged<PasswordStrengthLevel>? onStrengthChanged;
  final bool showRequirements;

  const PasswordStrength({
    super.key,
    required this.password,
    this.config = const PasswordStrengthConfig(),
    this.onStrengthChanged,
    this.showRequirements = true,
  });

  @override
  State<PasswordStrength> createState() => _PasswordStrengthState();
}

class _PasswordStrengthState extends State<PasswordStrength> {
  late PasswordStrengthLevel _currentLevel;

  @override
  void initState() {
    super.initState();
    _currentLevel = _calculateStrength();
  }

  @override
  void didUpdateWidget(PasswordStrength oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      final newLevel = _calculateStrength();
      if (newLevel != _currentLevel) {
        setState(() {
          _currentLevel = newLevel;
        });
        widget.onStrengthChanged?.call(newLevel);
      }
    }
  }

  PasswordStrengthLevel _calculateStrength() {
    int score = 0;

    // Length check
    if (widget.password.length >= widget.config.minLength) {
      score++;
    }
    if (widget.password.length >= 12) {
      score++;
    }

    // Character variety checks
    if (widget.config.requireUppercase &&
        widget.password.contains(RegExp(r'[A-Z]'))) {
      score++;
    }
    if (widget.config.requireLowercase &&
        widget.password.contains(RegExp(r'[a-z]'))) {
      score++;
    }
    if (widget.config.requireNumbers &&
        widget.password.contains(RegExp(r'[0-9]'))) {
      score++;
    }
    if (widget.config.requireSpecialChars &&
        widget.password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?]'))) {
      score++;
    }

    // Return strength level based on score
    if (score <= 1) {
      return PasswordStrengthLevel.weak;
    } else if (score == 2) {
      return PasswordStrengthLevel.fair;
    } else if (score == 3) {
      return PasswordStrengthLevel.good;
    } else if (score == 4) {
      return PasswordStrengthLevel.strong;
    } else {
      return PasswordStrengthLevel.veryStrong;
    }
  }

  Color _getColorForLevel(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.weak:
        return Colors.red;
      case PasswordStrengthLevel.fair:
        return Colors.orange;
      case PasswordStrengthLevel.good:
        return Colors.amber;
      case PasswordStrengthLevel.strong:
        return Colors.lightGreen;
      case PasswordStrengthLevel.veryStrong:
        return Colors.green;
    }
  }

  String _getLabelForLevel(PasswordStrengthLevel level) {
    switch (level) {
      case PasswordStrengthLevel.weak:
        return 'Weak';
      case PasswordStrengthLevel.fair:
        return 'Fair';
      case PasswordStrengthLevel.good:
        return 'Good';
      case PasswordStrengthLevel.strong:
        return 'Strong';
      case PasswordStrengthLevel.veryStrong:
        return 'Very Strong';
    }
  }

  double _getStrengthPercentage() {
    const total = 5.0;
    switch (_currentLevel) {
      case PasswordStrengthLevel.weak:
        return 1 / total;
      case PasswordStrengthLevel.fair:
        return 2 / total;
      case PasswordStrengthLevel.good:
        return 3 / total;
      case PasswordStrengthLevel.strong:
        return 4 / total;
      case PasswordStrengthLevel.veryStrong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForLevel(_currentLevel);
    final label = _getLabelForLevel(_currentLevel);
    final percentage = _getStrengthPercentage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 6,
                  backgroundColor:
                      color.withValues(alpha: 0.2),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (widget.showRequirements) ...[
          const SizedBox(height: 12),
          _PasswordRequirements(
            password: widget.password,
            config: widget.config,
          ),
        ],
      ],
    );
  }
}

/// Widget that displays a checklist of password requirements
class _PasswordRequirements extends StatelessWidget {
  final String password;
  final PasswordStrengthConfig config;

  const _PasswordRequirements({
    required this.password,
    required this.config,
  });

  bool _metLengthRequirement() {
    return password.length >= config.minLength;
  }

  bool _metUppercaseRequirement() {
    if (!config.requireUppercase) return true;
    return password.contains(RegExp(r'[A-Z]'));
  }

  bool _metLowercaseRequirement() {
    if (!config.requireLowercase) return true;
    return password.contains(RegExp(r'[a-z]'));
  }

  bool _metNumberRequirement() {
    if (!config.requireNumbers) return true;
    return password.contains(RegExp(r'[0-9]'));
  }

  bool _metSpecialCharRequirement() {
    if (!config.requireSpecialChars) return true;
    return password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?]'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Requirements:',
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _RequirementItem(
          label: 'At least ${config.minLength} characters',
          met: _metLengthRequirement(),
        ),
        if (config.requireUppercase)
          _RequirementItem(
            label: 'One uppercase letter (A-Z)',
            met: _metUppercaseRequirement(),
          ),
        if (config.requireLowercase)
          _RequirementItem(
            label: 'One lowercase letter (a-z)',
            met: _metLowercaseRequirement(),
          ),
        if (config.requireNumbers)
          _RequirementItem(
            label: 'One number (0-9)',
            met: _metNumberRequirement(),
          ),
        if (config.requireSpecialChars)
          _RequirementItem(
            label: 'One special character (!@#\$%^&*)',
            met: _metSpecialCharRequirement(),
          ),
      ],
    );
  }
}

/// A single requirement item with an icon and label
class _RequirementItem extends StatelessWidget {
  final String label;
  final bool met;

  const _RequirementItem({
    required this.label,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    final color = met ? Colors.green : Colors.grey;
    final icon = met ? Icons.check_circle : Icons.circle_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
