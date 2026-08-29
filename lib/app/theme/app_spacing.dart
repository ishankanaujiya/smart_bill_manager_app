import 'package:flutter/material.dart';

/// Spacing scale – 4 dp base grid.
///
/// Usage:
/// ```dart
/// Padding(padding: EdgeInsets.all(AppSpacing.md))
/// SizedBox(height: AppSpacing.lg)
/// ```
abstract final class AppSpacing {
  AppSpacing._();

  /// 2 dp
  static const double xxs = 2;

  /// 4 dp
  static const double xs = 4;

  /// 8 dp
  static const double sm = 8;

  /// 12 dp
  static const double md = 12;

  /// 16 dp
  static const double lg = 16;

  /// 20 dp
  static const double xl = 20;

  /// 24 dp
  static const double xxl = 24;

  /// 32 dp
  static const double xxxl = 32;

  /// 40 dp
  static const double huge = 40;

  /// 48 dp
  static const double massive = 48;

  /// 64 dp
  static const double giant = 64;

  // ---------------------------------------------------------------------------
  // Semantic / contextual helpers
  // ---------------------------------------------------------------------------

  /// Horizontal screen padding (left & right).
  static const double screenHorizontal = lg; // 16

  /// Page-level top padding below the app bar.
  static const double pageTop = xxl; // 24

  /// Page-level bottom padding above the nav bar / FAB.
  static const double pageBottom = xxxl; // 32

  /// Gap between a card title and its content.
  static const double cardInner = sm; // 8

  /// Standard list-item vertical padding.
  static const double listItemVertical = md; // 12

  /// Gap between icon and label in a row.
  static const double iconLabel = sm; // 8

  /// Gap between consecutive form fields.
  static const double formField = lg; // 16

  /// Minimum tappable height/width (accessibility).
  static const double minTouchTarget = 48;

  // ---------------------------------------------------------------------------
  // EdgeInsets shortcuts
  // ---------------------------------------------------------------------------

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const EdgeInsets cardPaddingSymmetric = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: md,
  );

  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: listItemVertical,
  );

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );
}
