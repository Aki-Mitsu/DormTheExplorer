import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/dormitories/presentation/dorm_dashboard_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DormExplorerApp());
}

class DormExplorerApp extends StatelessWidget {
  const DormExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dorm the Explorer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.crimson,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _roleUserId;
  Future<String?>? _roleFuture;

  Future<String?> _roleFor(String userId) {
    if (_roleUserId != userId || _roleFuture == null) {
      _roleUserId = userId;
      _roleFuture = AuthService().getRole(userId);
    }
    return _roleFuture!;
  }

  void _clearRoleFuture() {
    _roleUserId = null;
    _roleFuture = null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return _AuthGateMessage(
            message: AuthService.messageFor(authSnapshot.error!),
            onSignOut: AuthService().signOut,
          );
        }
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          _clearRoleFuture();
          return const LoginScreen();
        }
        if (user.email != null && !user.emailVerified) {
          _clearRoleFuture();
          return _EmailVerificationGate(user: user);
        }

        return FutureBuilder<String?>(
          key: ValueKey(user.uid),
          future: _roleFor(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.hasError) {
              return _AuthGateMessage(
                message: AuthService.messageFor(roleSnapshot.error!),
                onSignOut: AuthService().signOut,
              );
            }
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScreen();
            }

            final role = roleSnapshot.data;
            if (role != 'seeker' && role != 'landlord') {
              return _AuthGateMessage(
                message: 'Your account does not have a valid Seeker or Landlord profile.',
                onSignOut: AuthService().signOut,
              );
            }

            return DormDashboardScreen(accountRole: role!, userId: user.uid);
          },
        );
      },
    );
  }
}

class _EmailVerificationGate extends StatefulWidget {
  const _EmailVerificationGate({required this.user});

  final User user;

  @override
  State<_EmailVerificationGate> createState() => _EmailVerificationGateState();
}

class _EmailVerificationGateState extends State<_EmailVerificationGate> {
  bool _isBusy = false;
  bool _isVerified = false;
  String? _message;

  Future<void> _checkVerification() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await widget.user.reload();
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final verified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (mounted) {
        setState(() {
          _isVerified = verified;
          _message = verified
              ? 'Email verified. You can continue.'
              : 'Email is not verified yet. Open the link in your inbox.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = AuthService.messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await widget.user.sendEmailVerification();
      if (mounted) {
        setState(() => _message = 'A new verification link was sent.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = AuthService.messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _isVerified ? Colors.green.shade700 : AppTheme.primaryContainer;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _isVerified
                        ? Icons.verified_rounded
                        : Icons.mark_email_unread_outlined,
                    size: 56,
                    color: color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVerified ? 'Email verified' : 'Verify your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isVerified
                        ? 'Your email is confirmed. Your account will open shortly.'
                        : 'Open the verification link sent to '
                            '${widget.user.email ?? 'your email address'}.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: color),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (!_isVerified) ...[
                    FilledButton(
                      onPressed: _isBusy ? null : _checkVerification,
                      child: _isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("I've verified my email"),
                    ),
                    TextButton(
                      onPressed: _isBusy ? null : _resendVerification,
                      child: const Text('Resend verification link'),
                    ),
                  ],
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthGateMessage extends StatelessWidget {
  const _AuthGateMessage({required this.message, required this.onSignOut});

  final String message;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_outlined, size: 42),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => onSignOut(),
                  child: const Text('Return to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
