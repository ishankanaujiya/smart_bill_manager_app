import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Full-width primary CTA used across the auth flow.
///
/// A soft coloured shadow behind the button pulses in and out using a
/// sine-bell curve, creating a "blinking blur" effect that draws attention
/// to the CTA without altering the button's own background colour.
///
/// While [isLoading] is `true` the button is disabled and shows a spinner,
/// which also guards against double submissions.
class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  /// Text shown inside the button when not loading.
  final String label;

  /// Called when the user taps the button.
  final VoidCallback onPressed;

  /// When `true`, disables the button and shows a spinner.
  final bool isLoading;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blurController;
  late final Animation<double> _blur;

  @override
  void initState() {
    super.initState();
    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _blur = CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedBuilder(
        animation: _blur,
        builder: (context, child) {
          // Smooth sine-bell: 0 → 1 → 0 with no cusps.
          // (1 - cos(2πt)) / 2 gives a perfect 0 → 1 → 0 wave.
          final pulse = (1 - math.cos(math.pi * 2 * _blur.value)) * 0.5;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusMd,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: 0.15 + 0.40 * pulse,
                  ),
                  blurRadius: 6 + 20 * pulse,
                  spreadRadius: 1 + 2 * pulse,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            textStyle: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: widget.isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(widget.label),
        ),
      ),
    );
  }
}
