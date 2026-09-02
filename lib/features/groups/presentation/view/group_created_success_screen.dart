import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../domain/entities/group.dart';

/// A polished, full-screen celebration shown after a group is created.
///
/// Design highlights:
/// - Layered gradient backdrop with smoothly floating geometric shapes.
/// - Animated check ring + group avatar with breathing glow.
/// - Solid primary-color stat pills (Members / Created By / Created At).
/// - Unique members card with member rows, role badges, and a gradient
///   header strip.
/// - Solid primary button matching the sign-in screen.
///
/// Every element is staggered off a single master controller.
class GroupCreatedSuccessScreen extends StatefulWidget {
  const GroupCreatedSuccessScreen({
    super.key,
    required this.group,
    this.onDone,
    this.onAddAnother,
  });

  final Group group;
  final VoidCallback? onDone;
  final VoidCallback? onAddAnother;

  @override
  State<GroupCreatedSuccessScreen> createState() =>
      _GroupCreatedSuccessScreenState();
}

class _GroupCreatedSuccessScreenState extends State<GroupCreatedSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _ambient;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _particles = _ConfettiParticle.generate(36);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _master.forward();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _ambient.repeat();
      });
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Animation<double> _interval(double start, double end,
          {Curve curve = Curves.easeOutCubic}) =>
      CurvedAnimation(
          parent: _master, curve: Interval(start, end, curve: curve));

  Widget _stagger(Widget child, double start, double end,
      {double slide = 28, Curve curve = Curves.easeOutCubic}) {
    final anim = _interval(start, end, curve: curve);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) {
        final t = anim.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slide * (1 - t)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Stack(
          children: [
            _LayeredBackdrop(
              colorScheme: colorScheme,
              isDark: isDark,
              ambient: _ambient,
            ),
            Positioned.fill(
              child: _ConfettiBurst(
                controller: _master,
                particles: _particles,
                screenSize: screenSize,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - AppSpacing.xl * 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          _buildHero(colorScheme, isDark),
                          const SizedBox(height: AppSpacing.xxl),
                          _stagger(_buildTitle(colorScheme), 0.30, 0.44),
                          const SizedBox(height: AppSpacing.xs),
                          _stagger(
                              _buildSubtitle(colorScheme), 0.34, 0.47),
                          const SizedBox(height: AppSpacing.xxl),
                          _stagger(
                            _buildStatStrip(colorScheme, isDark),
                            0.40,
                            0.56,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _stagger(
                            _buildMembersCard(colorScheme, isDark),
                            0.48,
                            0.64,
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          _stagger(
                            _buildDoneButton(colorScheme, isDark),
                            0.60,
                            0.76,
                            slide: 36,
                          ),
                          if (widget.onAddAnother != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _stagger(
                              _buildAddAnotherButton(colorScheme),
                              0.66,
                              0.80,
                              slide: 36,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Hero
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildHero(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _BreathingGlow(ambient: _ambient, colorScheme: colorScheme),
            _CheckRing(master: _master, colorScheme: colorScheme),
            _GroupAvatarPop(
              master: _master,
              group: widget.group,
              colorScheme: colorScheme,
              isDark: isDark,
            ),
            ..._buildOrbitingDots(colorScheme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrbitingDots(ColorScheme colorScheme) {
    return [
      _OrbitingDot(
          ambient: _ambient,
          colorScheme: colorScheme,
          color: colorScheme.primary,
          radius: 100,
          startAngle: 0,
          size: 8),
      _OrbitingDot(
          ambient: _ambient,
          colorScheme: colorScheme,
          color: colorScheme.tertiary,
          radius: 100,
          startAngle: math.pi,
          size: 6),
      _OrbitingDot(
          ambient: _ambient,
          colorScheme: colorScheme,
          color: colorScheme.primary.withValues(alpha: 0.6),
          radius: 110,
          startAngle: math.pi / 2,
          size: 5),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────
  // Title + subtitle — solid primary color (matches sign-in button)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTitle(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small "SUCCESS" eyebrow label in primaryContainer style.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: AppRadius.radiusFull,
            ),
            child: Text(
              'SUCCESS',
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Group Created!',
            style: AppTextStyles.headlineMedium.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(ColorScheme colorScheme) {
    return Center(
      child: Text(
        '"${widget.group.groupName}" is ready to go.\nStart splitting bills with your group.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Stat strip — Members / Created By / Created At
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatStrip(ColorScheme colorScheme, bool isDark) {
    final admin = widget.group.groupAdmin;
    final adminName = (admin.displayName?.isNotEmpty == true
            ? admin.displayName!
            : admin.fullName)
        .split(' ')
        .first;

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            master: _master,
            start: 0.40,
            end: 0.54,
            icon: Icons.group_rounded,
            label: 'Members',
            value: '${widget.group.memberCount}',
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            master: _master,
            start: 0.43,
            end: 0.57,
            icon: Icons.person_rounded,
            label: 'Created By',
            value: adminName,
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            master: _master,
            start: 0.46,
            end: 0.60,
            icon: Icons.event_available_rounded,
            label: 'Created At',
            value: _formatDate(widget.group.createdAt),
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Members card — unique design with header strip + member rows
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildMembersCard(ColorScheme colorScheme, bool isDark) {
    final members = widget.group.members;
    final visible = members.take(5).toList();
    final overflow = members.length - visible.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.6)
            : colorScheme.surface,
        borderRadius: AppRadius.radiusXl,
        border: Border.all(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header strip — primary with subtle gradient depth.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xl),
                topRight: Radius.circular(AppRadius.xl),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusXs,
                  ),
                  child: Icon(Icons.people_alt_rounded,
                      color: colorScheme.onPrimary, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Members',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusFull,
                  ),
                  child: Text(
                    '${widget.group.memberCount}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Member rows.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: [
                for (int i = 0; i < visible.length; i++) ...[
                  _MemberRow(
                    master: _master,
                    index: i,
                    member: visible[i],
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  if (i < visible.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxs),
                      child: Divider(
                        height: 1,
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                ],
                if (overflow > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs),
                    child: Divider(
                      height: 1,
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.6),
                    ),
                  ),
                  _OverflowRow(
                    master: _master,
                    index: visible.length,
                    count: overflow,
                    colorScheme: colorScheme,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Action buttons — solid primary (matches sign-in button)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDoneButton(ColorScheme colorScheme, bool isDark) {
    return _TapScale(
      onTap: () {
        widget.onDone?.call();
        if (mounted) Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: AppRadius.radiusMd,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: colorScheme.onPrimary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Done',
              style: AppTextStyles.labelLarge.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAnotherButton(ColorScheme colorScheme) {
    return Center(
      child: _TapScale(
        onTap: () => widget.onAddAnother?.call(),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: AppRadius.radiusFull,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Add another group',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Layered backdrop — gradient + smoothly floating shapes
// ═════════════════════════════════════════════════════════════════════════════

class _LayeredBackdrop extends StatelessWidget {
  const _LayeredBackdrop({
    required this.colorScheme,
    required this.isDark,
    required this.ambient,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final AnimationController ambient;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ]
                  : [
                      Color(0xFFF0FDFA),
                      Color(0xFFF8FAFC),
                      Color(0xFFEFF6FF),
                    ],
            ),
          ),
        ),
        // Smoothly floating shapes — sine wave gives 0→1→0 ping-pong.
        // Each uses a different shade/variant of the primary family.
        _FloatingShape(
          ambient: ambient,
          color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.16),
          top: 50,
          left: -30,
          size: 120,
          shape: _ShapeType.ring,
          floatDistance: 16,
          phase: 0.0,
        ),
        _FloatingShape(
          ambient: ambient,
          color: colorScheme.tertiary.withValues(alpha: isDark ? 0.10 : 0.14),
          top: 100,
          right: -20,
          size: 90,
          shape: _ShapeType.plus,
          floatDistance: 12,
          phase: 0.25,
        ),
        _FloatingShape(
          ambient: ambient,
          color: colorScheme.primaryContainer
              .withValues(alpha: isDark ? 0.15 : 0.25),
          bottom: 80,
          left: -15,
          size: 70,
          shape: _ShapeType.ring,
          floatDistance: 10,
          phase: 0.5,
        ),
        _FloatingShape(
          ambient: ambient,
          color: colorScheme.tertiary.withValues(alpha: isDark ? 0.08 : 0.11),
          bottom: 180,
          right: -10,
          size: 100,
          shape: _ShapeType.plus,
          floatDistance: 14,
          phase: 0.75,
        ),
      ],
    );
  }
}

enum _ShapeType { ring, plus }

class _FloatingShape extends StatelessWidget {
  const _FloatingShape({
    required this.ambient,
    required this.color,
    required this.size,
    required this.shape,
    required this.floatDistance,
    required this.phase,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final AnimationController ambient;
  final Color color;
  final double size;
  final _ShapeType shape;
  final double floatDistance;
  final double phase;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        // Smooth sine wave: 0 → 1 → 0 → 1 → 0 (ping-pong, no snap).
        final v = (math.sin((ambient.value + phase) * math.pi * 2) * 0.5 + 0.5);
        return Transform.translate(
          offset: Offset(0, -floatDistance * v),
          child: child,
        );
      },
      child: Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: CustomPaint(
          size: Size(size, size),
          painter: _ShapePainter(color: color, shape: shape),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.color, required this.shape});

  final Color color;
  final _ShapeType shape;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    switch (shape) {
      case _ShapeType.ring:
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          size.width / 2 - 4,
          paint,
        );
        break;
      case _ShapeType.plus:
        final cx = size.width / 2;
        final cy = size.height / 2;
        final arm = size.width * 0.3;
        canvas.drawLine(
          Offset(cx - arm, cy),
          Offset(cx + arm, cy),
          paint,
        );
        canvas.drawLine(
          Offset(cx, cy - arm),
          Offset(cx, cy + arm),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => old.color != color;
}

// ═════════════════════════════════════════════════════════════════════════════
// Breathing glow
// ═════════════════════════════════════════════════════════════════════════════

class _BreathingGlow extends StatelessWidget {
  const _BreathingGlow({required this.ambient, required this.colorScheme});

  final AnimationController ambient;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final v = (math.sin(ambient.value * math.pi * 2) * 0.5 + 0.5);
        return Transform.scale(
          scale: 0.85 + v * 0.25,
          child: Opacity(
            opacity: 0.15 + v * 0.35,
            child: child,
          ),
        );
      },
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
              colorScheme.primary.withValues(alpha: 0),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Orbiting dots
// ═════════════════════════════════════════════════════════════════════════════

class _OrbitingDot extends StatelessWidget {
  const _OrbitingDot({
    required this.ambient,
    required this.colorScheme,
    required this.color,
    required this.radius,
    required this.startAngle,
    required this.size,
  });

  final AnimationController ambient;
  final ColorScheme colorScheme;
  final Color color;
  final double radius;
  final double startAngle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final angle = startAngle + ambient.value * math.pi * 2;
        return Transform.translate(
          offset: Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Animated check ring
// ═════════════════════════════════════════════════════════════════════════════

class _CheckRing extends StatelessWidget {
  const _CheckRing({required this.master, required this.colorScheme});

  final AnimationController master;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final ring = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );
    final check = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.30, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    final pop = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.35, 0.50, curve: Curves.easeOutBack),
      ),
    );

    return AnimatedBuilder(
      animation: master,
      builder: (context, child) {
        return Transform.scale(scale: pop.value, child: child);
      },
      child: SizedBox(
        width: 150,
        height: 150,
        child: CustomPaint(
          painter: _CheckRingPainter(
            ringProgress: ring.value,
            checkProgress: check.value,
            ringColor: colorScheme.primary,
            trackColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
            checkColor: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _CheckRingPainter extends CustomPainter {
  _CheckRingPainter({
    required this.ringProgress,
    required this.checkProgress,
    required this.ringColor,
    required this.trackColor,
    required this.checkColor,
  });

  final double ringProgress;
  final double checkProgress;
  final Color ringColor;
  final Color trackColor;
  final Color checkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;
    const startAngle = -math.pi / 2;
    final sweep = math.pi * 1.5 * ringProgress;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final p1 =
          Offset(center.dx - radius * 0.32, center.dy + radius * 0.02);
      final p2 =
          Offset(center.dx - radius * 0.05, center.dy + radius * 0.28);
      final p3 =
          Offset(center.dx + radius * 0.38, center.dy - radius * 0.28);

      if (checkProgress <= 0.4) {
        final t = checkProgress / 0.4;
        canvas.drawLine(p1, Offset.lerp(p1, p2, t)!, checkPaint);
      } else {
        canvas.drawLine(p1, p2, checkPaint);
        final t = (checkProgress - 0.4) / 0.6;
        canvas.drawLine(p2, Offset.lerp(p2, p3, t)!, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckRingPainter old) =>
      old.ringProgress != ringProgress ||
      old.checkProgress != checkProgress;
}

// ═════════════════════════════════════════════════════════════════════════════
// Group avatar pop — solid primary
// ═════════════════════════════════════════════════════════════════════════════

class _GroupAvatarPop extends StatelessWidget {
  const _GroupAvatarPop({
    required this.master,
    required this.group,
    required this.colorScheme,
    required this.isDark,
  });

  final AnimationController master;
  final Group group;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.40, 0.65, curve: Curves.linear),
      ),
    );
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: master,
        curve: const Interval(0.40, 0.50, curve: Curves.easeIn),
      ),
    );

    final initials = _initials(group.groupName);
    final hasPicture =
        group.groupPicture != null && group.groupPicture!.isNotEmpty;

    return AnimatedBuilder(
      animation: master,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value,
          child: Transform.scale(scale: scale.value, child: child),
        );
      },
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasPicture ? null : colorScheme.primaryContainer,
          border: Border.all(color: colorScheme.surface, width: 4),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          image: hasPicture
              ? DecorationImage(
                  image: NetworkImage(group.groupPicture!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasPicture
            ? null
            : Center(
                child: Text(
                  initials,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) {
      return parts[0].characters.take(2).toString().toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Stat pill — solid primary icon, clean card
// ═════════════════════════════════════════════════════════════════════════════

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.master,
    required this.start,
    required this.end,
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.isDark,
  });

  final AnimationController master;
  final double start;
  final double end;
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: master,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = anim.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(
            alpha: isDark ? 0.35 : 0.5,
          ),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppRadius.radiusSm,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: colorScheme.onPrimary, size: 18),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.7,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Member row — avatar + name + role badge
// ═════════════════════════════════════════════════════════════════════════════

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.master,
    required this.index,
    required this.member,
    required this.colorScheme,
    required this.isDark,
  });

  final AnimationController master;
  final int index;
  final GroupMember member;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final start = (0.48 + index * 0.05).clamp(0.0, 0.88);
    final end = (start + 0.12).clamp(0.0, 1.0);

    final slide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: master,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: master,
        curve: Interval(start, start + 0.08, curve: Curves.easeIn),
      ),
    );

    final name = member.displayName?.isNotEmpty == true
        ? member.displayName!
        : member.fullName;
    final initials = _initials(name);
    final hasPicture =
        member.profilePicture != null && member.profilePicture!.isNotEmpty;

    return AnimatedBuilder(
      animation: master,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(slide.value, 0),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          // Avatar — primaryContainer with onPrimaryContainer text.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasPicture
                  ? null
                  : colorScheme.primaryContainer.withValues(alpha: 0.8),
              border: Border.all(
                color: member.isAdmin
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.2),
                width: member.isAdmin ? 2.5 : 1.5,
              ),
              image: hasPicture
                  ? DecorationImage(
                      image: NetworkImage(member.profilePicture!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPicture
                ? null
                : Center(
                    child: Text(
                      initials,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Name.
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Role badge — admin uses primary, member uses primaryContainer.
          if (member.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppRadius.radiusFull,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded,
                      color: colorScheme.onPrimary, size: 12),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Admin',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: AppRadius.radiusFull,
              ),
              child: Text(
                'Member',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(
                    alpha: 0.8,
                  ),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].characters.take(2).toString().toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _OverflowRow extends StatelessWidget {
  const _OverflowRow({
    required this.master,
    required this.index,
    required this.count,
    required this.colorScheme,
  });

  final AnimationController master;
  final int index;
  final int count;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final start = (0.48 + index * 0.05).clamp(0.0, 0.88);
    final end = (start + 0.12).clamp(0.0, 1.0);

    final slide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: master,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: master,
        curve: Interval(start, start + 0.08, curve: Curves.easeIn),
      ),
    );

    return AnimatedBuilder(
      animation: master,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(slide.value, 0),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '+$count',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'more members',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Confetti — pre-generated, no per-frame allocation
// ═════════════════════════════════════════════════════════════════════════════

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.colorIndex,
    required this.width,
    required this.height,
    required this.spinDirection,
  });

  final double angle;
  final double speed;
  final int colorIndex;
  final double width;
  final double height;
  final int spinDirection;

  static List<_ConfettiParticle> generate(int count) {
    final random = math.Random(42);
    return List.generate(count, (i) {
      return _ConfettiParticle(
        angle: (i / count) * math.pi * 2 + random.nextDouble() * 0.3,
        speed: 180 + random.nextDouble() * 260,
        colorIndex: i % _ConfettiPainter.colors.length,
        width: 6 + random.nextDouble() * 6,
        height: 3 + random.nextDouble() * 3,
        spinDirection: random.nextBool() ? 1 : -1,
      );
    });
  }
}

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst({
    required this.controller,
    required this.particles,
    required this.screenSize,
  });

  final AnimationController controller;
  final List<_ConfettiParticle> particles;
  final Size screenSize;

  static const double _endFraction = 0.55;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.value >= _endFraction) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          size: screenSize,
          painter: _ConfettiPainter(
            progress: controller.value / _endFraction,
            particles: particles,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_ConfettiParticle> particles;

  static const colors = [
    Color(0xFF14B8A6),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height * 0.28);
    const gravity = 320.0;
    final t = progress;

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * t;
      final dy = math.sin(p.angle) * p.speed * t + gravity * t * t * 0.5;
      final pos = center + Offset(dx, dy);
      final opacity = (1 - t).clamp(0.0, 1.0);
      final rotation = t * math.pi * 4 * p.spinDirection;
      final color = colors[p.colorIndex];

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.width, height: p.height),
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

// ═════════════════════════════════════════════════════════════════════════════
// Tap-scale wrapper
// ═════════════════════════════════════════════════════════════════════════════

class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: widget.child,
      ),
    );
  }
}
