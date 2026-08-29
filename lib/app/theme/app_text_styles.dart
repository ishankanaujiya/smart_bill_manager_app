import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive font family selection.
///
/// - Android → Inter (bundled in assets/fonts/inter/)
/// - iOS / macOS → .SF Pro Display (system font)
/// - Other platforms → Inter as fallback
abstract final class AppFonts {
  static const String inter = 'Inter';

  /// Returns the correct font family string for the current platform.
  static String get platformFontFamily {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // .SF Pro is the system font on Apple platforms; Flutter uses it
      // automatically when fontFamily is null, but we pass it explicitly
      // via package name to keep ThemeData declarations consistent.
      return '.SF Pro Display';
    }
    return inter;
  }

  /// Ordered font-family fallback list used in [TextStyle].
  static List<String> get fontFamilyFallback {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const ['.SF Pro Text', 'SF Pro Display', inter];
    }
    return const [inter, 'Roboto'];
  }
}

/// Complete text-style scale following Material 3 type system.
///
/// All sizes are in logical pixels. Letter-spacing values follow the M3 spec.
/// Font weight convention: Regular = 400, Medium = 500, SemiBold = 600,
/// Bold = 700, ExtraBold = 800.
abstract final class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // Base style (platform font, size 14, regular weight)
  // ---------------------------------------------------------------------------
  static TextStyle get _base => TextStyle(
        fontFamily: AppFonts.platformFontFamily,
        fontFamilyFallback: AppFonts.fontFamilyFallback,
        package: null,
        height: 1.5,
        letterSpacing: 0,
      );

  // ---------------------------------------------------------------------------
  // Display
  // ---------------------------------------------------------------------------

  /// Display Large – 57sp, Regular, -0.25 tracking
  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      );

  /// Display Medium – 45sp, Regular, 0 tracking
  static TextStyle get displayMedium => _base.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
      );

  /// Display Small – 36sp, Regular, 0 tracking
  static TextStyle get displaySmall => _base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
      );

  // ---------------------------------------------------------------------------
  // Headline
  // ---------------------------------------------------------------------------

  /// Headline Large – 32sp, SemiBold
  static TextStyle get headlineLarge => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
      );

  /// Headline Medium – 28sp, SemiBold
  static TextStyle get headlineMedium => _base.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.29,
      );

  /// Headline Small – 24sp, SemiBold
  static TextStyle get headlineSmall => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
      );

  // ---------------------------------------------------------------------------
  // Title
  // ---------------------------------------------------------------------------

  /// Title Large – 22sp, SemiBold
  static TextStyle get titleLarge => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
      );

  /// Title Medium – 16sp, Medium, 0.15 tracking
  static TextStyle get titleMedium => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
      );

  /// Title Small – 14sp, Medium, 0.1 tracking
  static TextStyle get titleSmall => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      );

  // ---------------------------------------------------------------------------
  // Label
  // ---------------------------------------------------------------------------

  /// Label Large – 14sp, SemiBold, 0.1 tracking
  static TextStyle get labelLarge => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  /// Label Medium – 12sp, Medium, 0.5 tracking
  static TextStyle get labelMedium => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      );

  /// Label Small – 11sp, Medium, 0.5 tracking
  static TextStyle get labelSmall => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
      );

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  /// Body Large – 16sp, Regular, 0.5 tracking
  static TextStyle get bodyLarge => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      );

  /// Body Medium – 14sp, Regular, 0.25 tracking
  static TextStyle get bodyMedium => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        // letterSpacing: 0.25,
        height: 1.43,
      );

  /// Body Small – 12sp, Regular, 0.4 tracking
  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  // ---------------------------------------------------------------------------
  // App-specific convenience styles
  // ---------------------------------------------------------------------------

  /// Large monetary amount display – 36sp, ExtraBold
  static TextStyle get amountLarge => _base.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
      );

  /// Medium monetary amount display – 24sp, Bold
  static TextStyle get amountMedium => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.2,
      );

  /// Small monetary amount / badge – 14sp, SemiBold
  static TextStyle get amountSmall => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  /// Button text – 15sp, SemiBold, 0.1 tracking
  static TextStyle get button => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.0,
      );

  /// Caption / helper text – 11sp, Regular
  static TextStyle get caption => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.45,
      );

  /// Tab / chip label – 12sp, SemiBold
  static TextStyle get tabLabel => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.0,
      );

  /// Navigation label – 10sp, Medium
  static TextStyle get navLabel => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.0,
      );

  // ---------------------------------------------------------------------------
  // Full TextTheme for use in ThemeData
  // ---------------------------------------------------------------------------

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      );
}
