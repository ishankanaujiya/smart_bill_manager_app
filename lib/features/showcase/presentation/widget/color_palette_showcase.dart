import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Displays the full color palette as swatch tiles with hex labels.
class ColorPaletteShowcase extends StatelessWidget {
  const ColorPaletteShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final semanticSwatches = <_SwatchData>[
      _SwatchData('Primary', theme.colorScheme.primary),
      _SwatchData('On Primary', theme.colorScheme.onPrimary),
      _SwatchData('Primary Container', theme.colorScheme.primaryContainer),
      _SwatchData(
        'On Primary Container',
        theme.colorScheme.onPrimaryContainer,
      ),
      _SwatchData('Secondary', theme.colorScheme.secondary),
      _SwatchData('On Secondary', theme.colorScheme.onSecondary),
      _SwatchData('Tertiary', theme.colorScheme.tertiary),
      _SwatchData('Surface', theme.colorScheme.surface),
      _SwatchData('On Surface', theme.colorScheme.onSurface),
      _SwatchData('Surface Variant', theme.colorScheme.surfaceContainerHighest),
      _SwatchData('On Surface Variant', theme.colorScheme.onSurfaceVariant),
      _SwatchData('Outline', theme.colorScheme.outline),
      _SwatchData('Error', theme.colorScheme.error),
      _SwatchData('OnError', theme.colorScheme.onError),
    ];

    final statusSwatches = <_SwatchData>[
      _SwatchData('Success', AppColors.success),
      _SwatchData('Warning', AppColors.warning),
      _SwatchData('Error', AppColors.error),
    ];

    final chartColors =
        isDark ? AppColors.chartColorsDark : AppColors.chartColorsLight;
    final chartSwatches = <_SwatchData>[
      for (var i = 0; i < chartColors.length; i++)
        _SwatchData('Chart ${i + 1}', chartColors[i]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SwatchGrid(swatches: semanticSwatches),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Status Colors',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SwatchGrid(swatches: statusSwatches),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Chart / Data Colors',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SwatchGrid(swatches: chartSwatches),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Gradients',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
              Expanded(
              child: _GradientTile(
                label: 'Primary',
                gradient: isDark
                    ? AppColors.darkPrimaryGradient
                    : AppColors.lightPrimaryGradient,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _GradientTile(
                label: 'Secondary',
                gradient: isDark
                    ? AppColors.darkSecondaryGradient
                    : AppColors.lightSecondaryGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({required this.swatches});

  final List<_SwatchData> swatches;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: swatches.map((s) => _SwatchTile(data: s)).toList(),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({required this.data});

  final _SwatchData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hex = _toHex(data.color);

    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 56, color: data.color),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hex,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientTile extends StatelessWidget {
  const _GradientTile({required this.label, required this.gradient});

  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.radiusMd,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SwatchData {
  const _SwatchData(this.label, this.color);

  final String label;
  final Color color;
}

String _toHex(Color color) {
  final hex = color.toARGB32().toRadixString(16).toUpperCase();
  return '#${hex.substring(2)}';
}
