import 'package:flutter/material.dart';

/// Colour palette for the animated splash screen.
///
/// The splash uses its own green / gold / cream visual language which is
/// distinct from the app's teal [AppColors] palette. Every colour the splash
/// paints lives here so the widget never hard-codes a value.
///
/// Resolve the palette for the active theme with [AppSplashPalette.of].
@immutable
class AppSplashPalette {
  const AppSplashPalette({
    required this.background,
    required this.gridLine,
    required this.ripple,
    required this.particleGold,
    required this.particleGreen,
    required this.particleGoldDot,
    required this.particleGreenDot,
    required this.auroraBlob1,
    required this.auroraBlob2,
    required this.auroraBlob3,
    required this.markGlow,
    required this.tileGradient,
    required this.logoStroke,
    required this.coinGradient,
    required this.coinText,
    required this.wordmark,
    required this.tagline,
    required this.loaderTrack,
    required this.loaderGradient,
    required this.loaderPercent,
    required this.orbitDotGold,
    required this.orbitDotGreen,
    required this.orbitDotGoldGlow,
    required this.orbitDotGreenGlow,
  });

  /// Full-screen backdrop.
  final Color background;

  /// Hairline grid texture.
  final Color gridLine;

  /// Expanding ripple ring stroke.
  final Color ripple;

  /// Rising "₹" glyph colour.
  final Color particleGold;

  /// Rising green dot colour.
  final Color particleGreen;

  /// Rising gold dot colour.
  final Color particleGoldDot;

  /// Rising green accent dot colour.
  final Color particleGreenDot;

  /// Aurora blob colours (top-left, bottom-right, centre-right).
  final Color auroraBlob1;
  final Color auroraBlob2;
  final Color auroraBlob3;

  /// Soft halo behind the logo tile.
  final Color markGlow;

  /// Logo tile fill.
  final LinearGradient tileGradient;

  /// Logo glyph stroke.
  final Color logoStroke;

  /// Coin badge fill.
  final LinearGradient coinGradient;

  /// Coin badge glyph colour.
  final Color coinText;

  /// Wordmark text colour.
  final Color wordmark;

  /// Tagline text colour.
  final Color tagline;

  /// Loader track (unfilled) colour.
  final Color loaderTrack;

  /// Loader fill gradient.
  final LinearGradient loaderGradient;

  /// Loader percentage text colour.
  final Color loaderPercent;

  /// Orbiting dot gradients.
  final LinearGradient orbitDotGold;
  final LinearGradient orbitDotGreen;

  /// Orbiting dot glow colours.
  final Color orbitDotGoldGlow;
  final Color orbitDotGreenGlow;

  /// Resolves the palette for [context]'s active [Brightness].
  static AppSplashPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // ---------------------------------------------------------------------------
  // Raw palette
  // ---------------------------------------------------------------------------

  // ── Brand greens ──
  static const Color _greenDark = Color(0xFF2C9A76);
  static const Color _greenDeep = Color(0xFF14483A);
  static const Color _greenLight = Color(0xFF249270);
  static const Color _greenDeepLight = Color(0xFF124F3D);
  static const Color _greenBright = Color(0xFF4FCB9F);
  static const Color _greenMist = Color(0xFF8CDBB8);

  // ── Brand golds ──
  static const Color _gold = Color(0xFFD9B23E);
  static const Color _goldBright = Color(0xFFF2D77E);
  static const Color _goldDeep = Color(0xFFB8901F);

  // ── Neutrals ──
  static const Color _darkBackground = Color(0xFF0A0F0D);
  static const Color _lightBackground = Color(0xFFFBF9F3);
  static const Color _darkText = Color(0xFFF6F4EE);
  static const Color _lightText = Color(0xFF15201B);
  static const Color _darkMuted = Color(0xFF8A9490);
  static const Color _lightMuted = Color(0xFF7C8580);
  static const Color _darkFaint = Color(0xFF5F6B65);
  static const Color _lightFaint = Color(0xFF8A9490);
  static const Color _coinInk = Color(0xFF2A1F04);

