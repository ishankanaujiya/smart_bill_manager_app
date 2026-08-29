import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Validation rules for authentication forms.
///
/// All methods return `null` when the input is valid, otherwise a localized
/// error message string that can be displayed under a text field.
abstract final class AuthValidator {
  AuthValidator._();

  // ---------------------------------------------------------------------------
  // Full name
  // ---------------------------------------------------------------------------

  /// Validates a person's full name.
  ///
  /// Accepts only letters, spaces, hyphens and apostrophes. Must contain at
  /// least two words (first and last name) with a minimum of 2 characters each.
  static String? fullName(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Full name is required';
    }

    if (input.length < 3) {
      return 'Name is too short';
    }

    final parts = input.split(RegExp(r'\s+'))..removeWhere((p) => p.isEmpty);
    if (parts.length < 2) {
      return 'Enter first and last name';
    }

    if (parts.any((p) => p.length < 2)) {
      return 'Each name must be at least 2 characters';
    }

    final validPattern = RegExp(r"^[a-zA-Z\s\-'']+$");
    if (!validPattern.hasMatch(input)) {
      return 'Enter a valid name';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Mobile number (Nepal)
  // ---------------------------------------------------------------------------

  /// Nepali mobile numbers: start with 98 or 97 and 10 digits total.
  static const String _mobilePattern = r'^(98|97)\d{8}$';

  static String? phoneNepal(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Mobile number is required';
    }

    if (!RegExp(_mobilePattern).hasMatch(input)) {
      return 'Enter valid mobile number';
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

  /// Strong password: at least 8 chars and contains at least one number.
  static const String _numberPattern = r'\d';

  static String? password(String? value) {
    final input = value ?? '';

    if (input.isEmpty) {
      return 'Password is required';
    }

    if (input.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(_numberPattern).hasMatch(input)) {
      return 'Password must include at least one number';
    }

    return null;
  }

  /// Validates that the confirmation password matches the original.
  static String? confirmPassword(String? value, String original) {
    final input = value ?? '';

    if (input.isEmpty) {
      return 'Confirm your password';
    }

    if (input != original) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Score and label for a password based on multiple criteria.
  static PasswordStrength passwordStrength(String? value) {
    final input = value ?? '';

    var score = 0;
    if (input.length >= 8) score++;
    if (input.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(input)) score++;
    if (RegExp(r'[0-9]').hasMatch(input)) score++;
    if (RegExp(r'''[!@#$%^&*(),.?":{}|<>_+\-=\[\]\\\\;'~`\/]''').hasMatch(input)) {
      score++;
    }

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.fair;
    return PasswordStrength.strong;
  }

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
}

/// Labels used by the password-strength indicator.
enum PasswordStrength { weak, fair, strong }

extension PasswordStrengthX on PasswordStrength {
  /// Width fraction used by the progress bar.
  double get value {
    switch (this) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.65;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  /// Human-readable label.
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  /// Color that matches the strength level.
  Color color(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (this) {
      case PasswordStrength.weak:
        return colorScheme.error;
      case PasswordStrength.fair:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }
}
