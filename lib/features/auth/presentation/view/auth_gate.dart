import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/presentation/app_shell.dart';
import '../state/auth_providers.dart';
import 'welcome_screen.dart';

/// Root routing widget that decides which screen the user lands on at
/// app launch.
///
/// Firebase Authentication persists the signed-in session to the device by
/// default. To honour the "remember me" checkbox on the sign-in screen we:
///
///  1. Read the persisted "remember me" flag from [SessionService].
///  2. If the flag is `false` (or absent) and a Firebase session happens to
///     still be on disk, sign the user out and clear the flag so they are
///     asked to sign in again.
///  3. If the flag is `true`, leave the persisted session in place — the user
///     is taken straight to the [AppShell] and stays signed in until they
///     explicitly sign out.
///
/// While the bootstrap decision is being made a branded splash is shown so
/// the user never sees a flash of the wrong screen.
///
/// Subsequent transitions (sign-in from [SignInScreen], sign-out from the
/// profile screen) are handled imperatively via `Navigator.pushAndRemoveUntil`
/// as in the rest of the auth flow.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final sessionService = ref.read(sessionServiceProvider);
    final authRepo = ref.read(authRepositoryProvider);

    final rememberMe = await sessionService.getRememberMe();

    // If the user did not opt into "remember me", clear any persisted
    // Firebase session so they have to sign in again on this launch.
    if (!rememberMe && authRepo.currentUser != null) {
      await authRepo.signOut();
      await sessionService.clear();
    }

    if (!mounted) return;
    setState(() => _bootstrapped = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) {
      return const _AuthGateSplash();
    }

    final user = ref.read(authRepositoryProvider).currentUser;
    return user != null ? const AppShell() : const WelcomeScreen();
  }
}

/// Branded splash shown while [AuthGate] reads secure storage and decides
/// the initial route.
///
/// Uses the brand gradient on a surface background so the launch feels
/// intentional regardless of the active theme.
class _AuthGateSplash extends StatelessWidget {
  const _AuthGateSplash();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkPrimaryGradient
                    : AppColors.lightPrimaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
