import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../widget/button_showcase.dart';
import '../widget/card_showcase.dart';
import '../widget/color_palette_showcase.dart';
import '../widget/feedback_showcase.dart';
import '../widget/input_showcase.dart';
import '../widget/selection_showcase.dart';
import '../widget/showcase_section.dart';
import '../widget/typography_showcase.dart';

/// A visual catalog of every design-system token and component.
///
/// Acts as both a living style guide and a manual test surface for light and
/// dark mode. The theme-mode toggle in the app bar switches the entire app
/// between [AppTheme.light] and [AppTheme.dark].
class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(theme, colorScheme, isDark),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              sliver: SliverList.list(
                children: [
                  const ShowcaseSection(
                    title: 'Color Palette',
                    subtitle: 'Semantic tokens, status & chart colors, gradients',
                    icon: Icons.palette_rounded,
                    child: ColorPaletteShowcase(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const ShowcaseSection(
                    title: 'Typography',
                    subtitle: 'Inter (Android) / .SF Pro (iOS) — M3 type scale',
                    icon: Icons.text_fields_rounded,
                    child: TypographyShowcase(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const ShowcaseSection(
                    title: 'Buttons',
                    subtitle: 'Elevated, filled, outlined, text, FAB, icon',
                    icon: Icons.smart_button_rounded,
                    child: ButtonShowcase(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const ShowcaseSection(
                    title: 'Cards & Lists',
                    subtitle: 'Standard, gradient hero, list tiles, badges',
                    icon: Icons.dashboard_rounded,
                    child: CardShowcase(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const ShowcaseSection(
                    title: 'Inputs',
                    subtitle: 'Text fields with prefix, suffix, error & disabled',
                    icon: Icons.edit_rounded,
                    child: InputShowcase(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const ShowcaseSection(
                    title: 'Selection Controls',
                    subtitle: 'Switch, checkbox, radio, chips',
                    icon: Icons.toggle_on_rounded,
                    child: SelectionShowcase(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const ShowcaseSection(
                    title: 'Feedback',
                    subtitle: 'Progress, snackbar, dialog, bottom sheet',
                    icon: Icons.notifications_rounded,
                    child: FeedbackShowcase(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SliverAppBar(
      floating: true,
      toolbarHeight: 64,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design System',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Showcase — ${isDark ? 'Dark' : 'Light'} Mode',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        _ThemeToggle(
          isDark: isDark,
          onChanged: (dark) => onThemeModeChanged(
            dark ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.isDark, required this.onChanged});

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => onChanged(!isDark),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween<double>(begin: 0.5, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
        ),
      ),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
    );
  }
}
