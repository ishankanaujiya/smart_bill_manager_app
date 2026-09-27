import 'package:flutter/material.dart';

/// Generic staggered entrance animation for any screen.
///
/// Wraps [child] with a fade + vertical slide that is driven by a single
/// shared [Animation<double>] and a per-widget [Interval]. Use this to build
/// professional, coordinated page-load animations without duplicating the
/// animation logic in every screen.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.animation,
    required this.interval,
    required this.child,
    this.slideOffset = 14,
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
    final curved = CurvedAnimation(parent: animation, curve: interval);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        final opacity = t.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slideOffset * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
