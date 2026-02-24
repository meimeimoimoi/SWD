import 'package:flutter/material.dart';
import '../../../routes/app_router.dart';
import '../../../share/services/auth_api_service.dart';
import '../../../share/services/storage_service.dart';
import '../../../share/theme/app_colors.dart';
import '../../../share/widgets/app_button.dart';
import '../../../share/widgets/app_card.dart';
import '../../../share/widgets/app_input.dart';
import '../../../share/widgets/app_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Extract token data from response
        final tokenData = result['data']?['token'];
        final username = tokenData?['username'] as String?;
        final role = tokenData?['role'] as String?;
        final accessToken = tokenData?['accessToken'] as String?;
        final refreshToken = tokenData?['refreshToken'] as String?;
        final expiresIn = tokenData?['expiresIn'] as String?;

        if (accessToken != null) {
          // Save token and user info
          await StorageService.saveAuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            username: username,
            role: role,
            expiresIn: expiresIn,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${username ?? "User"}!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to dashboard
          Navigator.pushReplacementNamed(context, AppRouter.dashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed: No token received'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show error message
        String errorMessage = result['message'] ?? 'Login failed';

        // Handle specific validation errors
        if (result['data'] != null && result['data']['errors'] != null) {
          final errors = result['data']['errors'] as Map<String, dynamic>;
          final firstError = errors.entries.firstOrNull;
          if (firstError != null && firstError.value is List) {
            errorMessage = (firstError.value as List).first ?? errorMessage;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      centerContent: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 900;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _HeroPanel(isWide: isWide)),
                const SizedBox(width: 24),
                Expanded(
                  child: _AuthCard(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    rememberMe: _rememberMe,
                    obscurePassword: _obscurePassword,
                    isLoading: _isLoading,
                    onRememberChanged: (value) =>
                        setState(() => _rememberMe = value),
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _submit,
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroPanel(isWide: isWide),
                const SizedBox(height: 24),
                _AuthCard(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  rememberMe: _rememberMe,
                  obscurePassword: _obscurePassword,
                  isLoading: _isLoading,
                  onRememberChanged: (value) =>
                      setState(() => _rememberMe = value),
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmit: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required GlobalKey<FormState> formKey,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.isLoading,
    required this.onRememberChanged,
    required this.onTogglePassword,
    required this.onSubmit,
  }) : _formKey = formKey;

  final GlobalKey<FormState> _formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isLoading;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome back', style: theme.textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Please sign in to continue',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            AppInput(
              label: 'Email',
              hint: 'you@example.com',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Password',
              controller: passwordController,
              obscureText: obscurePassword,
              hint: '••••••••',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) return 'At least 6 characters';
                return null;
              },
              suffix: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) => onRememberChanged(value ?? false),
                    ),
                    const Text('Remember me'),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: isLoading ? 'Signing in...' : 'Sign in',
              onPressed: isLoading ? null : onSubmit,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Create account',
              variant: AppButtonVariant.outlined,
              onPressed: isLoading
                  ? null
                  : () => Navigator.pushNamed(context, AppRouter.register),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'or continue with',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Continue with Google',
              variant: AppButtonVariant.ghost,
              icon: Icons.g_translate,
              onPressed: isLoading ? null : () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Smart tree health',
            style: theme.textTheme.displayLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Monitor, predict, and respond to tree conditions in real time.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            // children: const [
            //   _ChipLabel(text: 'AI Predictions'),
            //   _ChipLabel(text: 'Live monitoring'),
            //   _ChipLabel(text: 'Insights'),
            // ],
          ),
          if (!isWide) const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
