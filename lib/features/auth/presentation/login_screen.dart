import 'package:dorm_the_explorer/app_notice.dart';
import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_widgets.dart';
import 'create_account_screen.dart';
import '../../../services/auth_service.dart';

typedef LoginSubmitCallback = void Function(String email, String password);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onLogin, this.onForgotPassword});

  final LoginSubmitCallback? onLogin;
  final ValueChanged<String>? onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isSendingReset = false;
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    if (widget.onLogin != null) {
      widget.onLogin!(_emailController.text.trim(), _passwordController.text);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authService.logIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      _showMessage('Signed in successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _loginError = AuthService.messageFor(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (_isSendingReset) return;
    if (email.isEmpty) {
      _showMessage('Enter your email address first.');
      return;
    }

    if (widget.onForgotPassword != null) {
      widget.onForgotPassword!(email);
      return;
    }

    setState(() => _isSendingReset = true);
    try {
      await _authService.resetPassword(email);
      if (!mounted) return;
      _showMessage('Password reset email sent.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(AuthService.messageFor(error));
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  void _showMessage(String message) => AppNotice.show(context, message);

  void _openCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth < 480
                            ? constraints.maxWidth
                            : 480.0,
                      ),
                      child: Column(
                        children: [
                          const AuthBrandHeader(
                            title: 'Welcome back!',
                            description: 'Sign in to manage your dorm listings or find your next home in Batangas City',
                            logoSize: 112,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: AuthFormCard(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                26,
                                28,
                                28,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const AuthFieldLabel(
                                      text: 'Email Address',
                                      trailing: 'Seeker or Landlord',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      onChanged: (_) {
                                        if (_loginError != null) {
                                          setState(() => _loginError = null);
                                        }
                                      },
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'\s'),
                                        ),
                                      ],
                                      decoration: authInputDecoration(
                                        context,
                                        hint: 'example@gmail.com',
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      validator: _validateEmail,
                                    ),
                                    const SizedBox(height: 18),
                                    const AuthFieldLabel(text: 'Password'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      onChanged: (_) {
                                        if (_loginError != null) {
                                          setState(() => _loginError = null);
                                        }
                                      },
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: authInputDecoration(
                                        context,
                                        hint: '••••••••••••',
                                        icon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: AppTheme.onSurfaceVariant
                                                .withValues(alpha: 0.72),
                                          ),
                                        ),
                                      ),
                                      validator: (value) =>
                                          (value ?? '').isEmpty
                                          ? 'Enter your password'
                                          : null,
                                    ),
                                    if (_loginError case final message?) ...[
                                      const SizedBox(height: 14),
                                      _LoginErrorBanner(message: message),
                                    ],
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isSendingReset
                                            ? null
                                            : _sendPasswordReset,
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.primaryContainer,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 40),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: AppTheme.primaryContainer,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : _submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryContainer,
                                          foregroundColor: AppTheme.onPrimary,
                                          elevation: 6,
                                          shadowColor: AppTheme.primary
                                              .withValues(alpha: 0.28),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isSubmitting
                                                  ? 'Signing In…'
                                                  : 'Sign In',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: AppTheme.onPrimary,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: AppTheme.onPrimary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.onSurfaceVariant,
                                      ),
                                ),
                                TextButton(
                                  onPressed: _openCreateAccount,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryContainer,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    minimumSize: const Size(0, 40),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Register',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Enter your email address';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to sign in',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
