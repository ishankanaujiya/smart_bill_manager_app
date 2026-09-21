import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// A [TextInputFormatter] that formats numbers using the South Asian
/// grouping convention (e.g. 1,00,000 / 10,000 / 1,250.50) as the user
/// types.
///
/// - Strips any non-digit / non-dot characters before formatting.
/// - Allows at most one decimal point with up to 2 decimal places.
/// - Preserves the cursor at the end of the input (natural for numeric
///   entry from left to right).
class SouthAsianCurrencyInputFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat('#,##,##0.##', 'en_IN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty input.
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Strip everything except digits and at most one dot.
    final stripped = _stripNonNumeric(newValue.text);
    if (stripped.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Split into integer and decimal parts.
    final parts = stripped.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final decPart = parts.length > 1 ? parts[1] : '';

    // Parse the integer part and format with South Asian grouping.
    final intVal = int.tryParse(intPart) ?? 0;
    var formatted = _formatter.format(intVal);

    // Reattach the decimal portion (raw, not grouped) if present.
    if (parts.length > 1) {
      // Limit to 2 decimal places.
      final trimmedDec = decPart.length > 2 ? decPart.substring(0, 2) : decPart;
      formatted = '$formatted.$trimmedDec';
    }

    // Place cursor at the end — natural for numeric entry.
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Removes all non-digit characters except the first dot encountered.
  static String _stripNonNumeric(String input) {
    final buffer = StringBuffer();
    bool dotSeen = false;
    for (final char in input.split('')) {
      if (char == '.') {
        if (!dotSeen) {
          buffer.write(char);
          dotSeen = true;
        }
      } else if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
