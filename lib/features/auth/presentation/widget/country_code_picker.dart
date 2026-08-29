import 'package:country_picker/country_picker.dart' as cp;
import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Re-export the [Country] type from the `country_picker` package so callers
/// don't need to import it separately.
typedef Country = cp.Country;

/// A tappable button that displays the selected country's flag emoji and
/// dial code, and opens the `country_picker` package's built-in picker
/// when tapped.
///
/// The picker provides a full list of countries with search, flag icons,
/// and dial codes — replacing the previous hand-rolled bottom sheet.
class CountryCodePicker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final borderColor =
        hasError ? colorScheme.error : colorScheme.outlineVariant;

    return GestureDetector(
      onTap: () => _openPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: borderColor,
            width: hasError ? 2 : 1,
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
                  selected.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '+${selected.phoneCode}',
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

  void _openPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    cp.showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: cp.CountryListThemeData(
        // Bottom sheet styling
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
        backgroundColor: colorScheme.surface,

        // Search field styling
        searchTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.radiusMd,
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),

        // Country list item styling
        textStyle: AppTextStyles.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        ),
        flagSize: 22,
      ),
      onSelect: onSelected,
    );
  }
}
