import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme/design_system.dart';
import 'features/showcase/presentation/view/showcase_screen.dart';

/// Global notifier for the app's [ThemeMode].
///
/// Using a [ValueNotifier] keeps the theme-mode state outside the widget tree
/// so any screen can toggle it without prop-drilling or an extra dependency.
final ValueNotifier<ThemeMode> _themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

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
          home: ShowcaseScreen(
            themeMode: mode,
            onThemeModeChanged: (newMode) => _themeModeNotifier.value = newMode,
          ),
        );
      },
    );
  }
}
