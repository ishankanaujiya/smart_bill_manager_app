import 'package:country_picker/country_picker.dart' as cp;
import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Re-export the [Country] type from the `country_picker` package so callers
/// don't need to import it separately.
typedef Country = cp.Country;

/// A tappable button that displays the selected country's flag emoji and
/// dial code.
///
/// The app is currently available in Nepal only, so the picker is locked
/// to Nepal. Tapping the button shows a snackbar informing the user that
/// country selection is unavailable, with a linear progress bar that
/// fills over 1.5 seconds as a loading animation.
class CountryCodePicker extends StatefulWidget {
  const CountryCodePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.hasError = false,
  });

  /// The currently selected [Country].
  final Country selected;

  /// Called when the user picks a new country from the picker.
  final ValueChanged<Country> onSelected;

  /// Whether the parent field is in an error state — controls the border.
  final bool hasError;

  /// Default country (Nepal) used by the sign-in screen.
  static Country get defaultCountry {
    final service = cp.CountryService();
    return service.findByCode('NP') ?? service.getAll().first;
  }

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final borderColor =
        widget.hasError ? colorScheme.error : colorScheme.outlineVariant;

    return GestureDetector(
      onTap: () => _showLockedMessage(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: borderColor,
            width: widget.hasError ? 2 : 1,
          ),
          borderRadius: AppRadius.radiusMd,
        ),
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            child: Row(
              children: [
                Text(
                  widget.selected.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '+${widget.selected.phoneCode}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a snackbar informing the user that country selection is locked
  /// to Nepal, with a linear progress bar that fills over 1.5 seconds.
  void _showLockedMessage(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Reset and start the progress animation from 0 → 1 over 1.5 seconds.
    _progressController.forward(from: 0);

    final progress = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For now the app is only available in Nepal so we cannot '
              'choose other country for now',
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: AppRadius.radiusFull,
                  child: LinearProgressIndicator(
                    value: progress.value,
                    minHeight: 4,
                    backgroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }
}
