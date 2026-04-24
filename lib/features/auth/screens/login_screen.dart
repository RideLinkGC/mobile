import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../chat/providers/chat_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetOtpController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetOtpController.dispose();
    _resetPasswordController.dispose();
    super.dispose();
  }

  void _propagateUserId(String userId) {
    context.read<ChatProvider>().setUserId(userId);
    context.read<NotificationProvider>().setUserId(userId);
  }

  Future<void> _handleDemoLogin(UserRole role) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginAsDemo(role);

    if (!mounted) return;

    if (success) {
      _propagateUserId(authProvider.user?.id ?? '');
      context.go(role == UserRole.driver ? '/driver' : '/passenger');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final success = await authProvider.login(email, password);

    if (!mounted) return;

    if (success) {
      _propagateUserId(authProvider.user?.id ?? '');
      final role = authProvider.user?.role.name ?? 'passenger';
      context.go(role == 'driver' ? '/driver' : '/passenger');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handlePasswordReset() async {
    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first.')),
      );
      return;
    }
    if (!_showReset) {
      final sent = await authProvider.requestPasswordResetOtp(email);
      if (!mounted) return;
      if (sent) {
        setState(() => _showReset = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset OTP sent.')),
        );
      }
      return;
    }
    final ok = await authProvider.resetPasswordWithOtp(
      email: email,
      otp: _resetOtpController.text.trim(),
      newPassword: _resetPasswordController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _showReset = false);
      _resetOtpController.clear();
      _resetPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.state == AuthState.loading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.welcome,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.login,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 36),
                AppTextField(
                  controller: _emailController,
                  hintText: l10n.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  hintText: l10n.password,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textHintLight,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handlePasswordReset,
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                if (_showReset) ...[
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _resetOtpController,
                    hintText: 'Reset OTP',
                    prefixIcon: Icons.password,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _resetPasswordController,
                    hintText: 'New password',
                    prefixIcon: Icons.lock_reset_outlined,
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 16),
                AppButton(
                  text: l10n.login,
                  onPressed: _handleLogin,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dontHaveAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text(
                        l10n.register,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or try demo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHintLight,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : () => _handleDemoLogin(UserRole.passenger),
                        icon: const Icon(Icons.person_outline, size: 20),
                        label: const Text('Passenger'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : () => _handleDemoLogin(UserRole.driver),
                        icon: const Icon(Icons.directions_car_outlined, size: 20),
                        label: const Text('Driver'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
