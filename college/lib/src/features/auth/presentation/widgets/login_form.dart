import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ksrce_erp/src/core/api_error_handler.dart';
import '../../data/auth_service.dart';
import '../../domain/models.dart';
import '../../../shared/presentation/widgets/alert.dart';

class LoginForm extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> allowedPrefixes;
  final String placeholderId;
  final List<DemoCredential> demoCredentials;

  const LoginForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.allowedPrefixes,
    required this.placeholderId,
    required this.demoCredentials,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _showPassword = false;
  bool _rememberMe = false;
  bool _isSubmitting = false;
  String? _error;
  int? _lockDuration;
  int? _remainingAttempts;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRememberedUser() async {
    final rememberedId = await _authService.getRememberedUser();
    if (rememberedId != null) {
      final prefix = rememberedId.replaceAll(RegExp(r'\d+$'), '').toUpperCase();
      if (widget.allowedPrefixes.contains(prefix)) {
        setState(() {
          _userIdController.text = rememberedId;
          _rememberMe = true;
        });
      }
    }
  }

  void _startLockTimer(int seconds) {
    _lockTimer?.cancel(); // Cancel any existing timer
    setState(() {
      _lockDuration = seconds;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockDuration != null && _lockDuration! > 1) {
        setState(() {
          _lockDuration = _lockDuration! - 1;
        });
      } else {
        timer.cancel();
        setState(() {
          _lockDuration = null;
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
      _remainingAttempts = null;
    });

    try {
      final result = await _authService.login(
        _userIdController.text,
        _passwordController.text,
        _rememberMe,
      );

      if (result.success) {
        if (mounted) context.go('/dashboard');
      } else {
        setState(() {
          _error = result.message;
          _remainingAttempts = result.remainingAttempts;
        });
        if (result.lockDuration != null) {
          _startLockTimer(result.lockDuration!);
        }
      }
    } catch (e) {
      setState(() {
        _error = "An unexpected error occurred. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = _lockDuration != null && _lockDuration! > 0;
    final isDisabled = _isSubmitting || isLocked;

    return Scaffold(
      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(theme),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildForm(theme, isDisabled, isLocked),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      width: double.infinity,
      color: theme.colorScheme.primary,
      child: Column(
        children: [
          // KSRCE Logo
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset('assets/ksrce-logo.png'), // Make sure to add this asset
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme, bool isDisabled, bool isLocked) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enhanced error messaging for API failures
          if (_error != null) ...[
            Alert(type: AlertType.destructive, message: _error!),
            if (_error!.contains('404') || _error!.contains('not found') || _error!.contains('backend'))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Alert(
                  type: AlertType.info,
                  message: 'Tip: ${ApiErrorHandler.error404Suggestion}',
                ),
              ),
          ],
          if (isLocked)
            Alert(type: AlertType.info, message: "Account locked. Try again in $_lockDuration seconds."),
          if (_remainingAttempts != null && _remainingAttempts! > 0 && _remainingAttempts! <= 2)
            Alert(type: AlertType.warning, message: "Warning: $_remainingAttempts attempt${_remainingAttempts! != 1 ? 's' : ''} remaining before lockout."),

          const SizedBox(height: 16),
          TextFormField(
            controller: _userIdController,
            enabled: !isDisabled,
            decoration: InputDecoration(
              labelText: "User ID",
              hintText: widget.placeholderId,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your User ID';
              final prefix = value.replaceAll(RegExp(r'\d+$'), '').toUpperCase();
              if (!widget.allowedPrefixes.contains(prefix)) {
                 return 'Invalid ID for this portal.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            enabled: !isDisabled,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your password';
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: isDisabled ? null : (value) => setState(() => _rememberMe = value ?? false),
                  ),
                  const Text("Remember me"),
                ],
              ),
              const Text("🔒 CAPTCHA", style: TextStyle(fontSize: 12)), // Placeholder
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isDisabled ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                : const Text("Sign In"),
          ),
          const SizedBox(height: 24),
          _buildDemoCredentials(theme),
        ],
      ),
    );
  }

  Widget _buildDemoCredentials(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Demo Credentials:",
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: widget.demoCredentials.map((c) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 2, bottom: 2),
                  child: Text("${c.label}:", style: theme.textTheme.bodySmall),
                ),
                Text("${c.id} / ${c.password}", style: theme.textTheme.bodySmall),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}
