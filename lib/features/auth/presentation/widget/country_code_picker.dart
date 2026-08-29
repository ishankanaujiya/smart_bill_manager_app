import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Minimal country model for the country-code selector.
class Country {
  const Country({
    required this.name,
    required this.countryCode,
    required this.phoneCode,
    required this.flagEmoji,
  });

  final String name;
  final String countryCode;
  final String phoneCode;
  final String flagEmoji;

  /// Default list of countries for the picker.
  static const List<Country> defaults = [
    Country(name: 'Nepal', countryCode: 'NP', phoneCode: '977', flagEmoji: '🇳🇵'),
    Country(name: 'India', countryCode: 'IN', phoneCode: '91', flagEmoji: '🇮🇳'),
    Country(name: 'United States', countryCode: 'US', phoneCode: '1', flagEmoji: '🇺🇸'),
    Country(name: 'United Kingdom', countryCode: 'GB', phoneCode: '44', flagEmoji: '🇬🇧'),
    Country(name: 'Australia', countryCode: 'AU', phoneCode: '61', flagEmoji: '🇦🇺'),
    Country(name: 'Bangladesh', countryCode: 'BD', phoneCode: '880', flagEmoji: '🇧🇩'),
    Country(name: 'Pakistan', countryCode: 'PK', phoneCode: '92', flagEmoji: '🇵🇰'),
    Country(name: 'Sri Lanka', countryCode: 'LK', phoneCode: '94', flagEmoji: '🇱🇰'),
  ];

  static const Country defaultCountry = Country(
    name: 'Nepal',
    countryCode: 'NP',
    phoneCode: '977',
    flagEmoji: '🇳🇵',
  );
}

/// A button that displays the selected country code and opens a bottom sheet
/// to pick another country.
class CountryCodePicker extends StatelessWidget {
  const CountryCodePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.hasError = false,
    this.errorColor,
    this.borderColor,
    this.fillColor,
    this.isDark = false,
  });

  final Country selected;
  final ValueChanged<Country> onSelected;
  final bool hasError;
  final Color? errorColor;
  final Color? borderColor;
  final Color? fillColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final activeBorder = hasError
        ? (errorColor ?? colorScheme.error)
        : (borderColor ?? colorScheme.outlineVariant);

    return GestureDetector(
      onTap: () => _openPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: fillColor ?? colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: activeBorder,
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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (context) => _CountryPickerSheet(
        selected: selected,
        onSelected: (country) {
          onSelected(country);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  final Country selected;
  final ValueChanged<Country> onSelected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late final TextEditingController _searchController;
  late List<Country> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = Country.defaults;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _filtered = Country.defaults.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.countryCode.toLowerCase().contains(query) ||
            c.phoneCode.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: AppRadius.radiusFull,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select country',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search country',
                prefixIcon: const Icon(Icons.search_rounded),
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
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  final isSelected = country.countryCode ==
                      widget.selected.countryCode;

                  return ListTile(
                    leading: Text(
                      country.flagEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(country.name),
                    subtitle: Text('+${country.phoneCode}'),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: colorScheme.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusSm,
                    ),
                    onTap: () => widget.onSelected(country),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
