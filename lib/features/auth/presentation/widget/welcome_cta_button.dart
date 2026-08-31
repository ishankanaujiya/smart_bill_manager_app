import 'package:flutter/material.dart';

import 'animated_welcome_entrance.dart';

/// Full-width primary CTA for the welcome screen.
///
/// Uses the theme's [ElevatedButtonThemeData] so it adapts to light/dark
/// mode automatically and is driven by the shared page animation.
class WelcomeCtaButton extends StatelessWidget {
  const WelcomeCtaButton({
    super.key,
    required this.animation,
    this.onPressed,
  });

  /// Parent animation for the slide-up entrance.
  final Animation<double> animation;

  /// Called when the user taps the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedWelcomeEntrance(
      animation: animation,
      interval: WelcomeAnimationIntervals.button,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: const Text('Get Started'),
        ),
      ),
    );
  }
}
