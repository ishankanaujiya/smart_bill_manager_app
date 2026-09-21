import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/presentation/app_shell.dart';
import '../state/auth_providers.dart';
import 'welcome_screen.dart';

/// Root routing widget that decides which screen the user lands on at
/// app launch.
///
/// Firebase Authentication persists the signed-in session to the device by
/// default. To honour the "remember me" checkbox on the sign-in screen we:
///
///  1. Read the persisted "remember me" flag from [SessionService].
///  2. If the flag is `false` (or absent) and a Firebase session happens to
///     still be on disk, sign the user out and clear the flag so they are
///     asked to sign in again.
///  3. If the flag is `true`, leave the persisted session in place — the user
///     is taken straight to the [AppShell] and stays signed in until they
///     explicitly sign out.
///
/// While the bootstrap decision is being made a branded splash is shown so
/// the user never sees a flash of the wrong screen.
///
/// Subsequent transitions (sign-in from [SignInScreen], sign-out from the
/// profile screen) are handled imperatively via `Navigator.pushAndRemoveUntil`
/// as in the rest of the auth flow.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  /// Whether the async bootstrap (reading secure storage / signing out) has
  /// finished.
  bool _bootstrapped = false;

  /// Whether the splash animation has finished playing at least once.
  bool _splashDone = false;

  /// Whether we've already swapped away from the splash.
  bool _transitioned = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final sessionService = ref.read(sessionServiceProvider);
    final authRepo = ref.read(authRepositoryProvider);

    final rememberMe = await sessionService.getRememberMe();

    // If the user did not opt into "remember me", clear any persisted
    // Firebase session so they have to sign in again on this launch.
    if (!rememberMe && authRepo.currentUser != null) {
      await authRepo.signOut();
      await sessionService.clear();
    }

    if (!mounted) return;
    setState(() => _bootstrapped = true);
    _maybeTransition();
  }

  /// Called by the splash when its entrance animation completes. We only
  /// transition once BOTH the bootstrap and the animation are done.
  void _onSplashComplete() {
    if (!mounted) return;
    setState(() => _splashDone = true);
    _maybeTransition();
  }

  void _maybeTransition() {
    if (_transitioned || !_bootstrapped || !_splashDone) return;
    setState(() => _transitioned = true);
  }

  @override
  Widget build(BuildContext context) {
    // Show the splash until both the bootstrap and the animation are done.
    if (!_transitioned) {
      return _AnimatedSplash(onComplete: _onSplashComplete);
    }

    final user = ref.read(authRepositoryProvider).currentUser;
    return user != null ? const AppShell() : const WelcomeScreen();
  }
}

/// Highly animated branded splash screen shown at app launch.
///
/// Plays a full entrance animation sequence (~2.8 s) and then calls
/// [onComplete] so the parent can transition to the real app. A smooth
/// fade-out is applied just before the callback fires so the hand-off to
/// the next screen feels seamless.
///
/// Animation sequence (total ≈ 2.8 s):
///   0.0 – 0.6 s  Background gradient fade-in + particle burst
///   0.2 – 0.9 s  Logo container scale + glow pulse
///   0.5 – 1.0 s  Icon flip-in (Y-axis rotation)
///   0.8 – 1.4 s  App name slides up + fades in
///   1.1 – 1.6 s  Tagline fades in
///   1.5 – 2.8 s  Progress bar fills left-to-right
///   2.8 – 3.2 s  Fade-out exit
///   Ongoing      Outer ring orbits + inner ring counter-orbits
class _AnimatedSplash extends StatefulWidget {
  const _AnimatedSplash({required this.onComplete});

  /// Invoked once the entrance animation has completed and the fade-out
  /// is about to finish.
  final VoidCallback onComplete;

  @override
  State<_AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<_AnimatedSplash>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  late final AnimationController _masterCtrl;   // drives the full sequence
  late final AnimationController _orbitCtrl;    // continuous orbit ring
  late final AnimationController _pulseCtrl;    // continuous glow pulse
  late final AnimationController _progressCtrl; // loading bar
  late final AnimationController _fadeCtrl;     // exit fade-out

