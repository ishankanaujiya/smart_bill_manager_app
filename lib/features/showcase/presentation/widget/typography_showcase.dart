import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Demonstrates the full text-style scale from [AppTextStyles].
class TypographyShowcase extends StatelessWidget {
  const TypographyShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final styles = <_TypeSample>[
      _TypeSample('Display Large', AppTextStyles.displayLarge),
      _TypeSample('Display Medium', AppTextStyles.displayMedium),
      _TypeSample('Display Small', AppTextStyles.displaySmall),
      _TypeSample('Headline Large', AppTextStyles.headlineLarge),
      _TypeSample('Headline Medium', AppTextStyles.headlineMedium),
      _TypeSample('Headline Small', AppTextStyles.headlineSmall),
      _TypeSample('Title Large', AppTextStyles.titleLarge),
      _TypeSample('Title Medium', AppTextStyles.titleMedium),
      _TypeSample('Title Small', AppTextStyles.titleSmall),
      _TypeSample('Body Large', AppTextStyles.bodyLarge),
      _TypeSample('Body Medium', AppTextStyles.bodyMedium),
      _TypeSample('Body Small', AppTextStyles.bodySmall),
      _TypeSample('Label Large', AppTextStyles.labelLarge),
      _TypeSample('Label Medium', AppTextStyles.labelMedium),
      _TypeSample('Label Small', AppTextStyles.labelSmall),
      _TypeSample('Amount Large', AppTextStyles.amountLarge),
      _TypeSample('Amount Medium', AppTextStyles.amountMedium),
      _TypeSample('Button', AppTextStyles.button),
      _TypeSample('Caption', AppTextStyles.caption),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: styles
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'The quick brown fox',
                      style: s.style.copyWith(color: colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    s.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TypeSample {
  const _TypeSample(this.name, this.style);

  final String name;
  final TextStyle style;
}