  // ── Translucent composites — dark mode ──
  static const Color _gridDark = Color(0x0FF6F4EE);
  static const Color _rippleDark = Color(0x384FCB9F);
  static const Color _particleGoldDark = Color(0x8CD9B23E);
  static const Color _particleGreenDark = Color(0x664FCB9F);
  static const Color _particleGoldDotDark = Color(0x80D9B23E);
  static const Color _aurora1Dark = Color(0x8C2C9A76);
  static const Color _aurora2Dark = Color(0x38C9A227);
  static const Color _aurora3Dark = Color(0x476B3F32);
  static const Color _markGlowDark = Color(0x734FCB9F);
  static const Color _loaderTrackDark = Color(0x1AF6F4EE);

  // ── Translucent composites — light mode ──
  static const Color _gridLight = Color(0x0F15201B);
  static const Color _rippleLight = Color(0x2E1F7A5C);
  static const Color _particleGoldLight = Color(0x80A9791E);
  static const Color _particleGreenLight = Color(0x4D1F7A5C);
  static const Color _particleGoldDotLight = Color(0x66A9791E);
  static const Color _aurora1Light = Color(0x8C7FD1AE);
  static const Color _aurora2Light = Color(0x66E9CE85);
  static const Color _aurora3Light = Color(0x59D8B7A6);
  static const Color _markGlowLight = Color(0x4D1F7A5C);
  static const Color _loaderTrackLight = Color(0x1415201B);

  // ── Orbit dot glows (shared) ──
  static const Color _orbitGoldGlow = Color(0x99D9B23E);
  static const Color _orbitGreenGlow = Color(0x804FCB9F);

  // ---------------------------------------------------------------------------
  // Semantic instances
  // ---------------------------------------------------------------------------

  /// Dark-mode splash palette (primary design).
  static const AppSplashPalette dark = AppSplashPalette(
    background: _darkBackground,
    gridLine: _gridDark,
    ripple: _rippleDark,
    particleGold: _particleGoldDark,
    particleGreen: _particleGreenDark,
    particleGoldDot: _particleGoldDotDark,
    particleGreenDot: _particleGreenDark,
    auroraBlob1: _aurora1Dark,
    auroraBlob2: _aurora2Dark,
    auroraBlob3: _aurora3Dark,
    markGlow: _markGlowDark,
    tileGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_greenDark, _greenDeep],
    ),
    logoStroke: _darkText,
    coinGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_goldBright, _goldDeep],
    ),
    coinText: _coinInk,
    wordmark: _darkText,
    tagline: _darkMuted,
    loaderTrack: _loaderTrackDark,
    loaderGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_greenDark, _greenBright, _gold],
    ),
    loaderPercent: _darkFaint,
    orbitDotGold: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_goldBright, _goldDeep],
    ),
    orbitDotGreen: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_greenMist, _greenDark],
    ),
    orbitDotGoldGlow: _orbitGoldGlow,
    orbitDotGreenGlow: _orbitGreenGlow,
  );

  /// Light-mode splash palette.
  static const AppSplashPalette light = AppSplashPalette(
    background: _lightBackground,
    gridLine: _gridLight,
    ripple: _rippleLight,
    particleGold: _particleGoldLight,
    particleGreen: _particleGreenLight,
    particleGoldDot: _particleGoldDotLight,
    particleGreenDot: _particleGreenLight,
    auroraBlob1: _aurora1Light,
    auroraBlob2: _aurora2Light,
    auroraBlob3: _aurora3Light,
    markGlow: _markGlowLight,
    tileGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_greenLight, _greenDeepLight],
    ),
    logoStroke: _darkText,
    coinGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_goldBright, _goldDeep],
    ),
    coinText: _coinInk,
    wordmark: _lightText,
    tagline: _lightMuted,
    loaderTrack: _loaderTrackLight,
    loaderGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_greenDark, _greenBright, _gold],
    ),
    loaderPercent: _lightFaint,
    orbitDotGold: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_goldBright, _goldDeep],
    ),
    orbitDotGreen: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_greenMist, _greenDark],
    ),
    orbitDotGoldGlow: _orbitGoldGlow,
    orbitDotGreenGlow: _orbitGreenGlow,
  );
}
