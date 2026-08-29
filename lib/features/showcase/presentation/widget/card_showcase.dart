import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';

/// Demonstrates card, list-tile, and badge variants.
class CardShowcase extends StatelessWidget {
  const CardShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Standard card ──────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card_rounded,
                        size: 22, color: AppColors.teal2),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Standard Card',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Badge(
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'A default card from the cardTheme with 16dp radius, '
                  'zero elevation, and an outline variant border.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Gradient hero card ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.darkPrimaryGradient
                : AppColors.lightPrimaryGradient,
            borderRadius: AppRadius.radiusXl,
            boxShadow: isDark
                ? AppShadows.primaryGlowDark
                : AppShadows.primaryGlowLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gradient Hero Card',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '\$1,250.00',
                style: AppTextStyles.amountLarge.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Uses AppColors gradient + AppShadows primaryGlow',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── List tiles inside a card ───────────────────────────────────────
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: const Text('Account'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.lock_rounded),
                title: const Text('Privacy'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.notifications_rounded),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
