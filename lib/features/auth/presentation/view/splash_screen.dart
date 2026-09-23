import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/design_system.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Splash screen
// ═════════════════════════════════════════════════════════════════════════════

/// Animated, branded splash screen shown at app launch.
///
/// Reproduces the reference "Settle" splash design in Flutter using the
/// app's design system:
///  - drifting aurora blobs on a masked grid with a subtle grain texture
///  - expanding ripple rings
///  - rising currency particles
///  - a breathing logo tile with orbiting dots, the brand artwork,
///    a coin badge and an animated sheen
///  - a per-letter wordmark entrance and an expanding tagline
///  - a sweeping loader bar with a live percentage
///
/// All colours come from [AppSplashPalette]; all typography from
/// [AppTextStyles]; component geometry lives in [_Spec]. No design value is
/// hard-coded in the widget tree.
///
/// Calls [onComplete] once the intro has finished and the exit fade has
/// played, so the parent can hand off to the next screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  /// Invoked after the entrance animation and exit fade complete.
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Entrance (one-shot) ────────────────────────────────────────────────────
  late final AnimationController _intro;
  late final AnimationController _exit;

  // ── Ambient loops ──────────────────────────────────────────────────────────
  late final AnimationController _auroraA;
  late final AnimationController _auroraB;
  late final AnimationController _auroraC;
  late final AnimationController _ripple;
  late final AnimationController _particles;
  late final AnimationController _spinFast;
  late final AnimationController _spinSlow;
  late final AnimationController _breathe;
  late final AnimationController _glow;
  late final AnimationController _sheen;
  late final AnimationController _loader;
  late final AnimationController _percent;

  @override
  void initState() {
    super.initState();

    // Entrance timeline — all entrance intervals are expressed as fractions
    // of this controller's duration.
    _intro = AnimationController(vsync: this, duration: _Spec.introDuration);
    _exit = AnimationController(vsync: this, duration: _Spec.exitDuration);

    _auroraA = AnimationController(vsync: this, duration: _Spec.auroraADuration)
      ..repeat();
    _auroraB = AnimationController(vsync: this, duration: _Spec.auroraBDuration)
      ..repeat();
    _auroraC = AnimationController(vsync: this, duration: _Spec.auroraCDuration)
      ..repeat();

    _ripple =
        AnimationController(vsync: this, duration: _Spec.rippleDuration)
          ..repeat();
    _particles =
        AnimationController(vsync: this, duration: _Spec.particleMaster)
          ..repeat();

    _spinFast = AnimationController(vsync: this, duration: _Spec.spinFastDuration)
      ..repeat();
    _spinSlow =
        AnimationController(vsync: this, duration: _Spec.spinSlowDuration)
          ..repeat(reverse: true);

    _breathe =
        AnimationController(vsync: this, duration: _Spec.breatheDuration);
    _glow = AnimationController(vsync: this, duration: _Spec.glowDuration)
      ..repeat();
    _sheen = AnimationController(vsync: this, duration: _Spec.sheenDuration)
      ..repeat();
    _loader = AnimationController(vsync: this, duration: _Spec.loaderDuration)
      ..repeat();
    _percent =
        AnimationController(vsync: this, duration: _Spec.percentDuration)
          ..repeat();

    _runEntrance();
  }

  /// Plays the entrance, then the exit fade, then notifies the parent.
  Future<void> _runEntrance() async {
    // The breathe loop starts after a short delay, in parallel with the
    // entrance timeline (rather than blocking it).
    Future<void>.delayed(_Spec.breatheDelay, () {
      if (mounted) _breathe.repeat(reverse: true);
    });

    await _intro.forward();
    if (!mounted) return;

    await Future<void>.delayed(_Spec.holdBeforeExit);
    if (!mounted) return;

    await _exit.forward();
    if (!mounted) return;

    widget.onComplete();
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    _auroraA.dispose();
    _auroraB.dispose();
    _auroraC.dispose();
    _ripple.dispose();
    _particles.dispose();
    _spinFast.dispose();
    _spinSlow.dispose();
    _breathe.dispose();
    _glow.dispose();
    _sheen.dispose();
    _loader.dispose();
    _percent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppSplashPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_exit),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _intro,
            _auroraA,
            _auroraB,
            _auroraC,
            _ripple,
            _particles,
            _spinFast,
            _spinSlow,
            _breathe,
            _glow,
            _sheen,
            _loader,
            _percent,
          ]),
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Drifting aurora backdrop.
                CustomPaint(
                  painter: _AuroraPainter(
                    palette: palette,
                    driftA: _pulse(_auroraA.value),
                    driftB: _pulse(_auroraB.value),
                    driftC: _pulse(_auroraC.value),
                  ),
                ),

                // 2. Masked grid texture.
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const RadialGradient(
                    center: _Spec.gridMaskCenter,
                    radius: _Spec.gridMaskRadius,
                    colors: [Colors.black, Colors.transparent],
                    stops: _Spec.gridMaskStops,
                  ).createShader(rect),
                  child: CustomPaint(
                    painter: _GridPainter(color: palette.gridLine),
                  ),
                ),

                // 3. Subtle grain.
                CustomPaint(
                  painter: _GrainPainter(
                    color: palette.wordmark.withValues(alpha: 0.04),
                  ),
                ),

                // 4. Expanding ripple rings.
                Align(
                  alignment: _Spec.rippleAlignment,
                  child: CustomPaint(
                    size: const Size.square(_Spec.rippleSize),
                    painter: _RipplePainter(
                      color: palette.ripple,
                      progress: _ripple.value,
                    ),
                  ),
                ),

                // 5. Rising currency particles.
                _ParticleLayer(
                  palette: palette,
                  progress: _particles.value,
                ),

                // 6. Foreground content.
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LogoMark(
                      palette: palette,
                      intro: _intro,
                      spinFast: _spinFast.value,
                      spinSlow: _spinSlow.value,
                      breathe: _pulse(_breathe.value),
                      glow: _pulse(_glow.value),
                      sheen: _pulse(_sheen.value),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    _Wordmark(
                      palette: palette,
                      intro: _intro,
                      text: _Spec.wordmark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Tagline(
                      palette: palette,
                      intro: _intro,
                      text: _Spec.tagline,
                    ),
                  ],
                ),

                // 7. Loader pinned to the bottom.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: _Spec.loaderBottomInset,
                    ),
                    child: _Loader(
                      palette: palette,
                      sweep: _loader.value,
                      percent: _percent.value * 100,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Maps a 0→1 linear controller value to a smooth 0→1→0 pulse.
  static double _pulse(double t) => (1 - math.cos(math.pi * 2 * t)) * 0.5;
}

