import 'package:flutter/material.dart';

/// Complete color palette for Smart Bill Manager.
///
/// Extracted from the "Group Expense Splitter – Color Palette" design spec.
/// A modern teal-green palette that feels fresh, financial, and trustworthy.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Raw palette – use semantic tokens in production code where possible
  // ---------------------------------------------------------------------------

  // ── Primary raw values ─────────────────────────────────────────────────────
  static const teal1 = Color(0xFF00D1B2); // Dark-mode Primary 1
  static const teal2 = Color(0xFF10B981); // Primary 2 (shared)
  static const teal3 = Color(0xFF14B8A6); // Light-mode Primary 1

  // ── Secondary / Accent raw values ──────────────────────────────────────────
  static const accentGreenDark = Color(0xFFA7F3D0); // Dark Accent 1
  static const accentBlueDark = Color(0xFF3B82F6); // Dark Accent 2  /  shared
  static const accentGreenLight = Color(0xFFD1FAE5); // Light Accent 1
  // accentBlueLight == accentBlueDark (same hex in spec)

  // ── Neutral raw values ─────────────────────────────────────────────────────
  // Dark mode
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceVariant = Color(0xFF334155);
  static const darkOnSurfaceHigh = Color(0xFFCBD5E1); // High emphasis
  static const darkOnSurfaceMedium = Color(0xFF94A3B8); // Medium emphasis

  // Light mode
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF1F5F9);
  static const lightOnSurfaceHigh = Color(0xFF1F2937); // High emphasis
  static const lightOnSurfaceMedium = Color(0xFF647488); // Medium emphasis

  // ── Status raw values (shared) ─────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFEF4444);

  // ── Chart / Data colors ─────────────────────────────────────────────────────
  // Both modes share the same chart palette (with slight primary shifts noted
  // in the spec; the palette rows are equivalent so we unify them).
  static const chartTeal = Color(0xFF00D1B2); // Dark / #14B8A6 light → same family
  static const chartGreen = Color(0xFF10B981);
  static const chartBlue = Color(0xFF3B82F6);
  static const chartPurple = Color(0xFF8B5CF6);
  static const chartOrange = Color(0xFFFB923C);
  static const chartPink = Color(0xFFF472B6);
  static const chartCyan = Color(0xFF22D3EE); // Dark #22D3EE / Light #22D3EE
  static const chartYellow = Color(0xFFFACC15);

  // Light mode chart teal variant
  static const chartTealLight = Color(0xFF14B8A6);

  // ── Gradient endpoint pairs ─────────────────────────────────────────────────
  // Dark mode
  static const darkPrimaryGradientStart = Color(0xFF00D1B2);
  static const darkPrimaryGradientEnd = Color(0xFF10B981);
  static const darkSecondaryGradientStart = Color(0xFF3B82F6);
  static const darkSecondaryGradientEnd = Color(0xFF60A5FA);

  // Light mode
  static const lightPrimaryGradientStart = Color(0xFF14B8A6);
  static const lightPrimaryGradientEnd = Color(0xFF10B981);
  static const lightSecondaryGradientStart = Color(0xFF3B82F6);
  static const lightSecondaryGradientEnd = Color(0xFF60A5FA);

  // ── Utility ────────────────────────────────────────────────────────────────
  static const transparent = Colors.transparent;
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Semantic color tokens – LIGHT mode
  // ---------------------------------------------------------------------------

  /// Primary action colour in light mode.
  static const lightPrimary = teal3; // #14B8A6
  static const lightPrimaryVariant = teal2; // #10B981
  static const lightOnPrimary = white;

  static const lightSecondary = accentBlueDark; // #3B82F6
  static const lightOnSecondary = white;

  static const lightAccent = accentGreenLight; // #D1FAE5

  static const lightErrorColor = error;
  static const lightOnError = white;

  static const lightSuccessColor = success;
  static const lightWarningColor = warning;

  // ---------------------------------------------------------------------------
  // Semantic color tokens – DARK mode
  // ---------------------------------------------------------------------------

  static const darkPrimary = teal1; // #00D1B2
  static const darkPrimaryVariant = teal2; // #10B981
  static const darkOnPrimary = darkBackground;

  static const darkSecondary = accentBlueDark; // #3B82F6
  static const darkOnSecondary = white;

  static const darkAccent = accentGreenDark; // #A7F3D0

  static const darkErrorColor = error;
  static const darkOnError = white;

  static const darkSuccessColor = success;
  static const darkWarningColor = warning;

  // ---------------------------------------------------------------------------
  // Gradient helpers (LinearGradient objects for convenience)
  // ---------------------------------------------------------------------------

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [darkPrimaryGradientStart, darkPrimaryGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkSecondaryGradient = LinearGradient(
    colors: [darkSecondaryGradientStart, darkSecondaryGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient lightPrimaryGradient = LinearGradient(
    colors: [lightPrimaryGradientStart, lightPrimaryGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient lightSecondaryGradient = LinearGradient(
    colors: [lightSecondaryGradientStart, lightSecondaryGradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ---------------------------------------------------------------------------
  // Chart color list – order matches the spec row left→right
  // ---------------------------------------------------------------------------

  static const List<Color> chartColorsDark = [
    chartTeal,
    chartGreen,
    chartBlue,
    chartPurple,
    chartOrange,
    chartPink,
    chartCyan,
    chartYellow,
  ];

  static const List<Color> chartColorsLight = [
    chartTealLight,
    chartGreen,
    chartBlue,
    chartPurple,
    chartOrange,
    chartPink,
    chartCyan,
    chartYellow,
  ];
}
