import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../expenses/presentation/state/bill_providers.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../groups/presentation/state/group_providers.dart';
import '../../../groups/presentation/view/group_details_screen.dart';
import '../../../users/domain/entities/app_user.dart';

/// Home tab for the app shell.
///
/// Displays a greeting header, financial summary card, quick stat tiles,
/// and a list of the user's groups. All data is sourced from real-time
/// Riverpod providers — no mocked values.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onNavigateToTab});

  /// Callback to switch the bottom nav tab (e.g. to the Groups tab).
  final void Function(int index)? onNavigateToTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  AnimationController? _entranceCtrl;
  AnimationController? _ambientCtrl;

  /// Lazily creates the entrance controller on first access so that hot
  /// reload (which doesn't re-run initState) doesn't crash with a
  /// LateInitializationError.
  AnimationController get _entrance => _entranceCtrl ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward();

  /// Lazily creates the ambient controller on first access.
  AnimationController get _ambient => _ambientCtrl ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4000),
      )..repeat();

  @override
  void dispose() {
    _entranceCtrl?.dispose();
    _ambientCtrl?.dispose();
    super.dispose();
  }

  /// Helper that wraps a widget with a shared fade + slide entrance.
  Widget _staggeredEntrance(
    Widget child, {
    required double start,
    required double end,
    double slide = 24,
    Curve curve = Curves.easeOutCubic,
  }) {
    return StaggeredEntrance(
      animation: _entrance,
      interval: Interval(start, end, curve: curve),
      slideOffset: slide,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appUserAsync = ref.watch(currentAppUserProvider);
    final groupsAsync = ref.watch(groupsForCurrentUserProvider);
    final balanceAsync = ref.watch(userBalanceProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _staggeredEntrance(
              _buildHeader(colorScheme, appUserAsync),
              start: 0.0,
              end: 0.25,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _staggeredEntrance(
              _buildFinancialSummaryCard(colorScheme, balanceAsync),
              start: 0.08,
              end: 0.32,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _buildQuickStatsRow(colorScheme, balanceAsync),
            const SizedBox(height: AppSpacing.xxxl),
            _buildYourGroupsSection(colorScheme, groupsAsync),
            const SizedBox(height: AppSpacing.xxxl),
            _staggeredEntrance(
              _buildSettleBanner(colorScheme),
              start: 0.62,
              end: 0.82,
            ),
            const SizedBox(height: AppSpacing.giant + AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Greeting header
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme colorScheme, AsyncValue<AppUser?> userAsync) {
    return Row(
      children: [
        userAsync.when(
          data: (user) => (user?.profilePicture != null &&
                  user!.profilePicture!.isNotEmpty)
              ? CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(user.profilePicture!),
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
          loading: () => CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          error: (_, __) => CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${userAsync.maybeWhen(
                      data: (user) =>
                          (user?.displayName?.isNotEmpty == true
                              ? user!.displayName!
                              : user?.fullName) ??
                          'there',
                      orElse: () => 'there',
                    )} 👋',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome back',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _staggeredEntrance(
          _buildNotificationButton(colorScheme),
          start: 0.05,
          end: 0.25,
        ),
      ],
    );
  }

  Widget _buildNotificationButton(ColorScheme colorScheme) {
    return IconButton(
      onPressed: () {},
      icon: Badge(
        smallSize: 8,
        backgroundColor: colorScheme.error,
        child: Icon(
          Icons.notifications_outlined,
          color: colorScheme.onSurface,
          size: 28,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Financial summary card
  // ───────────────────────────────────────────────────────────────────────────

  /// Financial summary card — the hero of the home screen.
  ///
  /// Uses a solid `colorScheme.primary` background in **both** light and
  /// dark mode.  All content is rendered in `AppColors.white` so it remains
  /// crisp and readable regardless of the theme — `colorScheme.onPrimary` in
  /// dark mode is dark navy and would vanish on the bright teal.
  Widget _buildFinancialSummaryCard(
    ColorScheme colorScheme,
    AsyncValue<UserBalance> balanceAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Colours resolved purely from design-system tokens ──────────────────
    final contentColor = isDark ? AppColors.white : colorScheme.onPrimary;
    final contentSoft = contentColor.withValues(alpha: 0.85);
    final contentMuted = contentColor.withValues(alpha: isDark ? 0.60 : 0.65);
    final blobColor = isDark
        ? AppColors.white.withValues(alpha: 0.07)
        : colorScheme.onPrimary.withValues(alpha: 0.18);
    final tagBg = contentColor.withValues(alpha: isDark ? 0.15 : 0.22);
    final tagFg = contentColor;
    final iconCircleBg = contentColor.withValues(alpha: isDark ? 0.18 : 0.2);

    // Real balance data.
    final balance = balanceAsync.valueOrNull ?? const UserBalance.zero();
    final netBalance = balance.youAreOwed - balance.youOwe;
    final isAhead = netBalance >= 0;

    // Entrance: scale + fade.
    final entranceAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.08, 0.32, curve: Curves.easeOutBack),
      ),
    );
    final entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.08, 0.28, curve: Curves.easeIn),
      ),
    );

    // Pulsing blob (0.85 → 1.0 → 0.85).
    final blobPulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ambient,
        curve: Curves.easeInOutSine,
      ),
    );

    // Shimmer sweep (0 → 1, loops).
    final shimmer = Tween<double>(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(parent: _ambient, curve: Curves.easeInOut),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entrance,
        _ambient,
      ]),
      builder: (context, _) {
        final scale = entranceAnim.value.clamp(0.0, 1.2);
        final opacity = entranceOpacity.value.clamp(0.0, 1.0);

        // Pulsing glow.
        final pulse = (1 - math.cos(math.pi * 2 * _ambient.value)) * 0.5;
        final glowAlpha =
            isDark ? (0.12 + 0.15 * pulse) : (0.15 + 0.30 * pulse);
        final glowBlur = isDark ? (20 + 16 * pulse) : (16 + 12 * pulse);
        final glowSpread = isDark ? (1 + pulse) : (2 + 2 * pulse);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusXxxl,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                    spreadRadius: glowSpread,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.radiusXxxl,
                child: SizedBox(
                  height: 190,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // ── 1. Card background (static) ─────────────────────
                      _buildCardBackground(colorScheme),

                      // ── 2. Pulsing glow blob ──────────────────────────────
                      Positioned(
                        right: -34,
                        top: -34,
                        child: Transform.scale(
                          scale: blobPulse.value,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: blobColor,
                            ),
                          ),
                        ),
                      ),

                      // ── 3. Shimmer sweep ──────────────────────────────────
                      _buildShimmerSweep(shimmer.value),

                      // ── 4. Floating wallet ────────────────────────────────
                      Positioned(
                        right: -16,
                        bottom: -10,
                        child: _buildFloatingWallet(),
                      ),

                      // ── 5. Text content ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row.
                            Row(
                              children: [
                                Text(
                                  'Your Financial Summary',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: contentSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: contentMuted,
                                  size: 20,
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Net Balance label.
                            Text(
                              'Net Balance',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: contentMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            // Amount + trend icon.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  AppConstants.formatCurrency(
                                    netBalance.abs(),
                                    withSymbol: true,
                                  ),
                                  style: AppTextStyles.headlineLarge.copyWith(
                                    color: contentColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: iconCircleBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isAhead
                                        ? Icons.north_east_rounded
                                        : Icons.south_west_rounded,
                                    color: contentColor,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Status pill.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: tagBg,
                                borderRadius: AppRadius.radiusFull,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAhead
                                        ? Icons.check_circle_rounded
                                        : Icons.info_rounded,
                                    color: tagFg,
                                    size: 14,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    isAhead
                                        ? "You're ahead"
                                        : "You're behind",
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: tagFg,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Card background — static, no rotation.
  Widget _buildCardBackground(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            colorScheme.primary.withValues(alpha: 0.45),
            colorScheme.surface,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
      ),
    );
  }

  /// A translucent vertical light band that sweeps left → right across the
  /// card.  Driven by the ambient animation controller.
  Widget _buildShimmerSweep(double t) {
    final left = t * 1.0;
    return Positioned.fill(
      child: CustomPaint(
        painter: _ShimmerPainter(progress: left.clamp(-0.5, 1.5)),
      ),
    );
  }

  /// Wallet image with a continuous gentle bob after the entrance pop.
  Widget _buildFloatingWallet() {
    final pop = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.12, 0.42, curve: Curves.easeOutBack),
      ),
    );
    final float = (math.sin(_ambient.value * 2 * 3.14159) * 6.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _ambient]),
      builder: (context, child) {
        final s = pop.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -float * s),
          child: Transform.scale(
            scale: s,
            alignment: Alignment.bottomRight,
            child: Opacity(
              opacity: s,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/images/wallet.png',
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Quick stats row
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildQuickStatsRow(
    ColorScheme colorScheme,
    AsyncValue<UserBalance> balanceAsync,
  ) {
    final balance = balanceAsync.valueOrNull ?? const UserBalance.zero();

    final stats = [
      _QuickStat(
        label: "You're Owed",
        amount: AppConstants.formatCurrency(balance.youAreOwed,
            withSymbol: true),
        caption:
            'Across ${balance.youAreOwedGroupCount} group${balance.youAreOwedGroupCount == 1 ? '' : 's'}',
        icon: Icons.arrow_downward,
        iconColor: AppColors.chartTeal,
      ),
      _QuickStat(
        label: 'You Owe',
        amount:
            AppConstants.formatCurrency(balance.youOwe, withSymbol: true),
        caption:
            'Across ${balance.youOweGroupCount} group${balance.youOweGroupCount == 1 ? '' : 's'}',
        icon: Icons.arrow_upward,
        iconColor: AppColors.chartOrange,
      ),
      _QuickStat(
        label: 'Net Balance',
        amount: AppConstants.formatCurrency(
            (balance.youAreOwed - balance.youOwe).abs(),
            withSymbol: true),
        caption: (balance.youAreOwed - balance.youOwe) >= 0
            ? "You're ahead"
            : "You're behind",
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.chartBlue,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _staggeredEntrance(
                _QuickStatCard(
                  stat: stats[i],
                  colorScheme: colorScheme,
                ),
                start: 0.2 + (i * 0.06),
                end: 0.42 + (i * 0.06),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Your groups section
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildYourGroupsSection(
    ColorScheme colorScheme,
    AsyncValue<List<Group>> groupsAsync,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredEntrance(
          _buildSectionHeader(
            'Your Groups',
            colorScheme,
            onSeeAll: () => widget.onNavigateToTab?.call(1),
          ),
          start: 0.45,
          end: 0.6,
        ),
        const SizedBox(height: AppSpacing.md),
        groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return _staggeredEntrance(
                _buildEmptyGroups(colorScheme),
                start: 0.5,
                end: 0.65,
              );
            }
            // Show at most 3 groups, sorted by most recently updated.
            final sorted = [...groups]
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            final shown = sorted.take(3).toList();
            return Column(
              children: shown.indexed.map((e) {
                final (index, group) = e;
                return _staggeredEntrance(
                  _GroupListTile(
                    group: group,
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  start: 0.52 + (index * 0.05),
                  end: 0.72 + (index * 0.05),
                );
              }).toList(),
            );
          },
          loading: () => _buildGroupsSkeleton(colorScheme, isDark),
          error: (_, __) => _staggeredEntrance(
            _buildEmptyGroups(colorScheme),
            start: 0.5,
            end: 0.65,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyGroups(ColorScheme colorScheme) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_2_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No groups yet',
            style: AppTextStyles.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a group to start splitting bills.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsSkeleton(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          height: 76,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadius.radiusXxl,
            boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: LinearProgressIndicator(
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                color: colorScheme.primary.withValues(alpha: 0.2),
                minHeight: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Settle up banner
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSettleBanner(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: AppRadius.radiusXxl,
        boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_rupee_rounded,
              color: colorScheme.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settle up easily',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Clear dues, keep relationships happy.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => widget.onNavigateToTab?.call(1),
            child: const Text('Settle Now'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    String title,
    ColorScheme colorScheme, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'See all',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Private data classes
// ═════════════════════════════════════════════════════════════════════════════

class _QuickStat {
  const _QuickStat({
    required this.label,
    required this.amount,
    required this.caption,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String amount;
  final String caption;
  final IconData icon;
  final Color iconColor;
}

// ═════════════════════════════════════════════════════════════════════════════
// Quick stat card
// ═════════════════════════════════════════════════════════════════════════════

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.stat,
    required this.colorScheme,
  });

  final _QuickStat stat;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXl,
        boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
        border: Border(
          top: BorderSide(
            color: stat.iconColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: stat.iconColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: stat.iconColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Icon(
              stat.icon,
              color: stat.iconColor,
              size: 18,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stat.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            stat.amount,
            style: AppTextStyles.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.caption,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Group list tile — uses real Group data
// ═════════════════════════════════════════════════════════════════════════════

class _GroupListTile extends ConsumerWidget {
  const _GroupListTile({
    required this.group,
    required this.colorScheme,
    required this.isDark,
  });

  final Group group;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    return GestureDetector(
      onTap: () {
        if (uid == null) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupDetailsScreen(
              group: group,
              currentUserId: uid,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.radiusXxl,
          boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.radiusLg,
              ),
              child: Icon(
                Icons.groups_2_rounded,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shimmer painter
// ═════════════════════════════════════════════════════════════════════════════

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final bandWidth = width * 0.25;
    final centerX = progress * width;

    final rect = Rect.fromCenter(
      center: Offset(centerX, height / 2),
      width: bandWidth,
      height: height * 1.5,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.save();
    canvas.rotate(0.15);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
