/// Application-wide constants.
///
/// Centralises values that are used across multiple features so they are
/// never hard-coded in individual screens or widgets.
abstract final class AppConstants {
  AppConstants._();

  // ── Currency ───────────────────────────────────────────────────────────────

  /// The currency symbol used throughout the application (e.g. "Rs.").
  static const String currencySymbol = 'Rs.';

  // ── Bill creation ──────────────────────────────────────────────────────────

  /// Maximum length for a bill title.
  static const int billTitleMaxLength = 50;

  /// Maximum length for a bill note / description.
  static const int billNoteMaxLength = 200;

  /// Tolerance used when comparing whether custom-split shares sum to the
  /// total amount (e.g. 0.01 → within one paisa).
  static const double splitRoundingTolerance = 0.01;
}
