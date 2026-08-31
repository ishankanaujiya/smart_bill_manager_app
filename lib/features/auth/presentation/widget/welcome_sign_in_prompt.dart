import 'package:flutter/material.dart';

import 'animated_welcome_entrance.dart';

/// Footer prompt that lets existing users navigate to the sign-in screen.
class WelcomeSignInPrompt extends StatelessWidget {
  const WelcomeSignInPrompt({
    super.key,
    required this.animation,
    this.onSignInTap,
  });

  /// Parent animation for the fade entrance.
  final Animation<double> animation;

  /// Called when the user taps the "Sign in" text.
  final VoidCallback? onSignInTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedWelcomeEntrance(
      animation: animation,
      interval: WelcomeAnimationIntervals.footer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: onSignInTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign in',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
