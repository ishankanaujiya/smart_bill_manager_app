import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Header block used on authentication screens.
///
/// Renders the design-spec header:
///  - Decorative network pattern (circles + lines) to the right of the logo
///  - App logo (rounded primary square + group icon, nudged slightly down)
///  - "Group Expense Splitter" brand mark with "Splitter" in primary
///  - Title + subtitle stacked beneath the brand with a compact gap
///
/// All elements are staggered into view using the supplied [animation].
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.animation,
    required this.title,
    this.subtitle,
  });

  final Animation<double> animation;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const logoSize = 52.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final patternWidth =
            (constraints.maxWidth - logoSize - 24).clamp(160.0, 230.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Network pattern — positioned to the right of the logo.
            Positioned(
              top: 0,
              left: logoSize - 4,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
                ),
                child: SizedBox(
                  width: patternWidth,
                  height: 100,
                  child: CustomPaint(
                    painter: _NetworkPatternPainter(
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),

            // Foreground content
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),

                // Logo with soft primary glow.
                StaggeredEntrance(
                  animation: animation,
                  interval: const Interval(
                    0.0,
                    0.45,
                    curve: Curves.easeOutCubic,
                  ),
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: AppRadius.radiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.18 : 0.30,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: const Alignment(0, 0.25),
                      child: Icon(
                        Icons.groups_rounded,
                        size: 28,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Brand text directly below the logo.
                StaggeredEntrance(
                  animation: animation,
                  interval: const Interval(
                    0.05,
                    0.50,
                    curve: Curves.easeOutCubic,
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: 'Group Expense ',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: 'Splitter',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Title
                StaggeredEntrance(
                  animation: animation,
                  interval: const Interval(
                    0.15,
                    0.60,
                    curve: Curves.easeOutCubic,
                  ),
                  child: Text(
                    title,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StaggeredEntrance(
                    animation: animation,
                    interval: const Interval(
                      0.22,
                      0.65,
                      curve: Curves.easeOutCubic,
                    ),
                    child: Text(
                      subtitle!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Network pattern
// ─────────────────────────────────────────────────────────────────────────────

/// Paints a sparse network of circles + lines that originates near the logo.
///
/// The pattern has three visible nodes (large primary, small blue, small green)
/// connected by thin lines from the left edge of the painter.
class _NetworkPatternPainter extends CustomPainter {
  const _NetworkPatternPainter({
    required this.colorScheme,
    required this.isDark,
  });

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.14);

    final origin = Offset(w * 0.02, h * 0.26);

    final large = _Node(
      Offset(w * 0.28, h * 0.08),
      6.5,
      colorScheme.primary,
    );

    final blue = _Node(
      Offset(w * 0.82, h * 0.12),
      4.5,
      colorScheme.secondary,
    );

    final green = _Node(
      Offset(w * 0.72, h * 0.75),
      4.0,
      colorScheme.tertiary,
    );

    final nodes = [large, blue, green];

    canvas.drawLine(origin, large.offset, linePaint);
    canvas.drawLine(large.offset, blue.offset, linePaint);
    canvas.drawLine(large.offset, green.offset, linePaint);

    for (final node in nodes) {
      final glowPaint = Paint()
        ..color = node.color.withValues(alpha: isDark ? 0.16 : 0.10)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(node.offset, node.radius * 2.2, glowPaint);

      final nodePaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(node.offset, node.radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPatternPainter old) =>
      old.colorScheme != colorScheme || old.isDark != isDark;
}

class _Node {
  const _Node(this.offset, this.radius, this.color);

  final Offset offset;
  final double radius;
  final Color color;
}
