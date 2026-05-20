import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/data_service.dart';
import '../../../../core/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  int _selectedRole = 0;

  final List<String> _roles = ['Student', 'Faculty'];
  final List<IconData> _roleIcons = [Icons.school, Icons.person];
  final List<String> _placeholders = ['Eg. STU001', 'Eg. FAC001'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedRole = _tabController.index;
        _userIdController.clear();
        _passwordController.clear();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final ds = Provider.of<DataService>(context, listen: false);
    final userId = _userIdController.text.trim();
    final password = _passwordController.text;

    await Future.delayed(const Duration(milliseconds: 400));

    if (ds.login(userId, password)) {
      if (!mounted) return;
      context.go(ds.getHomeRouteForCurrentUser());
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid User ID or password. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 960;

    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isWide
                      ? Row(
                          children: [
                            const Expanded(flex: 3, child: _BrandPanel()),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _LoginFormCard(
                              formKey: _formKey,
                              tabController: _tabController,
                              roles: _roles,
                              roleIcons: _roleIcons,
                              placeholders: _placeholders,
                              userIdController: _userIdController,
                              passwordController: _passwordController,
                              isLoading: _isLoading,
                              obscurePassword: _obscurePassword,
                              rememberMe: _rememberMe,
                              selectedRole: _selectedRole,
                              onToggleRemember: (v) => setState(() => _rememberMe = v ?? false),
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                              onLogin: _login,
                            )),
                          ],
                        )
                      : Column(
                          children: [
                            const _BrandPanel(),
                            const SizedBox(height: 24),
                            _LoginFormCard(
                              formKey: _formKey,
                              tabController: _tabController,
                              roles: _roles,
                              roleIcons: _roleIcons,
                              placeholders: _placeholders,
                              userIdController: _userIdController,
                              passwordController: _passwordController,
                              isLoading: _isLoading,
                              obscurePassword: _obscurePassword,
                              rememberMe: _rememberMe,
                              selectedRole: _selectedRole,
                              onToggleRemember: (v) => setState(() => _rememberMe = v ?? false),
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                              onLogin: _login,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFEFF6FF),
            Color(0xFFF8FAFC),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KSRCE ERP', style: Theme.of(context).textTheme.titleLarge),
                  Text('Enterprise Campus Suite', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Secure access for students, faculty, and administrators.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Role-aware dashboards, academic tracking, and operational workflows in one unified platform.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _InfoBadge(icon: Icons.lock, text: 'Secure Access'),
              _InfoBadge(icon: Icons.analytics, text: 'Analytics Ready'),
              _InfoBadge(icon: Icons.school, text: 'Academic Core'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TabController tabController;
  final List<String> roles;
  final List<IconData> roleIcons;
  final List<String> placeholders;
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final bool rememberMe;
  final int selectedRole;
  final ValueChanged<bool?> onToggleRemember;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  const _LoginFormCard({
    required this.formKey,
    required this.tabController,
    required this.roles,
    required this.roleIcons,
    required this.placeholders,
    required this.userIdController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.rememberMe,
    required this.selectedRole,
    required this.onToggleRemember,
    required this.onToggleObscure,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Secure Login', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Select your portal and sign in.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TabBar(
                controller: tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textLight,
                dividerColor: Colors.transparent,
                labelStyle: Theme.of(context).textTheme.labelLarge,
                tabs: List.generate(2, (i) => Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(roleIcons[i], size: 18),
                      const SizedBox(width: 6),
                      Text(roles[i]),
                    ],
                  ),
                )),
              ),
            ),
            const SizedBox(height: 22),
            Text('User ID', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: userIdController,
              decoration: InputDecoration(
                hintText: placeholders[tabController.index],
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please enter your User ID' : null,
            ),
            const SizedBox(height: 18),
            Text('Password', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: onToggleObscure,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: onToggleRemember,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Text('Remember me', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                TextButton(
                  onPressed: () => _showForgotPasswordDialog(context),
                  child: Text('Forgot Password?', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetController = TextEditingController();
    final reasonController = TextEditingController();
    String? message;
    bool isSuccess = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text('Reset Password'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your User ID to raise a password reset request.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Approval flow: Student -> Mentor (if assigned) -> HOD, Faculty -> HOD, HOD -> Admin.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetController,
                    decoration: InputDecoration(
                      labelText: 'User ID',
                      hintText: 'Eg. STU001 or FAC001',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason (optional)',
                      hintText: 'Example: Forgot my password and cannot log in',
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSuccess ? Colors.green : Colors.red, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(message!, style: TextStyle(fontSize: 13, color: isSuccess ? Colors.green.shade800 : Colors.red.shade800))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final uid = resetController.text.trim();
                    if (uid.isEmpty) {
                      setDialogState(() {
                        message = 'Please enter your User ID.';
                        isSuccess = false;
                      });
                      return;
                    }
                    final ds = Provider.of<DataService>(ctx, listen: false);
                    final error = ds.submitPasswordResetRequest(
                      uid,
                      reason: reasonController.text.trim(),
                    );
                    setDialogState(() {
                      if (error == null) {
                        message = 'Request submitted. You will be able to log in with default password after all approvals.';
                        isSuccess = true;
                      } else {
                        message = error;
                        isSuccess = false;
                      }
                    });
                  },
                  child: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C5282).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const gap = 42.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
