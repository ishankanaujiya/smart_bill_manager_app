import 'package:flutter/material.dart';

/// Border-radius scale.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(borderRadius: AppRadius.md),
/// )
/// ```
abstract final class AppRadius {
  AppRadius._();

  // ── Raw values ─────────────────────────────────────────────────────────────

  /// 4 dp – subtle rounding (input borders, tags)
  static const double xs = 4;

  /// 8 dp – small components (chips, badges)
  static const double sm = 8;

  /// 12 dp – default compact cards
  static const double md = 12;

  /// 16 dp – standard cards, dialogs, modals
  static const double lg = 16;

  /// 20 dp – large cards, bottom-sheets top corners
  static const double xl = 20;

  /// 24 dp – prominent containers
  static const double xxl = 24;

  /// 28 dp – hero cards
  static const double xxxl = 28;

  /// 9999 dp – fully rounded / pill shape
  static const double full = 9999;

  // ── BorderRadius objects ────────────────────────────────────────────────────

  static final BorderRadius radiusXs = BorderRadius.circular(xs);
  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(md);
  static final BorderRadius radiusLg = BorderRadius.circular(lg);
  static final BorderRadius radiusXl = BorderRadius.circular(xl);
  static final BorderRadius radiusXxl = BorderRadius.circular(xxl);
  static final BorderRadius radiusXxxl = BorderRadius.circular(xxxl);
  static final BorderRadius radiusFull = BorderRadius.circular(full);

  // ── Top-only variants (bottom-sheets, header cards) ────────────────────────

  static final BorderRadius topLg = const BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );

  static final BorderRadius topXl = const BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );

  static final BorderRadius topXxl = const BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );

  // ── Bottom-only variants ───────────────────────────────────────────────────

  static final BorderRadius bottomLg = const BorderRadius.only(
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );

  // ── Semantic aliases ───────────────────────────────────────────────────────

  /// Standard card border radius.
  static final BorderRadius card = radiusLg;

  /// Dialog / modal border radius.
  static final BorderRadius dialog = radiusXxl;

  /// Bottom-sheet top corners.
  static final BorderRadius bottomSheet = topXxl;

  /// Button border radius (pill-ish).
  static final BorderRadius button = radiusLg;

  /// Input field border radius.
  static final BorderRadius input = radiusMd;

  /// Badge / status dot border radius.
  static final BorderRadius badge = radiusFull;

  /// Chip border radius.
  static final BorderRadius chip = radiusFull;

  /// Avatar border radius.
  static final BorderRadius avatar = radiusFull;
}
