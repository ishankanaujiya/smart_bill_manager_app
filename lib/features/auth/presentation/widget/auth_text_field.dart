import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/design_system.dart';

/// Reusable input field shell used throughout the auth flow.
///
/// Provides the focus-driven animated border, the filled background, and
/// a horizontal shake that is triggered via [shake] when validation fails.
/// All colours are pulled from the active theme.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.prefixIcon,
    this.suffix,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffix;
  final String? errorText;

  @override
  State<AuthTextField> createState() => AuthTextFieldState();
}

class AuthTextFieldState extends State<AuthTextField>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Triggers the horizontal shake animation.
  void shake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        // Damped sine wave shake.
        final offset = 8 *
            (1 - t) *
            (t * 4 - t * t * 4 - t * t * t).clamp(-1.0, 1.0);

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Focus(
        child: Builder(
          builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: hasError
                      ? colorScheme.error
                      : (focused ? colorScheme.primary : colorScheme.outlineVariant),
                  width: (focused || hasError) ? 2 : 1,
                ),
                borderRadius: AppRadius.radiusMd,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                inputFormatters: widget.inputFormatters,
                onChanged: (_) => widget.onChanged?.call(),
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  prefixIcon: widget.prefixIcon,
                  prefixIconConstraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  suffixIcon: widget.suffix,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
