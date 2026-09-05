import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Privacy & Security settings screen.
///
/// Displays a security status hero card, a biometric lock toggle,
/// password management, data privacy controls, and legal links.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  // ── Toggle states ──
  bool _biometricLock = false;
  bool _hideBalance = false;
  bool _shareAnalytics = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Security status hero card ───────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.0, 0.45, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl,
                  ),
                  child: _SecurityStatusCard(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    biometricEnabled: _biometricLock,
                  ),
                ),
              ),
            ),

            // ── Authentication section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.1, 0.55, curve: Curves.easeOut),
                child: _SectionLabel(label: 'Authentication'),
              ),
            ),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.13, 0.58, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _ToggleGroup(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    items: [
                      _ToggleItem(
                        icon: Icons.fingerprint_rounded,
                        label: 'Biometric Lock',
                        subtitle: 'Require fingerprint or face ID to open',
                        value: _biometricLock,
                        onChanged: (v) =>
                            setState(() => _biometricLock = v),
                      ),
                      _ToggleItem(
                        icon: Icons.visibility_off_outlined,
                        label: 'Hide Balance',
                        subtitle: 'Mask amounts on the home screen',
                        value: _hideBalance,
                        onChanged: (v) =>
                            setState(() => _hideBalance = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Account security section ────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.2, 0.65, curve: Curves.easeOut),
                child: _SectionLabel(label: 'Account Security'),
              ),
            ),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.23, 0.68, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _NavGroup(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    items: [
                      _NavItem(
                        icon: Icons.password_outlined,
                        label: 'Change Password',
                        onTap: () {},
                      ),
                      _NavItem(
                        icon: Icons.email_outlined,
                        label: 'Change Email',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Data & Privacy section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.3, 0.72, curve: Curves.easeOut),
                child: _SectionLabel(label: 'Data & Privacy'),
              ),
            ),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.33, 0.75, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: Column(
                    children: [
                      _ToggleGroup(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        items: [
                          _ToggleItem(
                            icon: Icons.analytics_outlined,
                            label: 'Share Analytics',
                            subtitle: 'Help improve the app with usage data',
                            value: _shareAnalytics,
                            onChanged: (v) =>
                                setState(() => _shareAnalytics = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _NavGroup(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        items: [
                          _NavItem(
                            icon: Icons.download_outlined,
                            label: 'Export My Data',
                            onTap: () {},
                          ),
                          _NavItem(
                            icon: Icons.delete_forever_outlined,
                            label: 'Delete Account',
                            isDestructive: true,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Legal section ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.4, 0.8, curve: Curves.easeOut),
                child: _SectionLabel(label: 'Legal'),
              ),
            ),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                animation: _entranceController,
                interval: const Interval(0.43, 0.83, curve: Curves.easeOut),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: _NavGroup(
                    isDark: isDark,
                    colorScheme: colorScheme,
                    items: [
                      _NavItem(
                        icon: Icons.description_outlined,
                        label: 'Privacy Policy',
                        onTap: () {},
                      ),
                      _NavItem(
                        icon: Icons.gavel_outlined,
                        label: 'Terms of Service',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security status hero card
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard({
    required this.isDark,
    required this.colorScheme,
    required this.biometricEnabled,
  });

  final bool isDark;
  final ColorScheme colorScheme;
  final bool biometricEnabled;

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? AppColors.darkPrimaryGradient
        : AppColors.lightPrimaryGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.radiusXxl,
        boxShadow: isDark
            ? AppShadows.primaryGlowDark
            : AppShadows.primaryGlowLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        children: [
          // Shield icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.22),
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 28,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biometricEnabled ? 'Well Protected' : 'Strengthen Security',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  biometricEnabled
                      ? 'Biometric lock is active. Your data is secured.'
                      : 'Enable biometric lock to keep your data safe.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                    height: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle group (switches)
// ─────────────────────────────────────────────────────────────────────────────

class _ToggleItem {
  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _ToggleGroup extends StatelessWidget {
  const _ToggleGroup({
    required this.items,
    required this.isDark,
    required this.colorScheme,
  });

  final List<_ToggleItem> items;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < items.length; i++) ...[
            _ToggleRow(item: items[i], colorScheme: colorScheme),
            if (i < items.length - 1)
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.item, required this.colorScheme});
  final _ToggleItem item;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: AppRadius.radiusSm,
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: item.value,
            onChanged: item.onChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation group (rows with chevrons)
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

class _NavGroup extends StatelessWidget {
  const _NavGroup({
    required this.items,
    required this.isDark,
    required this.colorScheme,
  });

  final List<_NavItem> items;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < items.length; i++) ...[
            _NavRow(item: items[i], colorScheme: colorScheme),
            if (i < items.length - 1)
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

class _NavRow extends StatelessWidget {
  const _NavRow({required this.item, required this.colorScheme});
  final _NavItem item;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        item.isDestructive ? colorScheme.error : colorScheme.primary;
    final iconBg = item.isDestructive
        ? colorScheme.errorContainer.withValues(alpha: 0.4)
        : colorScheme.primaryContainer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: baseColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: item.isDestructive
                        ? colorScheme.error
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: item.isDestructive
                    ? colorScheme.error.withValues(alpha: 0.6)
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
