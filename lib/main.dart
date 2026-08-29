import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme/design_system.dart';
import 'features/auth/presentation/view/welcome_screen.dart';

/// Global notifier for the app [ThemeMode].
///
/// Using a [ValueNotifier] lets the theme mode be switched from anywhere in the
/// app (e.g. settings) without prop-drilling or an extra dependency.
final ValueNotifier<ThemeMode> _themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SmartBillManagerApp());
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