// ═════════════════════════════════════════════════════════════════════════════
// Logo mark
// ═════════════════════════════════════════════════════════════════════════════

/// The central logo tile: halo, orbiting dots, sheen border, brand artwork and
/// coin badge.
class _LogoMark extends StatelessWidget {
  const _LogoMark({
    required this.palette,
    required this.intro,
    required this.spinFast,
    required this.spinSlow,
    required this.breathe,
    required this.glow,
    required this.sheen,
  });

  final AppSplashPalette palette;
  final Animation<double> intro;
  final double spinFast;
  final double spinSlow;
  final double breathe;
  final double glow;
  final double sheen;

  @override
  Widget build(BuildContext context) {
    // Entrance: tile pops in.
    final tileIn = CurvedAnimation(
      parent: intro,
      curve: _Spec.tileInterval,
    ).drive(CurveTween(curve: _Spec.popCurve));

    // Entrance: coin badge springs in.
    final badgeIn = CurvedAnimation(
      parent: intro,
      curve: _Spec.badgeInterval,
    ).drive(CurveTween(curve: _Spec.badgeCurve));

    // Entrance: the brand artwork fades and scales in once the tile has
    // popped, echoing the tile's own spring.
    final logoIn = CurvedAnimation(
      parent: intro,
      curve: _Spec.logoInterval,
    ).drive(CurveTween(curve: _Spec.popCurve));

    return Transform.scale(
      // Breathe: 1.0 → 1.045 → 1.0.
      scale: 1.0 + 0.045 * breathe,
      child: SizedBox.square(
        dimension: _Spec.markSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Halo — extends beyond the tile, matching the design's outset glow.
            Positioned.fill(
              child: Transform.scale(
                scale: _Spec.glowScale * (1.0 + 0.15 * glow),
                child: Opacity(
                  opacity: 0.55 + 0.45 * glow,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.markGlow,
                          palette.markGlow.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.68],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Outer (slow, reverse) orbit.
            _Orbit(
              outset: _Spec.orbitSlowInset,
              angle: -spinSlow * 2 * math.pi,
              dotSize: _Spec.orbitSlowDot,
              gradient: palette.orbitDotGreen,
              glow: palette.orbitDotGreenGlow,
            ),

            // Inner (fast) orbit.
            _Orbit(
              outset: _Spec.orbitFastInset,
              angle: spinFast * 2 * math.pi,
              dotSize: _Spec.orbitFastDot,
              gradient: palette.orbitDotGold,
              glow: palette.orbitDotGoldGlow,
            ),

            // Tile with sheen border.
            Opacity(
              opacity: tileIn.value.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: (1 - tileIn.value) * -14 * math.pi / 180,
                child: Transform.scale(
                  scale: 0.4 + 0.6 * tileIn.value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: _Spec.tileRadius,
                      gradient: palette.tileGradient,
                      boxShadow: [
                        BoxShadow(
                          color: palette.tileGradient.colors.first
                              .withValues(alpha: 0.40),
                          blurRadius: 46,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      foregroundPainter: _SheenPainter(
                        radius: _Spec.tileRadius.topLeft.x,
                        opacity: 0.4 + 0.5 * sheen,
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: logoIn.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _Spec.logoScaleStart +
                                (1 - _Spec.logoScaleStart) * logoIn.value,
                            child: SvgPicture.asset(
                              _Spec.logoAsset,
                              width: _Spec.logoSize,
                              height: _Spec.logoSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Coin badge.
            Positioned(
              top: _Spec.badgeOffset,
              right: _Spec.badgeOffset,
              child: Opacity(
                opacity: badgeIn.value.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: (1 - badgeIn.value) * -40 * math.pi / 180,
                  child: Transform.scale(
                    scale: badgeIn.value.clamp(0.0, 1.4),
                    child: Container(
                      width: _Spec.badgeSize,
                      height: _Spec.badgeSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: palette.coinGradient,
                        boxShadow: [
                          BoxShadow(
                            color: palette.coinGradient.colors.last
                                .withValues(alpha: 0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Text(
                        _Spec.currencyGlyph,
                        style: AppTextStyles.splashCoinBadge.copyWith(
                          color: palette.coinText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rotating ring with a single glowing dot at its top edge.
///
/// [outset] expands the ring beyond the logo tile; the parent [Stack] uses
/// `Clip.none` so the overflow is visible.
class _Orbit extends StatelessWidget {
  const _Orbit({
    required this.outset,
    required this.angle,
    required this.dotSize,
    required this.gradient,
    required this.glow,
  });

  final double outset;
  final double angle;
  final double dotSize;
  final LinearGradient gradient;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -outset,
      top: -outset,
      right: -outset,
      bottom: -outset,
      child: Transform.rotate(
        angle: angle,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: glow,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a rounded-rect gradient border whose opacity pulses — the "sheen".
class _SheenPainter extends CustomPainter {
  const _SheenPainter({required this.radius, required this.opacity});

  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.5 * opacity),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.3 * opacity),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SheenPainter old) =>
      old.opacity != opacity || old.radius != radius;
}

// ═════════════════════════════════════════════════════════════════════════════
// Wordmark & tagline
// ═════════════════════════════════════════════════════════════════════════════

/// The brand wordmark, animated in one letter at a time.
class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.palette,
    required this.intro,
    required this.text,
  });

  final AppSplashPalette palette;
  final Animation<double> intro;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.splashWordmark.copyWith(
      color: palette.wordmark,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          _AnimatedLetter(
            letter: text[i],
            style: style,
            animation: CurvedAnimation(
              parent: intro,
              curve: _Spec.letterInterval(i),
            ).drive(CurveTween(curve: _Spec.letterCurve)),
          ),
      ],
    );
  }
}

class _AnimatedLetter extends StatelessWidget {
  const _AnimatedLetter({
    required this.letter,
    required this.style,
    required this.animation,
  });

  final String letter;
  final TextStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, _Spec.letterRise * (1 - t)),
            child: child,
          ),
        );
      },
      child: Text(letter, style: style),
    );
  }
}

/// Uppercase tagline whose letter-spacing expands as it fades in.
class _Tagline extends StatelessWidget {
  const _Tagline({
    required this.palette,
    required this.intro,
    required this.text,
  });

  final AppSplashPalette palette;
  final Animation<double> intro;
  final String text;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: intro,
      curve: _Spec.taglineInterval,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        final base = AppTextStyles.splashTagline;

        return Opacity(
          opacity: t,
          child: Text(
            text.toUpperCase(),
            style: base.copyWith(
              color: palette.tagline,
              letterSpacing: (base.letterSpacing ?? 0) * t,
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Loader
// ═════════════════════════════════════════════════════════════════════════════

/// Sweeping progress bar with a live percentage read-out.
class _Loader extends StatelessWidget {
  const _Loader({
    required this.palette,
    required this.sweep,
    required this.percent,
  });

  final AppSplashPalette palette;

  /// 0→1 position of the fill within the track.
  final double sweep;
  final double percent;

  @override
  Widget build(BuildContext context) {
    // The fill slides from fully off the left to fully off the right.
    final trackWidth = _Spec.loaderWidth;
    final fillWidth = trackWidth * _Spec.loaderFillFraction;
    final left = (-fillWidth) +
        (trackWidth + fillWidth) * sweep;

    // Hue shift: slide the gradient window back and forth.
    final shift = sweep * 2 - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_Spec.loaderHeight),
          child: SizedBox(
            width: trackWidth,
            height: _Spec.loaderHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: palette.loaderTrack),
                ),
                Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: fillWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(shift - 1, 0),
                        end: Alignment(shift + 1, 0),
                        colors: palette.loaderGradient.colors,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${percent.floor()}%',
          style: AppTextStyles.splashLoaderPercent.copyWith(
            color: palette.loaderPercent,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Backdrop layers
// ═════════════════════════════════════════════════════════════════════════════

/// Three soft, drifting radial blobs that form the aurora backdrop.
class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.palette,
    required this.driftA,
    required this.driftB,
    required this.driftC,
  });

  final AppSplashPalette palette;
  final double driftA;
  final double driftB;
  final double driftC;

  @override
  void paint(Canvas canvas, Size size) {
    _blob(
      canvas,
      size,
      color: palette.auroraBlob1,
      center: _Spec.auroraBlob1,
      radius: _Spec.auroraBlob1Radius,
      drift: driftA,
      move: _Spec.auroraDriftA,
      scaleTo: 1.20,
    );
    _blob(
      canvas,
      size,
      color: palette.auroraBlob2,
      center: _Spec.auroraBlob2,
      radius: _Spec.auroraBlob2Radius,
      drift: driftB,
      move: _Spec.auroraDriftB,
      scaleTo: 1.15,
    );
    _blob(
      canvas,
      size,
      color: palette.auroraBlob3,
      center: _Spec.auroraBlob3,
      radius: _Spec.auroraBlob3Radius,
      drift: driftC,
      move: _Spec.auroraDriftC,
      scaleTo: 0.85,
    );
  }

  void _blob(
    Canvas canvas,
    Size size, {
    required Color color,
    required Offset center,
    required double radius,
    required double drift,
    required Offset move,
    required double scaleTo,
  }) {
    final c = Offset(
      center.dx * size.width + move.dx * drift,
      center.dy * size.height + move.dy * drift,
    );

    final r = radius * (1.0 + (scaleTo - 1.0) * drift);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 0.7],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _Spec.auroraBlur);

    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.palette != palette ||
      old.driftA != driftA ||
      old.driftB != driftB ||
      old.driftC != driftC;
}

/// Hairline grid texture (masked radially by the caller).
class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += _Spec.gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += _Spec.gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

/// A very subtle film-grain speckle, generated once from a fixed seed.
class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.color});

  final Color color;

  /// Deterministic speckle positions (normalised 0→1).
  static final List<Offset> _speckles = _generate();

  static List<Offset> _generate() {
    final random = math.Random(1337);
    return List<Offset>.generate(
      _Spec.grainDots,
      (_) => Offset(random.nextDouble(), random.nextDouble()),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final s in _speckles) {
      canvas.drawRect(
        Rect.fromLTWH(
          s.dx * size.width,
          s.dy * size.height,
          _Spec.grainDotSize,
          _Spec.grainDotSize,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.color != color;
}

/// Four expanding, fading concentric rings.
class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    for (var i = 0; i < _Spec.rippleCount; i++) {
      // Each ring is offset in time by an equal fraction of the cycle.
      final p = (progress - i / _Spec.rippleCount) % 1.0;

      final eased = _Spec.rippleCurve.transform(p);
      final radius = maxRadius * (0.4 + 0.6 * eased);

      // Fade in over the first 12 %, then out over the remainder.
      final opacity = p < 0.12 ? p / 0.12 : 1 - (p - 0.12) / 0.88;
      if (opacity <= 0) continue;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.color != color;
}

/// Rising "₹" glyphs and accent dots.
class _ParticleLayer extends StatelessWidget {
  const _ParticleLayer({required this.palette, required this.progress});

  final AppSplashPalette palette;

  /// 0→1 across [_Spec.particleMaster].
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final rise = height * _Spec.particleRiseFraction;

          return Stack(
            children: [
              for (final p in _Spec.particles)
                _Particle(
                  spec: p,
                  palette: palette,
                  // Map the shared clock onto this particle's own period.
                  progress: ((progress * _Spec.particleMasterSeconds -
                              p.delay) /
                          p.duration) %
                      1.0,
                  rise: rise,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  const _Particle({
    required this.spec,
    required this.palette,
    required this.progress,
    required this.rise,
  });

  final _ParticleSpec spec;
  final AppSplashPalette palette;
  final double progress;
  final double rise;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    // Opacity: 0 → 1 (10 %) → 1 (90 %) → 0 (100 %).
    final opacity = p < 0.10
        ? p / 0.10
        : (p > 0.90 ? (1 - p) / 0.10 : 1.0);

    final color = spec.isGlyph
        ? palette.particleGold
        : (spec.gold ? palette.particleGoldDot : palette.particleGreen);

    return Positioned.fill(
      child: Transform.translate(
        // Start just below the bottom edge, then rise up the screen.
        offset: Offset(0, _Spec.particleStartOffset - rise * p),
        child: Align(
          // Map the horizontal fraction (0→1) onto the alignment axis (-1→1).
          alignment: Alignment(spec.left * 2 - 1, 1.0),
          child: Transform.rotate(
            angle: p * 30 * math.pi / 180,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: spec.isGlyph
                  ? Text(
                      _Spec.currencyGlyph,
                      style: AppTextStyles.splashCoinBadge.copyWith(
                        color: color,
                        fontSize: spec.fontSize,
                      ),
                    )
                  : Container(
                      width: spec.size,
                      height: spec.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Spec — component geometry & timing
// ═════════════════════════════════════════════════════════════════════════════

/// Component-level geometry and timing for the splash.
///
/// Kept in one place so the widget tree stays free of magic numbers. These are
/// component dimensions (sizes, positions, animation periods), not design
/// tokens — colours and typography come from the design system.
abstract final class _Spec {
  _Spec._();

  // ── Content ──
  static const String wordmark = 'Tabora';
  static const String tagline = 'Split fair · Settle faster';
  static const String currencyGlyph = 'Rs';

  /// Brand artwork rendered inside the logo tile.
  static const String logoAsset = 'assets/icons/tabora.svg';

  // ── Timing ──
  static const Duration introDuration = Duration(milliseconds: 2500);
  static const Duration exitDuration = Duration(milliseconds: 400);
  static const Duration holdBeforeExit = Duration(milliseconds: 350);
  static const Duration breatheDelay = Duration(milliseconds: 1100);

  static const Duration auroraADuration = Duration(seconds: 13);
  static const Duration auroraBDuration = Duration(seconds: 16);
  static const Duration auroraCDuration = Duration(seconds: 11);

  /// One ring expands over this period. Kept deliberately long so the ripples
  /// stay calm and uncluttered rather than pulsing rapidly.
  static const Duration rippleDuration = Duration(milliseconds: 4200);
  static const Duration spinFastDuration = Duration(seconds: 7);
  static const Duration spinSlowDuration = Duration(seconds: 12);
  static const Duration breatheDuration = Duration(milliseconds: 3600);
  static const Duration glowDuration = Duration(milliseconds: 2600);
  static const Duration sheenDuration = Duration(milliseconds: 3400);
  static const Duration loaderDuration = Duration(milliseconds: 1600);
  static const Duration percentDuration = Duration(milliseconds: 2600);

  /// Longest particle animation; drives the shared particle clock.
  static const double particleMasterSeconds = 9.5;
  static const Duration particleMaster = Duration(milliseconds: 9500);

  // ── Curves ──
  static const Cubic popCurve = Cubic(0.2, 1.4, 0.4, 1.0);
  static const Cubic badgeCurve = Cubic(0.2, 1.6, 0.4, 1.0);
  static const Cubic letterCurve = Cubic(0.2, 0.9, 0.3, 1.0);
  static const Cubic rippleCurve = Cubic(0.2, 0.7, 0.3, 1.0);

  // ── Entrance intervals (fractions of [introDuration]) ──
  static const Interval tileInterval = Interval(0.06, 0.42);
  static const Interval badgeInterval = Interval(0.40, 0.64);
  static const Interval taglineInterval = Interval(0.62, 0.98);

  /// Brand artwork entrance — starts after the tile has popped.
  static const Interval logoInterval = Interval(0.24, 0.58);

  /// Per-letter entrance interval (60 ms stagger, 550 ms each).
  static Interval letterInterval(int index) {
    const start = 0.288; // 720 ms
    const step = 0.024; // 60 ms
    const span = 0.22; // 550 ms
    final s = start + step * index;
    return Interval(s, (s + span).clamp(0.0, 1.0));
  }

  static const double letterRise = 16;

  // ── Logo mark ──
  static const double markSize = 118;
  static const double orbitFastInset = 22;
  static const double orbitSlowInset = 38;
  static const double orbitFastDot = 9;
  static const double orbitSlowDot = 6;
  static const double badgeSize = 36;
  static const double badgeOffset = -10;

  /// Halo diameter relative to the tile (≈ (118 + 2×36) / 118).
  static const double glowScale = 1.61;

  /// Brand artwork side length inside the tile.
  static const double logoSize = 64;

  /// Brand artwork entrance scale (0→1 maps to this→1).
  static const double logoScaleStart = 0.7;
  static final BorderRadius tileRadius = BorderRadius.circular(32);

  // ── Grid ──
  static const double gridSize = 28;
  static const Alignment gridMaskCenter = Alignment(0, -0.36);
  static const double gridMaskRadius = 0.75;
  static const List<double> gridMaskStops = [0.35, 0.75];

  // ── Grain ──
  static const int grainDots = 900;
  static const double grainDotSize = 1;

  // ── Aurora ──
  static const Offset auroraBlob1 = Offset(0.25, 0.19);
  static const Offset auroraBlob2 = Offset(0.83, 1.02);
  static const Offset auroraBlob3 = Offset(0.69, 0.59);
  static const double auroraBlob1Radius = 160;
  static const double auroraBlob2Radius = 140;
  static const double auroraBlob3Radius = 120;
  static const Offset auroraDriftA = Offset(40, 30);
  static const Offset auroraDriftB = Offset(-30, -40);
  static const Offset auroraDriftC = Offset(-25, 20);
  static const double auroraBlur = 28;

  // ── Ripples ──
  /// Only two rings are in flight at once — enough to read as "ripples"
  /// without crowding the logo. Each is offset by half the cycle, so a new
  /// ring is emitted every [rippleDuration] / 2.
  static const int rippleCount = 2;
  static const double rippleSize = 560;
  static const Alignment rippleAlignment = Alignment(0, -0.38);

  // ── Particles ──
  /// Vertical offset (below the bottom edge) the particles start from.
  static const double particleStartOffset = 30;
  static const double particleRiseFraction = 0.85;
  static const List<_ParticleSpec> particles = [
    _ParticleSpec(left: 0.08, size: 16, fontSize: 9, isGlyph: true,
        duration: 7.5, delay: 0.2),
    _ParticleSpec(left: 0.20, size: 6, fontSize: 0, gold: false,
        duration: 6.0, delay: 1.6),
    _ParticleSpec(left: 0.33, size: 12, fontSize: 7, isGlyph: true,
        duration: 9.0, delay: 0.8),
    _ParticleSpec(left: 0.48, size: 5, fontSize: 0, gold: true,
        duration: 7.0, delay: 2.4),
    _ParticleSpec(left: 0.62, size: 18, fontSize: 10, isGlyph: true,
        duration: 8.5, delay: 0.4),
    _ParticleSpec(left: 0.74, size: 7, fontSize: 0, gold: false,
        duration: 6.5, delay: 3.0),
    _ParticleSpec(left: 0.85, size: 14, fontSize: 8, isGlyph: true,
        duration: 9.5, delay: 1.2),
    _ParticleSpec(left: 0.93, size: 6, fontSize: 0, gold: true,
        duration: 7.8, delay: 2.0),
  ];

  // ── Loader ──
  static const double loaderWidth = 132;
  static const double loaderHeight = 4;
  static const double loaderFillFraction = 0.36;
  static const double loaderBottomInset = 52;
}

/// Geometry + timing for a single rising particle.
@immutable
class _ParticleSpec {
  const _ParticleSpec({
    required this.left,
    required this.size,
    required this.fontSize,
    required this.duration,
    required this.delay,
    this.isGlyph = false,
    this.gold = false,
  });

  /// Horizontal position as a fraction of screen width.
  final double left;
  final double size;

  /// Font size when [isGlyph]; ignored for dots.
  final double fontSize;

  /// Animation duration in seconds.
  final double duration;

  /// Start delay in seconds.
  final double delay;

  /// Whether this particle renders the currency glyph instead of a dot.
  final bool isGlyph;

  /// For dots: `true` → gold accent, `false` → green accent.
  final bool gold;
}