  // ── Sequence animations (driven by _masterCtrl, 0→1 over 2.8 s) ──────────
  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFlip;
  late final Animation<double> _glowOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _taglineFade;

  /// Guard so [widget.onComplete] is only called once.
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    // Master timeline: 2.8 s, runs once.
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Exit fade: 400 ms, starts when the master animation finishes.
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Fire the entrance animation on the next frame so the first frame
    // paints at progress = 0 (otherwise the controller may already be
    // part-way through on some devices).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _masterCtrl.forward();
    });

    // When the entrance animation finishes, start the fade-out and then
    // notify the parent.
    _masterCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        _fadeCtrl.forward().then((_) {
          if (mounted) widget.onComplete();
        });
      }
    });

    // Continuous orbit: 4 s per revolution.
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Continuous glow pulse: 1.6 s.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Progress bar: starts at 1.5 s, fills over 1.3 s.
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _progressCtrl.forward();
    });

    // ── Sequence curves ───────────────────────────────────────────────────
    _bgFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.22, curve: Curves.easeIn),
    );

    _logoScale = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.07, 0.32, curve: Curves.elasticOut),
    );

    _logoFlip = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.18, 0.36, curve: Curves.easeOutBack),
    );

    _glowOpacity = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.07, 0.40, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.28, 0.50, curve: Curves.easeOutCubic),
    ));

    _titleFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.28, 0.52, curve: Curves.easeIn),
    );

    _taglineFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.39, 0.57, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final gradientStart = isDark
        ? AppColors.darkPrimaryGradientStart
        : AppColors.lightPrimaryGradientStart;
    final gradientEnd = isDark
        ? AppColors.darkPrimaryGradientEnd
        : AppColors.lightPrimaryGradientEnd;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      body: FadeTransition(
        // Fade the entire splash out when the animation completes.
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeCtrl),
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_masterCtrl, _orbitCtrl, _pulseCtrl, _progressCtrl]),
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 1. Background gradient ──────────────────────────────────
                Opacity(
                  opacity: _bgFade.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.4,
                        colors: [
                          gradientStart
                              .withValues(alpha: isDark ? 0.18 : 0.12),
                          bg,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 2. Decorative floating particles ───────────────────────
                Opacity(
                  opacity: _bgFade.value,
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      progress: _orbitCtrl.value,
                      primaryColor: gradientStart,
                      accentColor: gradientEnd,
                      isDark: isDark,
                    ),
                  ),
                ),

                // ── 3. Main content ────────────────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo stack ──────────────────────────────────────
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer orbit ring
                          Transform.rotate(
                            angle: _orbitCtrl.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(190, 190),
                              painter: _OrbitRingPainter(
                                color: gradientStart,
                                opacity: _glowOpacity.value * 0.55,
                                dashCount: 8,
                                dotRadius: 3.5,
                                ringRadius: 92,
                              ),
                            ),
                          ),
                          // Inner counter-orbit ring
                          Transform.rotate(
                            angle: -_orbitCtrl.value * 2 * math.pi * 0.7,
                            child: CustomPaint(
                              size: const Size(140, 140),
                              painter: _OrbitRingPainter(
                                color: gradientEnd,
                                opacity: _glowOpacity.value * 0.4,
                                dashCount: 6,
                                dotRadius: 2.5,
                                ringRadius: 67,
                              ),
                            ),
                          ),
                          // Pulsing glow halo
                          Opacity(
                            opacity: _glowOpacity.value *
                                (0.25 + _pulseCtrl.value * 0.35),
                            child: Container(
                              width: 108 + _pulseCtrl.value * 14,
                              height: 108 + _pulseCtrl.value * 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    gradientStart.withValues(alpha: 0.55),
                                    gradientStart.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Logo container with scale + flip entrance
                          Transform.scale(
                            scale: _logoScale.value.clamp(0.0, 1.0),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(
                                    (1 - _logoFlip.value) * math.pi),
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [gradientStart, gradientEnd],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradientStart.withValues(
                                          alpha: 0.40 +
                                              _pulseCtrl.value * 0.20),
                                      blurRadius:
                                          28 + _pulseCtrl.value * 10,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color:
                                          gradientEnd.withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 40,
                                  color: isDark
                                      ? AppColors.darkBackground
                                      : AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── App name ────────────────────────────────────────
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [gradientStart, gradientEnd],
                          ).createShader(bounds),
                          child: Text(
                            'Tabora',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // ── Subtitle word ───────────────────────────────────
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Text(
                          'SMART BILL MANAGER',
                          style: AppTextStyles.labelMedium.copyWith(
                            color:
                                scheme.onSurface.withValues(alpha: 0.55),
                            letterSpacing: 5,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Tagline ─────────────────────────────────────────
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Track · Split · Settle',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.40),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.massive),

                    // ── Progress bar ────────────────────────────────────
                    FadeTransition(
                      opacity: _taglineFade,
                      child: SizedBox(
                        width: 180,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progressCtrl.value,
                                minHeight: 3,
                                backgroundColor: scheme.onSurface
                                    .withValues(alpha: 0.10),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    gradientStart),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Loading your workspace…',
                              style: AppTextStyles.caption.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.30),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Supporting painters ──────────────────────────────────────────────────────

/// Paints 8 floating particles at fixed positions that gently drift using
/// simple sine/cosine offsets driven by [progress] (0 → 1, repeating).
class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
  });

  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;

  static const List<_ParticleDef> _particles = [
    _ParticleDef(0.12, 0.14, 5, 0.0),
    _ParticleDef(0.88, 0.11, 4, 0.4),
    _ParticleDef(0.05, 0.55, 6, 0.8),
    _ParticleDef(0.93, 0.48, 3.5, 1.2),
    _ParticleDef(0.15, 0.85, 4.5, 1.6),
    _ParticleDef(0.82, 0.82, 5.5, 2.0),
    _ParticleDef(0.50, 0.07, 3, 2.4),
    _ParticleDef(0.60, 0.93, 4, 2.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final phase = progress * 2 * math.pi + p.phase;
      final dx = math.sin(phase) * 10;
      final dy = math.cos(phase * 0.7) * 8;

      final color = i.isEven ? primaryColor : accentColor;
      final paint = Paint()
        ..color = color.withValues(alpha: isDark ? 0.30 : 0.22)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * p.x + dx, size.height * p.y + dy),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _ParticleDef {
  const _ParticleDef(this.x, this.y, this.radius, this.phase);
  final double x, y, radius, phase;
}

/// Paints a dashed orbit ring with glowing dot nodes.
class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({
    required this.color,
    required this.opacity,
    required this.dashCount,
    required this.dotRadius,
    required this.ringRadius,
  });

  final Color color;
  final double opacity;
  final int dashCount;
  final double dotRadius;
  final double ringRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Dashed ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashAngle = math.pi / 18; // 10°
    final gapAngle = (2 * math.pi / dashCount) - dashAngle;
    double startAngle = 0;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        dashAngle,
        false,
        ringPaint,
      );
      startAngle += dashAngle + gapAngle;
    }

    // Dot nodes at each dash midpoint
    final dotPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final step = 2 * math.pi / dashCount;
    for (var i = 0; i < dashCount; i++) {
      final angle = i * step + dashAngle / 2;
      final dotPos = Offset(
        center.dx + ringRadius * math.cos(angle),
        center.dy + ringRadius * math.sin(angle),
      );
      canvas.drawCircle(dotPos, dotRadius + 2, dotGlowPaint);
      canvas.drawCircle(dotPos, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) =>
      old.opacity != opacity || old.color != color;
}
