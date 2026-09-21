import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../main.dart';

/// Appearance settings — lets the user switch between Light, Dark, and
/// System theme modes.
///
/// The selected mode is written to the global [themeModeNotifier] in
/// `main.dart`, which the root [MaterialApp] listens to via
/// [ValueListenableBuilder].
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _setMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, currentMode, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── Intro ───────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: StaggeredEntrance(
                    animation: _entranceController,
                    interval: const Interval(0.0, 0.4, curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.lg,
                        AppSpacing.screenHorizontal,
                        AppSpacing.xl,
                      ),
                      child: Text(
                        'Choose how Smart Bill Manager looks to you. '
                        'You can switch between light and dark themes, or '
                        'follow your system setting.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Preview card ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: StaggeredEntrance(
                    animation: _entranceController,
                    interval: const Interval(0.05, 0.45, curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: _ThemePreviewCard(
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

                // ── Section label ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: StaggeredEntrance(
                    animation: _entranceController,
                    interval: const Interval(0.15, 0.55, curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Text(
                        'THEME',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Theme options ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: StaggeredEntrance(
                    animation: _entranceController,
                    interval: const Interval(0.18, 0.6, curve: Curves.easeOut),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: _ThemeOptionsGroup(
                        currentMode: currentMode,
                        onSelect: _setMode,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme preview card — shows a mini mock of how the app looks
// ─────────────────────────────────────────────────────────────────────────────

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.isDark,
    required this.colorScheme,
  });

  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusXxl,
        boxShadow: AppShadows.cardShadow(
          isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXxl,
        child: Container(
          // Mini "app" surface
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkPrimaryGradient
                          : AppColors.lightPrimaryGradient,
                      borderRadius: AppRadius.radiusSm,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 8,
                          width: 100,
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.darkOnSurfaceHigh
                                    : AppColors.lightOnSurfaceHigh)
                                .withValues(alpha: 0.7),
                            borderRadius: AppRadius.radiusXs,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          width: 60,
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.darkOnSurfaceMedium
                                    : AppColors.lightOnSurfaceMedium)
                                .withValues(alpha: 0.5),
                            borderRadius: AppRadius.radiusXs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Mock balance card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkPrimaryGradient
                      : AppColors.lightPrimaryGradient,
                  borderRadius: AppRadius.radiusLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 6,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.6),
                        borderRadius: AppRadius.radiusXs,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.radiusXs,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Mock list rows
              ...List.generate(2, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface),
                          borderRadius: AppRadius.radiusXs,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.darkOnSurfaceMedium
                                    : AppColors.lightOnSurfaceMedium)
                                .withValues(alpha: 0.3),
                            borderRadius: AppRadius.radiusXs,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme options group
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeOptionsGroup extends StatelessWidget {
  const _ThemeOptionsGroup({
    required this.currentMode,
    required this.onSelect,
    required this.isDark,
    required this.colorScheme,
  });

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onSelect;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final options = [
      _ThemeOption(
        mode: ThemeMode.light,
        icon: Icons.light_mode_rounded,
        label: 'Light',
        description: 'Bright background, ideal for daytime use',
      ),
      _ThemeOption(
        mode: ThemeMode.dark,
        icon: Icons.dark_mode_rounded,
        label: 'Dark',
        description: 'Reduced glare, easier on the eyes at night',
      ),
      _ThemeOption(
        mode: ThemeMode.system,
        icon: Icons.settings_brightness_rounded,
        label: 'System',
        description: 'Follow your device\'s display setting',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _ThemeOptionRow(
              option: options[i],
              isSelected: currentMode == options[i].mode,
              colorScheme: colorScheme,
              onTap: () => onSelect(options[i].mode),
            ),
            if (i < options.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg + 38 + AppSpacing.md,
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.3 : 0.5,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.description,
  });

  final ThemeMode mode;
  final IconData icon;
  final String label;
  final String description;
}

class _ThemeOptionRow extends StatelessWidget {
  const _ThemeOptionRow({
    required this.option,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  final _ThemeOption option;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(
                  option.icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
