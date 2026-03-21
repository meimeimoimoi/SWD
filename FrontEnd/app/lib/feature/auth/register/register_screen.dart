import 'package:flutter/material.dart';
import '../../../routes/app_router.dart';
import '../../../share/services/auth_api_service.dart';
import '../../../share/constants/app_brand.dart';
import '../../../share/widgets/app_button.dart';
import '../../../share/widgets/app_card.dart';
import '../../../share/widgets/app_input.dart';
import '../../../share/widgets/app_scaffold.dart';
import '../../../share/widgets/auth_hero_banner.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthApiService.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRouter.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
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
    return AppScaffold(
      centerContent: false,
      showThemeToggle: false,
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
                        title: 'Create your account',
                        subtitle: AppBrand.registerHeroSubtitle,
                        isWide: isWide,
                        chipLabels: const [
                          'Quick signup',
                          'Secure',
                          'Sync anywhere',
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _RegisterFormCard(
                        formKey: _formKey,
                        usernameController: _usernameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmController: _confirmController,
                        obscurePassword: _obscurePassword,
                        obscureConfirm: _obscureConfirm,
                        isLoading: _isLoading,
                        isWide: isWide,
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onToggleConfirm: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
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
                      title: 'Create your account',
                      subtitle: AppBrand.registerHeroSubtitle,
                      isWide: isWide,
                      chipLabels: const [
                        'Quick signup',
                        'Secure',
                        'Sync anywhere',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _RegisterFormCard(
                      formKey: _formKey,
                      usernameController: _usernameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmController: _confirmController,
                      obscurePassword: _obscurePassword,
                      obscureConfirm: _obscureConfirm,
                      isLoading: _isLoading,
                      isWide: isWide,
                      onTogglePassword: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      onToggleConfirm: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
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

class _RegisterFormCard extends StatelessWidget {
  const _RegisterFormCard({
    required GlobalKey<FormState> formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.isWide,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  }) : _formKey = formKey;

  final GlobalKey<FormState> _formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final bool isWide;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final passwordField = AppInput(
      label: 'Password',
      hint: '••••••••',
      controller: passwordController,
      obscureText: obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password required';
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
    );

    final confirmField = AppInput(
      label: 'Confirm password',
      hint: '••••••••',
      controller: confirmController,
      obscureText: obscureConfirm,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirm password required';
        }
        if (value != passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      suffix: IconButton(
        icon: Icon(
          obscureConfirm
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: onToggleConfirm,
      ),
    );

    final primaryActions = isWide
        ? Row(
            children: [
              Expanded(
                child: AppButton(
                  label: isLoading ? 'Registering...' : 'Sign up',
                  onPressed: isLoading ? null : onSubmit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Back to login',
                  variant: AppButtonVariant.outlined,
                  onPressed:
                      isLoading ? null : () => Navigator.pop(context),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: isLoading ? 'Registering...' : 'Sign up',
                onPressed: isLoading ? null : onSubmit,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to login',
                variant: AppButtonVariant.outlined,
                onPressed: isLoading ? null : () => Navigator.pop(context),
              ),
            ],
          );

    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your details',
              style: theme.textTheme.titleLarge,
              softWrap: true,
            ),
            const SizedBox(height: 20),
            AppInput(
              label: 'Username',
              hint: 'john_doe',
              controller: usernameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username required';
                }
                if (value.trim().length < 2) {
                  return 'Username must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppInput(
              label: 'Email',
              hint: 'john@example.com',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email required';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: passwordField),
                  const SizedBox(width: 16),
                  Expanded(child: confirmField),
                ],
              )
            else ...[
              passwordField,
              const SizedBox(height: 16),
              confirmField,
            ],
            const SizedBox(height: 20),
            primaryActions,
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: isLoading
                  ? null
                  : () => Navigator.pushReplacementNamed(
                        context,
                        AppRouter.login,
                      ),
              child: Text(
                'Already have an account? Sign in',
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
