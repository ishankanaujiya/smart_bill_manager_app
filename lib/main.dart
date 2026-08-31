import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme/design_system.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/view/welcome_screen.dart';
import 'firebase_options.dart';

/// Global notifier for the app [ThemeMode].
///
/// Using a [ValueNotifier] lets the theme mode be switched from anywhere in the
/// app (e.g. settings) without prop-drilling or an extra dependency.
final ValueNotifier<ThemeMode> _themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Sign-In SDK (must be done before any sign-in attempt).
  await AuthRepositoryImpl.initializeGoogleSignIn();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SmartBillManagerApp(),
    ),
  );
}

class SmartBillManagerApp extends StatelessWidget {
  const SmartBillManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Smart Bill Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
