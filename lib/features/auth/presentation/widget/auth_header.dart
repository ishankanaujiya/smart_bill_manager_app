import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Header block used on authentication screens.
///
/// Renders the design-spec header:
///  - Decorative network pattern (circles + lines) to the right of the logo.
///    Each node gently pulses (scale + glow + opacity) on a staggered phase
///    so the header feels alive and professional.
///  - App logo (rounded primary square + group icon, nudged slightly down)
///  - "Group Expense Splitter" brand mark with "Splitter" in primary
///  - Title + subtitle stacked beneath the brand with a compact gap
///
/// The entrance is staggered using the supplied [animation]. The pulse loop
/// is driven by an internal [AnimationController] that lives for the lifetime
/// of the widget.
class AuthHeader extends StatefulWidget {
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
  State<AuthHeader> createState() => _AuthHeaderState();
}

class _AuthHeaderState extends State<AuthHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const logoSize = 52.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Network pattern — spans the full header width so that
            // coordinates inside the painter map directly to the screen.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: widget.animation,
                  curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
                ),
                child: SizedBox(
                  width: fullWidth,
                  height: 140,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _NetworkPatternPainter(
                          colorScheme: colorScheme,
                          isDark: isDark,
                          pulse: _pulseController.value,
                        ),
                      );
                    },
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
                  animation: widget.animation,
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

                const SizedBox(height: AppSpacing.md),

                // Brand text directly below the logo.
                StaggeredEntrance(
                  animation: widget.animation,
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
                  animation: widget.animation,
                  interval: const Interval(
                    0.15,
                    0.60,
                    curve: Curves.easeOutCubic,
                  ),
                  child: Text(
                    widget.title,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),

                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StaggeredEntrance(
                    animation: widget.animation,
                    interval: const Interval(
                      0.22,
                      0.65,
                      curve: Curves.easeOutCubic,
                    ),
                    child: Text(
                      widget.subtitle!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        // fontSize: 13,
                        fontWeight: FontWeight.w500,
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
/// Each node gently pulses on a staggered phase derived from [pulse] so the
/// pattern feels alive without being distracting. The pulse modulates:
///  - node radius (subtle scale, ±18 %)
///  - glow radius and alpha
///  - core opacity (a soft "blink")
class _NetworkPatternPainter extends CustomPainter {
  const _NetworkPatternPainter({
    required this.colorScheme,
    required this.isDark,
    required this.pulse,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final double pulse; // 0..1, loops forever

  /// Returns a 0..1 pulse envelope for a node with the given phase offset.
  ///
  /// Uses a smooth sine bell so the node swells and fades gently rather than
  /// snapping on/off. [phase] shifts the wave so nodes don't all blink in
  /// unison — this is what makes the motion feel professional.
  double _nodePulse(double phase) {
    final t = (pulse + phase) % 1.0;
    return 0.5 - 0.5 * math.cos(2 * math.pi * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.14);

    // Origin — at the logo icon's visual center.
    // The foreground Column has 24px top padding (AppSpacing.xxl), then the
    // logo is 52px tall with the 28px icon nudged down via Alignment(0, 0.25).
    // Icon center Y ≈ 24 + 26 + 3 ≈ 53px from the top of the header.
    // Icon center X ≈ 26px (half of the 52px logo).
    // The line emerges from inside the icon, hidden by the logo container.
    final origin = Offset(26.0, 53.0);

    // Each node has a phase offset so they pulse in sequence.
    // Node 0 is the large primary "middle" node; the others branch from it.
    // Coordinates map to the full screen width (w) and 140px height (h).
    final nodes = <_Node>[
      _Node(Offset(w * 0.45, h * 0.06), 6.5, colorScheme.primary, 0.00),
      _Node(Offset(w * 0.85, h * 0.22), 4.5, colorScheme.secondary, 0.33),
      _Node(Offset(w * 0.72, h * 0.45), 4.0, colorScheme.tertiary, 0.66),
      _Node(Offset(w * 0.40, h * 0.55), 4.0, colorScheme.secondary, 0.50),
    ];

    // Draw lines first so they sit behind nodes.
    canvas.drawLine(origin, nodes[0].offset, linePaint);
    canvas.drawLine(nodes[0].offset, nodes[1].offset, linePaint);
    canvas.drawLine(nodes[0].offset, nodes[2].offset, linePaint);
    canvas.drawLine(nodes[0].offset, nodes[3].offset, linePaint);

    // Draw filled circles only — no glow ring, no stroke.
    // The pulse animates scale and opacity for a clean "blink" effect.
    for (final node in nodes) {
      final p = _nodePulse(node.phase); // 0..1 bell curve

      // Scale radius subtly (±18 %).
      final scale = 1.0 + 0.18 * (p - 0.5) * 2; // 0.82..1.18
      final radius = node.radius * scale;

      // Opacity dips at the trough — the "blink".
      final coreAlpha = 0.55 + 0.45 * p;
      final nodePaint = Paint()
        ..color = node.color.withValues(alpha: coreAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node.offset, radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPatternPainter old) =>
      old.colorScheme != colorScheme ||
      old.isDark != isDark ||
      old.pulse != pulse;
}

class _Node {
  const _Node(this.offset, this.radius, this.color, this.phase);

  final Offset offset;
  final double radius;
  final Color color;
  final double phase; // 0..1 offset within the pulse loop
}
