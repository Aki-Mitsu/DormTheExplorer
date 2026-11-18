import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'features/auth/presentation/login_screen.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const LoginScreen(),
    );
  }
}
