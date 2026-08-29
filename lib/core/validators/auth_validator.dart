/// Validation rules for authentication forms.
///
/// All methods return `null` when the input is valid, otherwise a localized
/// error message string that can be displayed under a text field.
abstract final class AuthValidator {
  AuthValidator._();

  // ---------------------------------------------------------------------------
  // Mobile number
  // ---------------------------------------------------------------------------

  /// Validates a Nepali mobile number without the country code.
  ///
  /// Accepts numbers starting with 98 or 97 followed by 8 more digits,
  /// giving the common 10-digit Nepali mobile format.
  static const String _mobilePattern = r'^(98|97)\d{8}$';

  static String? phoneNepal(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Mobile number is required';
    }

    if (!RegExp(_mobilePattern).hasMatch(input)) {
      return 'Enter a valid 10-digit mobile number';
    }

    return null;
  }

  /// Strips a leading '+977' or '977' if the user typed it, returning only
  /// the 10-digit local number.
  static String normalizeMobileNumber(String value) {
    var input = value.trim().replaceAll(' ', '');
    if (input.startsWith('+977')) {
      input = input.substring(4);
    } else if (input.startsWith('977')) {
      input = input.substring(3);
    }
    return input;
  }

  // ---------------------------------------------------------------------------
  // Password
  // ---------------------------------------------------------------------------

  static String? passwordRequired(String? value) {
    final input = value ?? '';

    if (input.isEmpty) {
      return 'Password is required';
    }

    if (input.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }
}
