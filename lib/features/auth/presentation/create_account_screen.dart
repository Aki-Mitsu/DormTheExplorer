import 'package:dorm_the_explorer/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

import 'auth_widgets.dart';
import 'terms_policy_dialog.dart';
import '../../../services/auth_service.dart';

typedef CreateAccountCallback = void Function({
  required String fullName,
  required String email,
  required String phone,
  required String password,
  required String role,
});

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, this.onCreateAccount});

  final CreateAccountCallback? onCreateAccount;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _isSubmitting = false;
  bool _isCheckingVerification = false;
  bool _pendingVerification = false;
  bool _emailVerified = false;
  String? _verificationEmail;
  String _role = 'seeker';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingVerification) {
      _checkEmailVerification(showMessage: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _reviewTerms() async {
    final accepted = await showTermsPolicyDialog(context);
    if (!mounted) return;
    setState(() {
      _acceptedTerms = accepted == true;
      if (_acceptedTerms) _showTermsError = false;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_pendingVerification) {
      await _checkEmailVerification();
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showTermsError = !_acceptedTerms);
    if (!isValid || !_acceptedTerms) return;

    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
      if (!mounted) return;
      setState(() {
        _pendingVerification = true;
        _verificationEmail = _emailController.text.trim();
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Verification link sent. Check your email.'),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AuthService.messageFor(error))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _checkEmailVerification({bool showMessage = true}) async {
    if (_isCheckingVerification) return;
    setState(() => _isCheckingVerification = true);
    try {
      final verified = await _authService.refreshEmailVerification();
      if (!mounted) return;
      setState(() => _emailVerified = verified);
      if (showMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                verified
                    ? 'Email verified. Finish your registration.'
                    : 'Email is not verified yet. Open the link in your inbox.',
              ),
            ),
          );
      }
    } catch (error) {
      if (mounted && showMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AuthService.messageFor(error))),
          );
      }
    } finally {
      if (mounted) setState(() => _isCheckingVerification = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _authService.resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('A new verification link was sent.')),
        );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AuthService.messageFor(error))),
          );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _finishRegistration() {
    if (!_emailVerified) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _emailVerificationCard() {
    final color = _emailVerified ? AppTheme.secondary : AppTheme.primaryContainer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: AuthFormCard(
        padding: const EdgeInsets.all(16),
        radius: 16,
        showShadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _emailVerified
                      ? Icons.verified_rounded
                      : Icons.mark_email_unread_outlined,
                  color: color,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _emailVerified ? 'Email verified' : 'Verify your email',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailVerified
                            ? 'Your email is confirmed. Finish creating your account.'
                            : 'Open the verification link sent to '
                                '${_verificationEmail ?? _emailController.text.trim()}.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_emailVerified)
              FilledButton.icon(
                onPressed: _finishRegistration,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Finish Registration'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                ),
              )
            else ...[
              FilledButton(
                onPressed: _isCheckingVerification
                    ? null
                    : () => _checkEmailVerification(),
                child: _isCheckingVerification
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("I've verified my email"),
              ),
              TextButton(
                onPressed: _isSubmitting ? null : _resendVerificationEmail,
                child: const Text('Resend verification link'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            AuthPageHeader(
              title: 'Create Account',
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        const AuthBrandHeader(
                          title: 'Create Account',
                          description: 'Join thousands finding trusted dorms & rooms in Batangas.',
                          logoSize: 56,
                          compact: true,
                          showPortalBadge: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I WANT TO:',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: AppTheme.onSurface,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _AccountTypeCard(
                                      selected: _role == 'seeker',
                                      icon: Icons.person_search,
                                      title: 'Seeker',
                                      subtitle: 'Students & Professionals',
                                      onTap: () =>
                                          setState(() => _role = 'seeker'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _AccountTypeCard(
                                      selected: _role == 'landlord',
                                      icon: Icons.home_work_outlined,
                                      title: 'Landlord',
                                      subtitle: 'Listing dorms & units',
                                      onTap: () =>
                                          setState(() => _role = 'landlord'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: AuthFormCard(
                            padding: const EdgeInsets.all(14),
                            radius: 16,
                            showShadow: false,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const AuthFieldLabel(text: 'Full Name'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: authInputDecoration(
                                      context,
                                      hint: 'e.g., Bea Santos',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    validator: (value) =>
                                        (value ?? '').trim().length < 2
                                        ? 'Enter your full name'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  const AuthFieldLabel(text: 'Email Address'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: authInputDecoration(
                                      context,
                                      hint: 'example@gmail.com',
                                      icon: Icons.mail_outline_rounded,
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 12),
                                  const AuthFieldLabel(text: 'Phone Number'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber,
                                    ],
                                    decoration: authInputDecoration(
                                      context,
                                      hint: '0912 345 6789',
                                      icon: Icons.call_outlined,
                                    ),
                                    validator: _validatePhone,
                                  ),
                                  const SizedBox(height: 12),
                                  const AuthFieldLabel(text: 'Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    decoration: authInputDecoration(
                                      context,
                                      hint: 'Enter secure password',
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: _PasswordVisibilityButton(
                                        isObscured: _obscurePassword,
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        (value ?? '').length < 6
                                        ? 'Use at least 6 characters'
                                        : null,
                                  ),
                                  const SizedBox(height: 3),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: 13,
                                          color: AppTheme.onSurfaceVariant
                                              .withValues(alpha: 0.75),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Minimum 6 characters',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppTheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const AuthFieldLabel(
                                    text: 'Confirm Password',
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: authInputDecoration(
                                      context,
                                      hint: 'Re-enter password',
                                      icon: Icons.verified_user_outlined,
                                      suffixIcon: _PasswordVisibilityButton(
                                        isObscured: _obscureConfirmPassword,
                                        onPressed: () => setState(
                                          () => _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value != _passwordController.text
                                        ? 'Passwords do not match'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    if (value == true) {
                                      _reviewTerms();
                                    } else {
                                      setState(() {
                                        _acceptedTerms = false;
                                        _showTermsError = false;
                                      });
                                    }
                                  },
                                  activeColor: AppTheme.primaryContainer,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: InkWell(
                                  onTap: _reviewTerms,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text.rich(
                                      TextSpan(
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.onSurfaceVariant,
                                            ),
                                        children: const [
                                          TextSpan(
                                            text: 'I have read and agree to the ',
                                          ),
                                          TextSpan(
                                            text: 'Terms and Conditions',
                                            style: TextStyle(
                                              color: AppTheme.primaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' and the '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppTheme.primaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: '.'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showTermsError)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 42,
                              right: 18,
                              top: 2,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Please accept the terms to continue.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.error),
                              ),
                            ),
                          ),
                        if (_pendingVerification)
                          _emailVerificationCard()
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryContainer,
                                  foregroundColor: AppTheme.onPrimary,
                                  elevation: 5,
                                  shadowColor: AppTheme.primary.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isSubmitting
                                          ? 'Creating Account…'
                                          : 'Create Account',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: AppTheme.onPrimary),
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
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.maybePop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: AppTheme.primaryContainer,
                                ),
                                child: Text(
                                  'Sign In',
                                  style: Theme.of(context).textTheme.labelLarge
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

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length < 10 ? 'Enter a valid phone number' : null;
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppTheme.primaryDeep
        : AppTheme.onSurfaceVariant;

    return Material(
      color: selected ? AppTheme.primaryFixed : AppTheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 86,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.surfaceContainerLowest
                            : AppTheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 17, color: foreground),
                    ),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.check_circle_outline_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: selected ? AppTheme.primaryDeep : AppTheme.outline,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppTheme.onSurface, height: 1.1),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    required this.isObscured,
    required this.onPressed,
  });

  final bool isObscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isObscured ? 'Show password' : 'Hide password',
      onPressed: onPressed,
      icon: Icon(
        isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 18,
        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
    );
  }
}
