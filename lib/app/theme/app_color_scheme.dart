import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Explicit [ColorScheme] definitions for both light and dark modes.
///
/// We define every relevant role explicitly instead of using
/// [ColorScheme.fromSeed] so the output is 100% faithful to the design spec.
abstract final class AppColorScheme {
  // ---------------------------------------------------------------------------
  // Light mode ColorScheme
  // ---------------------------------------------------------------------------
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

    // ── Primary ──────────────────────────────────────────────────────────────
    primary: AppColors.lightPrimary, // #14B8A6
    onPrimary: AppColors.lightOnPrimary, // white
    primaryContainer: AppColors.lightAccent, // #D1FAE5
    onPrimaryContainer: Color(0xFF0D4037), // deep teal for legibility

    // ── Secondary ────────────────────────────────────────────────────────────
    secondary: AppColors.lightSecondary, // #3B82F6
    onSecondary: AppColors.lightOnSecondary, // white
    secondaryContainer: Color(0xFFDBEAFE), // light blue tint
    onSecondaryContainer: Color(0xFF1E3A8A),

    // ── Tertiary (accent green primary variant) ───────────────────────────────
    tertiary: AppColors.teal2, // #10B981
    onTertiary: AppColors.white,
    tertiaryContainer: Color(0xFFD1FAE5),
    onTertiaryContainer: Color(0xFF064E3B),

    // ── Error ─────────────────────────────────────────────────────────────────
    error: AppColors.lightErrorColor, // #EF4444
    onError: AppColors.lightOnError, // white
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),

    // ── Background & Surface ──────────────────────────────────────────────────
    surface: AppColors.lightSurface, // #FFFFFF
    onSurface: AppColors.lightOnSurfaceHigh, // #1F2937
    surfaceContainerHighest: AppColors.lightSurfaceVariant, // #F1F5F9
    onSurfaceVariant: AppColors.lightOnSurfaceMedium, // #647488

    // ── Outline ───────────────────────────────────────────────────────────────
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),

    // ── Inverse ───────────────────────────────────────────────────────────────
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkOnSurfaceHigh,
    inversePrimary: AppColors.darkPrimary,

    // ── Scrim & Shadow ────────────────────────────────────────────────────────
    scrim: Color(0x660F172A),
    shadow: Color(0x1A0F172A),
  );

  // ---------------------------------------------------------------------------
  // Dark mode ColorScheme
  // ---------------------------------------------------------------------------
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,

    // ── Primary ──────────────────────────────────────────────────────────────
    primary: AppColors.darkPrimary, // #00D1B2
    onPrimary: AppColors.darkOnPrimary, // #0F172A (dark bg for contrast)
    primaryContainer: Color(0xFF134E4A), // deep teal container
    onPrimaryContainer: AppColors.accentGreenDark, // #A7F3D0

    // ── Secondary ────────────────────────────────────────────────────────────
    secondary: AppColors.darkSecondary, // #3B82F6
    onSecondary: AppColors.white,
    secondaryContainer: Color(0xFF1E3A8A),
    onSecondaryContainer: Color(0xFFBFDBFE),

    // ── Tertiary ──────────────────────────────────────────────────────────────
    tertiary: AppColors.teal2, // #10B981
    onTertiary: AppColors.darkBackground,
    tertiaryContainer: Color(0xFF064E3B),
    onTertiaryContainer: AppColors.accentGreenDark,

    // ── Error ─────────────────────────────────────────────────────────────────
    error: AppColors.darkErrorColor, // #EF4444
    onError: AppColors.darkOnError,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),

    // ── Background & Surface ──────────────────────────────────────────────────
    surface: AppColors.darkSurface, // #1E293B
    onSurface: AppColors.darkOnSurfaceHigh, // #CBD5E1
    surfaceContainerHighest: AppColors.darkSurfaceVariant, // #334155
    onSurfaceVariant: AppColors.darkOnSurfaceMedium, // #94A3B8

    // ── Outline ───────────────────────────────────────────────────────────────
    outline: Color(0xFF475569),
    outlineVariant: Color(0xFF334155),

    // ── Inverse ───────────────────────────────────────────────────────────────
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightOnSurfaceHigh,
    inversePrimary: AppColors.lightPrimary,

    // ── Scrim & Shadow ────────────────────────────────────────────────────────
    scrim: Color(0x990F172A),
    shadow: Color(0x330F172A),
  );
}
