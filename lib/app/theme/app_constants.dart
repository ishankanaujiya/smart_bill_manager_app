import 'package:intl/intl.dart';

/// Application-wide constants.
///
/// Centralises values that are used across multiple features so they are
/// never hard-coded in individual screens or widgets.
abstract final class AppConstants {
  AppConstants._();

  // ── Currency ───────────────────────────────────────────────────────────────

  /// The currency symbol used throughout the application (e.g. "Rs.").
  static const String currencySymbol = 'Rs.';

  /// Formats a number using the South Asian grouping convention
  /// (e.g. 1,00,000 / 10,000 / 1,250.50).
  ///
  /// Pass [withSymbol] = true to prefix "Rs. ".
  /// Pass [decimals] to force a fixed number of decimal places
  /// (default: drop trailing ".00", keep up to 2 otherwise).
  static String formatCurrency(
    num value, {
    bool withSymbol = false,
    int? decimals,
  }) {
    final formatter = NumberFormat(
      decimals != null ? '#,##,##0.${'0' * decimals}' : '#,##,##0.##',
      'en_IN',
    );
    final formatted = formatter.format(value);
    return withSymbol ? '$currencySymbol $formatted' : formatted;
  }

  // ── Bill creation ──────────────────────────────────────────────────────────

  /// Maximum length for a bill title.
  static const int billTitleMaxLength = 50;

  /// Maximum length for a bill note / description.
  static const int billNoteMaxLength = 200;

  /// Tolerance used when comparing whether custom-split shares sum to the
  /// total amount (e.g. 0.01 → within one paisa).
  static const double splitRoundingTolerance = 0.01;
}
