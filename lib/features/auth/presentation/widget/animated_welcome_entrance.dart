import 'package:flutter/material.dart';

/// Reusable staggered entrance animation for the welcome screen.
///
/// Wraps [child] with a fade + vertical slide that is driven by a single
/// shared [Animation<double>] and a per-widget [interval]. This keeps the
/// animation orchestrated while still being easy to compose.
class AnimatedWelcomeEntrance extends StatelessWidget {
  const AnimatedWelcomeEntrance({
    super.key,
    required this.animation,
    required this.interval,
    required this.child,
    this.slideOffset = 24,
  });

  /// The parent animation controller (0.0 → 1.0).
  final Animation<double> animation;

  /// The time window in which this element animates.
  final Interval interval;

  /// The child to animate.
  final Widget child;

  /// How far the child starts below its final position.
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: interval,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, slideOffset * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Shared animation intervals for the welcome screen so the staggered order
/// is centralized and easy to tweak.
abstract final class WelcomeAnimationIntervals {
  WelcomeAnimationIntervals._();

  /// Duration of the full orchestration.
  static const Duration duration = Duration(milliseconds: 1600);

  static const Interval welcomeLabel = Interval(0.00, 0.35, curve: Curves.easeOutCubic);
  static const Interval headlineFirst = Interval(0.12, 0.45, curve: Curves.easeOutCubic);
  static const Interval headlineSecond = Interval(0.22, 0.55, curve: Curves.easeOutCubic);
  static const Interval subtitle = Interval(0.32, 0.65, curve: Curves.easeOutCubic);
  static const Interval illustration = Interval(0.20, 0.75, curve: Curves.easeOutBack);
  static const Interval button = Interval(0.55, 0.85, curve: Curves.easeOutCubic);
  static const Interval footer = Interval(0.65, 0.95, curve: Curves.easeOutCubic);
}
