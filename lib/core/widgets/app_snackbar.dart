import 'package:flutter/material.dart';

import '../../app/theme/design_system.dart';

/// Severity of an [AppSnackBar].
enum AppSnackBarType {
  /// Success feedback — green accent.
  success,

  /// Error feedback — red accent.
  error,

  /// Informational feedback — blue accent.
  info,

  /// Warning feedback — amber accent.
  warning,
}

/// A highly polished, animated snackbar used across the registration flow.
///
/// Features:
///  - A leading circular icon badge that pops in with an elastic scale.
///  - A title + optional message body.
///  - A subtle leading-edge accent stripe coloured by severity.
///  - A depleting progress bar at the bottom that tracks the snackbar's
///    lifetime, so the user can see how long it will remain on screen.
///  - A floating, rounded, elevated surface that respects the app's
///    [AppRadius] and [AppSpacing] design tokens.
///
/// Use [AppSnackBar.show] to surface one via [ScaffoldMessenger].
class AppSnackBar {
  const AppSnackBar._();

  /// Shows an [AppSnackBar] using the nearest [ScaffoldMessenger].
  ///
  /// [title] is always shown; [message] is optional supporting copy.
  /// [duration] controls how long the snackbar stays on screen (the
  /// progress bar depletes over this duration). Pass [withAction] label
  /// and [onAction] to render a trailing text action.
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: _AppSnackBarContent(
          title: title,
          message: message,
          type: type,
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content widget
// ─────────────────────────────────────────────────────────────────────────────

class _AppSnackBarContent extends StatefulWidget {
  const _AppSnackBarContent({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? message;
  final AppSnackBarType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_AppSnackBarContent> createState() => _AppSnackBarContentState();
}

class _AppSnackBarContentState extends State<_AppSnackBarContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 0,
    );

    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.elasticOut),
      ),
    );

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    // Start the lifetime countdown on the next frame so the entrance
    // (icon pop) is visible before the progress bar begins depleting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _paletteFor(widget.type, colorScheme);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm + 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Leading accent stripe
                  Container(
                    width: 4,
                    height: widget.message != null ? 44 : 32,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Icon badge with elastic pop-in
                  ScaleTransition(
                    scale: _iconScale,
                    child: _IconBadge(
                      icon: palette.icon,
                      color: palette.accent,
                      onColor: palette.onAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Title + message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        if (widget.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.message!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Optional action
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: widget.onAction,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Progress bar (fills left → right over the snackbar's lifetime) ──
            AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                return LinearProgressIndicator(
                  value: _progress.value,
                  minHeight: 3,
                  backgroundColor: palette.accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                  borderRadius: BorderRadius.circular(2),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon badge
// ─────────────────────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.radiusMd,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Severity palette
// ─────────────────────────────────────────────────────────────────────────────

class _SnackBarPalette {
  const _SnackBarPalette({
    required this.accent,
    required this.onAccent,
    required this.icon,
  });

  final Color accent;
  final Color onAccent;
  final IconData icon;
}

_SnackBarPalette _paletteFor(AppSnackBarType type, ColorScheme colorScheme) {
  switch (type) {
    case AppSnackBarType.success:
      return _SnackBarPalette(
        accent: AppColors.success,
        onAccent: Colors.white,
        icon: Icons.check_circle_rounded,
      );
    case AppSnackBarType.error:
      return _SnackBarPalette(
        accent: colorScheme.error,
        onAccent: colorScheme.onError,
        icon: Icons.error_outline_rounded,
      );
    case AppSnackBarType.warning:
      return _SnackBarPalette(
        accent: AppColors.warning,
        onAccent: Colors.white,
        icon: Icons.warning_amber_rounded,
      );
    case AppSnackBarType.info:
      return _SnackBarPalette(
        accent: colorScheme.primary,
        onAccent: colorScheme.onPrimary,
        icon: Icons.info_outline_rounded,
      );
  }
}
