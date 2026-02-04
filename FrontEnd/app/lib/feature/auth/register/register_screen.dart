import 'package:flutter/material.dart';
import '../../../routes/app_router.dart';
import '../../../share/widgets/app_button.dart';
import '../../../share/widgets/app_card.dart';
import '../../../share/widgets/app_input.dart';
import '../../../share/widgets/app_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Widget _buildNameField() {
    return AppInput(
      label: 'Full name',
      hint: 'Tran Van A',
      controller: _fullNameController,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Full name required' : null,
    );
  }

  Widget _buildEmailField() {
    return AppInput(
      label: 'Email',
      hint: 'you@example.com',
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email required';
        if (!value.contains('@')) return 'Invalid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AppInput(
      label: 'Password',
      hint: '••••••••',
      controller: _passwordController,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password required';
        if (value.length < 6) return 'At least 6 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmField() {
    return AppInput(
      label: 'Confirm password',
      hint: '••••••••',
      controller: _confirmController,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Confirm password';
        if (value != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created (demo only).')),
    );
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      centerContent: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 720;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create your account', style: theme.textTheme.displayMedium),
              const SizedBox(height: 6),
              Text(
                'Join and start managing your trees smarter.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      isWide
                          ? Row(
                              children: [
                                Expanded(child: _buildNameField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildEmailField()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildNameField(),
                                const SizedBox(height: 16),
                                _buildEmailField(),
                              ],
                            ),
                      const SizedBox(height: 16),
                      isWide
                          ? Row(
                              children: [
                                Expanded(child: _buildPasswordField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildConfirmField()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildPasswordField(),
                                const SizedBox(height: 16),
                                _buildConfirmField(),
                              ],
                            ),
                      const SizedBox(height: 16),
                      isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Sign up',
                                    onPressed: _submit,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: 'Back to login',
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                AppButton(label: 'Sign up', onPressed: _submit),
                                const SizedBox(height: 12),
                                AppButton(
                                  label: 'Back to login',
                                  variant: AppButtonVariant.outlined,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRouter.login,
                          ),
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
