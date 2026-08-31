import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import 'animated_welcome_entrance.dart';

/// Animated headline block for the welcome screen.
///
/// Renders:
/// - "Welcome to" — muted label
/// - "Group Expense Splitter" — two-line primary headline
/// - "Manage together. Split easily." — muted subtitle
class WelcomeHeadline extends StatelessWidget {
  const WelcomeHeadline({
    super.key,
    required this.animation,
  });

  /// Parent animation that drives the staggered text reveals.
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedWelcomeEntrance(
          animation: animation,
          interval: WelcomeAnimationIntervals.welcomeLabel,
          child: Text(
            'Welcome to',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedWelcomeEntrance(
          animation: animation,
          interval: WelcomeAnimationIntervals.headlineFirst,
          child: Text(
            'Group Expense',
            style: AppTextStyles.headlineLarge.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        AnimatedWelcomeEntrance(
          animation: animation,
          interval: WelcomeAnimationIntervals.headlineSecond,
          child: Text(
            'Splitter',
            style: AppTextStyles.headlineLarge.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedWelcomeEntrance(
          animation: animation,
          interval: WelcomeAnimationIntervals.subtitle,
          child: Text(
            'Manage together. Split easily.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
