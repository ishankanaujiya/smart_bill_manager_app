import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme/design_system.dart';
import 'core/notifications/notification_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/view/auth_gate.dart';
import 'firebase_options.dart';

/// Global navigator key used by [NotificationService] to push screens in
/// response to notification taps, even from a cold start.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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

  // Initialize OneSignal push notifications.
  await NotificationService.instance.initialize();

  // Re-tag this device when the user is already signed in from a previous
  // session (cold start). The auth listeners inside the app won't fire a
  // sign-in event in this case, so we tag here proactively.
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await NotificationService.instance.login(currentUser.uid);
  }

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

  // Register the notification tap (click) handler after the widget tree is
  // built so the navigator key is attached and ready for navigation.
  NotificationService.instance.setupClickHandler(appNavigatorKey);
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
          navigatorKey: appNavigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}
