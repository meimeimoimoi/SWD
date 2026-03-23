import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../routes/app_router.dart';
import '../../../share/services/auth_api_service.dart';
import '../../../share/services/storage_service.dart';
import '../../../share/constants/app_brand.dart';
import '../../../share/constants/demo_accounts.dart';
import '../../../share/widgets/app_button.dart';
import '../../../share/widgets/app_card.dart';
import '../../../share/widgets/app_input.dart';
import '../../../share/widgets/app_scaffold.dart';
import '../../../share/widgets/auth_hero_banner.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDemoProfile());
  }

  Future<void> _restoreDemoProfile() async {
    final saved = await StorageService.getLoginDemoProfile();
    if (!mounted) return;
    final useAdmin = saved == 'admin';
    setState(() {
      _emailController.text =
          useAdmin ? DemoAccounts.adminEmail : DemoAccounts.userEmail;
      _passwordController.text =
          useAdmin ? DemoAccounts.adminPassword : DemoAccounts.userPassword;
    });
  }

  Future<void> _applyDemoUser() async {
    setState(() {
      _emailController.text = DemoAccounts.userEmail;
      _passwordController.text = DemoAccounts.userPassword;
    });
    await StorageService.saveLoginDemoProfile('user');
  }

  Future<void> _applyDemoAdmin() async {
    setState(() {
      _emailController.text = DemoAccounts.adminEmail;
      _passwordController.text = DemoAccounts.adminPassword;
    });
    await StorageService.saveLoginDemoProfile('admin');
  }

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
        final tokenData = result['data']?['token'];
        final username = tokenData?['username'] as String?;
        final role = tokenData?['role'] as String?;
        final accessToken = tokenData?['accessToken'] as String?;
        final refreshToken = tokenData?['refreshToken'] as String?;
        final expiresIn = tokenData?['expiresIn'] as String?;

        if (accessToken != null) {
          await StorageService.saveAuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            username: username,
            role: role,
            expiresIn: expiresIn,
          );

          if (_rememberMe) {
            final email = _emailController.text.trim();
            if (DemoAccounts.isUserDemo(email)) {
              await StorageService.saveLoginDemoProfile('user');
            } else if (DemoAccounts.isAdminDemo(email)) {
              await StorageService.saveLoginDemoProfile('admin');
            }
          }

          final cs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome back, ${username ?? "User"}!',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: cs.primary,
            ),
          );

          final roleLower = role?.toLowerCase().trim() ?? '';
          final useStaffConsole =
              roleLower == 'admin' || roleLower == 'technician';
          Navigator.pushReplacementNamed(
            context,
            useStaffConsole ? AppRouter.adminDashboard : AppRouter.dashboard,
          );
        } else {
          final cs = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login failed: No token received',
                style: TextStyle(color: cs.onError, fontWeight: FontWeight.w600),
              ),
              backgroundColor: cs.error,
            ),
          );
        }
      } else {
        String errorMessage = result['message'] ?? 'Login failed';

        if (result['data'] != null && result['data']['errors'] != null) {
          final errors = result['data']['errors'] as Map<String, dynamic>;
          final firstError = errors.entries.firstOrNull;
          if (firstError != null && firstError.value is List) {
            errorMessage = (firstError.value as List).first ?? errorMessage;
          }
        }

        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: cs.onError, fontWeight: FontWeight.w500),
            ),
            backgroundColor: cs.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: TextStyle(color: cs.onError, fontWeight: FontWeight.w500),
          ),
          backgroundColor: cs.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      centerContent: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 900;
          final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

          final Widget body = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AuthHeroBanner(
                        title: AppBrand.heroTitle,
                        subtitle: AppBrand.heroSubtitle,
                        isWide: isWide,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _AuthCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        rememberMe: _rememberMe,
                        obscurePassword: _obscurePassword,
                        isLoading: _isLoading,
                        onDemoUser: _applyDemoUser,
                        onDemoAdmin: _applyDemoAdmin,
                        onRememberChanged: (value) =>
                            setState(() => _rememberMe = value),
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onSubmit: _submit,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeroBanner(
                      title: AppBrand.heroTitle,
                      subtitle: AppBrand.heroSubtitle,
                      isWide: isWide,
                    ),
                    const SizedBox(height: 16),
                    _AuthCard(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      rememberMe: _rememberMe,
                      obscurePassword: _obscurePassword,
                      isLoading: _isLoading,
                      onDemoUser: _applyDemoUser,
                      onDemoAdmin: _applyDemoAdmin,
                      onRememberChanged: (value) =>
                          setState(() => _rememberMe = value),
                      onTogglePassword: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      onSubmit: _submit,
                    ),
                  ],
                );

          return SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottomInset + 8),
            child: body,
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
    required this.onDemoUser,
    required this.onDemoAdmin,
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
  final Future<void> Function() onDemoUser;
  final Future<void> Function() onDemoAdmin;
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
            Text(
              'Welcome back',
              style: theme.textTheme.displayMedium,
              softWrap: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Please sign in to continue',
              style: theme.textTheme.bodyLarge,
              softWrap: true,
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
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  textStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final choice = await showDialog<String>(
                          context: context,
                          builder: (ctx) {
                            final cs = Theme.of(ctx).colorScheme;
                            return AlertDialog(
                              title: const Text('Demo account'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.person_outline,
                                        color: cs.primary,
                                      ),
                                      title: const Text('User1@swd.com'),
                                      subtitle: const Text(
                                        'Regular user · demo seed',
                                      ),
                                      onTap: () => Navigator.pop(ctx, 'user'),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.admin_panel_settings_outlined,
                                        color: cs.primary,
                                      ),
                                      title: const Text('Admin@swd.com'),
                                      subtitle: const Text(
                                        'Staff console · demo seed',
                                      ),
                                      onTap: () => Navigator.pop(ctx, 'admin'),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            );
                          },
                        );
                        if (!context.mounted || choice == null) return;
                        if (choice == 'user') {
                          await onDemoUser();
                        } else if (choice == 'admin') {
                          await onDemoAdmin();
                        }
                      },
                child: const Text('Use demo account…'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) =>
                            onRememberChanged(value ?? false),
                      ),
                      Flexible(
                        child: Text(
                          'Remember me',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'or continue with',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Continue with Google',
              variant: AppButtonVariant.ghost,
              leading: FaIcon(
                FontAwesomeIcons.google,
                size: 18,
                color: const Color(0xFF4285F4),
              ),
              onPressed: isLoading ? null : () {},
            ),
          ],
        ),
      ),
    );
  }
}
