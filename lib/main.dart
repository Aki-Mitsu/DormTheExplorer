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

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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
        if (user == null) return const LoginScreen();

        return FutureBuilder<String?>(
          key: ValueKey(user.uid),
          future: AuthService().getRole(user.uid),
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
