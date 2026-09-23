import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_shell.dart';
import '../state/auth_providers.dart';
import 'splash_screen.dart';
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
/// While the bootstrap decision is being made the branded [SplashScreen] is
/// shown so the user never sees a flash of the wrong screen. We only hand off
/// once BOTH the bootstrap and the splash animation have completed.
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
  /// Whether the async bootstrap (reading secure storage / signing out) has
  /// finished.
  bool _bootstrapped = false;

  /// Whether the splash animation has finished playing at least once.
  bool _splashDone = false;

  /// Whether we've already swapped away from the splash.
  bool _transitioned = false;

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
    _maybeTransition();
  }

  /// Called by the splash when its animation completes. We only transition
  /// once BOTH the bootstrap and the animation are done.
  void _onSplashComplete() {
    if (!mounted) return;
    setState(() => _splashDone = true);
    _maybeTransition();
  }

  void _maybeTransition() {
    if (_transitioned || !_bootstrapped || !_splashDone) return;
    setState(() => _transitioned = true);
  }

  @override
  Widget build(BuildContext context) {
    // Show the splash until both the bootstrap and the animation are done.
    if (!_transitioned) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    final user = ref.read(authRepositoryProvider).currentUser;
    return user != null ? const AppShell() : const WelcomeScreen();
  }
}
