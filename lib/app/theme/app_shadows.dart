import 'package:flutter/material.dart';

/// Elevation / shadow system.
///
/// Two variants are provided: one for light mode and one for dark mode.
/// Dark-mode shadows use a slightly stronger opacity since the dark surface
/// provides less contrast for a subtle blur.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.cardLight,
///   ),
/// )
/// ```
abstract final class AppShadows {
  AppShadows._();

  // ---------------------------------------------------------------------------
  // Light mode shadows
  // ---------------------------------------------------------------------------

  /// Hairline – barely perceptible lift (nav bars, bottom bars)
  static const List<BoxShadow> hairlineLight = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  /// Extra-small – subtle card or list item
  static const List<BoxShadow> xsLight = [
    BoxShadow(
      color: Color(0x0D0F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Small – standard card
  static const List<BoxShadow> smLight = [
    BoxShadow(
      color: Color(0x120F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Medium – elevated card / modal
  static const List<BoxShadow> mdLight = [
    BoxShadow(
      color: Color(0x180F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Large – dialogs, popovers
  static const List<BoxShadow> lgLight = [
    BoxShadow(
      color: Color(0x200F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0C0F172A),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  /// Extra-large – hero elements, full-screen overlays
  static const List<BoxShadow> xlLight = [
    BoxShadow(
      color: Color(0x260F172A),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x100F172A),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Dark mode shadows
  // ---------------------------------------------------------------------------

  /// Hairline – dark
  static const List<BoxShadow> hairlineDark = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  /// Extra-small – dark
  static const List<BoxShadow> xsDark = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Small – dark
  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Medium – dark
  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Large – dark
  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  /// Extra-large – dark
  static const List<BoxShadow> xlDark = [
    BoxShadow(
      color: Color(0x47000000),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Tinted / colored shadows (for primary-color cards)
  // ---------------------------------------------------------------------------

  /// Primary teal glow – light mode
  static const List<BoxShadow> primaryGlowLight = [
    BoxShadow(
      color: Color(0x3314B8A6), // 20% lightPrimary
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Primary teal glow – dark mode
  static const List<BoxShadow> primaryGlowDark = [
    BoxShadow(
      color: Color(0x4D00D1B2), // 30% darkPrimary
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  /// Secondary blue glow
  static const List<BoxShadow> secondaryGlow = [
    BoxShadow(
      color: Color(0x333B82F6), // 20% secondary
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Helper: resolve shadow by brightness
  // ---------------------------------------------------------------------------

  /// Returns the correct card shadow set for the given [brightness].
  static List<BoxShadow> cardShadow(Brightness brightness) =>
      brightness == Brightness.dark ? smDark : smLight;

  /// Returns the correct modal shadow set for the given [brightness].
  static List<BoxShadow> modalShadow(Brightness brightness) =>
      brightness == Brightness.dark ? lgDark : lgLight;
}
