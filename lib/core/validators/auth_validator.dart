/// Validation rules for authentication forms.
///
/// All methods return `null` when the input is valid, otherwise a localized
/// error message string that can be displayed under a text field.
abstract final class AuthValidator {
  AuthValidator._();

  // ---------------------------------------------------------------------------
  // Email
  // ---------------------------------------------------------------------------

  /// RFC 5322–simplified email pattern.
  static const String _emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  static String? email(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Email address is required';
    }

    if (!RegExp(_emailPattern).hasMatch(input)) {
      return 'Enter a valid email address';
    }

    return null;
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
