import 'package:flutter/material.dart';

import '../../app/theme/design_system.dart';

/// Animated error message shown below a form field.
///
/// Slides down and fades in when [errorText] becomes non-null, then slides
/// up and fades out when it disappears. Keeps height transitions smooth via
/// [AnimatedSize].
class AppFieldError extends StatelessWidget {
  const AppFieldError({
    super.key,
    this.errorText,
    this.isDark = false,
  });

  final String? errorText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(animation);

          return ClipRect(
            child: SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
          );
        },
        child: errorText != null
            ? Padding(
                key: ValueKey(errorText),
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        errorText!,
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(
                key: ValueKey('empty'),
                width: double.infinity,
              ),
      ),
    );
  }
}
