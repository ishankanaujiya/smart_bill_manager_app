import 'package:flutter/material.dart';

import 'animated_welcome_entrance.dart';

/// The welcome illustration with a subtle scale + fade entrance.
///
/// Displays the bundled `welcome_screen_group_picture.png` on a transparent
/// background so the image itself handles all the styling.
class WelcomeHeroImage extends StatelessWidget {
  const WelcomeHeroImage({
    super.key,
    required this.animation,
  });

  /// Parent animation used for the scale/fade entrance.
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: WelcomeAnimationIntervals.illustration,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        final scale = 1.0 - (0.08 * (1 - t));
        final opacity = t.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/welcome_screen_group_picture.png',
        fit: BoxFit.contain,
        semanticLabel: 'Group of people splitting expenses',
      ),
    );
  }
}
