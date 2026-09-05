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
  AnimationController? _settleBtnCtrl;

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

  /// Drives the "Settle Now" button's expand/contract cycle. Slower than
  /// the ambient loop so the text lingers long enough to read.
  AnimationController get _settleBtn => _settleBtnCtrl ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 7000),
      )..repeat();

  @override
  void dispose() {
    _entranceCtrl?.dispose();
    _ambientCtrl?.dispose();
    _settleBtnCtrl?.dispose();
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
                    entranceController: _entrance,
                    index: index,
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
      children: List.generate(
        3,
        (index) => _GroupListTileSkeleton(
          colorScheme: colorScheme,
          isDark: isDark,
        ),
      ),
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
        borderRadius: AppRadius.radiusLg,
        boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: Row(
        children: [
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
          const SizedBox(width: AppSpacing.md),
          _buildSettleNowButton(colorScheme),
        ],
      ),
    );
  }

  /// The "Settle Now" button with a continuous expand/contract animation,
  /// mirroring the `_AnimatedCreateBillButton` on the group details screen:
  /// it cycles between a bare right-arrow icon and the full "Settle Now"
  /// label, driven by the shared ambient controller.
  Widget _buildSettleNowButton(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _settleBtn,
      builder: (context, _) {
        final t = _settleBtn.value;
        final showText = t > 0.5;

        // Smooth progress values for animation.
        final expandProgress = showText
            ? ((t - 0.45) / 0.15).clamp(0.0, 1.0)
            : ((0.55 - t) / 0.15).clamp(0.0, 1.0);
        final collapseProgress = 1.0 - expandProgress;

        // Arrow (compact state) fades and slides right as it disappears.
        final arrowOpacity = collapseProgress;
        final arrowSlideX = expandProgress * 0.5;

        // Content slides in from right + fades in.
        final contentOpacity = expandProgress;
        final contentSlideX = (1.0 - expandProgress) * 1.0;

        final scale = 1.0 + 0.06 * math.sin(t * 2 * math.pi);

        // Fixed footprint so the card's Row layout never reflows.
        const width = 130.0;

        return GestureDetector(
          onTap: () => widget.onNavigateToTab?.call(1),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 36,
            width: width,
            child: ClipRect(
              child: Stack(
                alignment: Alignment.centerRight,
                clipBehavior: Clip.hardEdge,
                children: [
                  // Arrow (compact state) — anchored right, slides right as it exits.
                  Opacity(
                    opacity: arrowOpacity,
                    child: Transform.translate(
                      offset: Offset(arrowSlideX * 30, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Expanded content: arrow + Settle Now text — slides in from right.
                  Opacity(
                    opacity: contentOpacity,
                    child: Transform.translate(
                      offset: Offset(contentSlideX * 100, 0),
                      // OverflowBox frees the Row from the animating
                      // parent width so it always lays out at its natural
                      // size. The outer ClipRect clips the overflow during
                      // the expand/collapse transition instead of letting
                      // the RenderFlex overflow.
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        maxWidth: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              'Settle Now',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
// Group list tile — premium card with gradient accent, avatar stack & animation
// ═════════════════════════════════════════════════════════════════════════════

/// A premium group card with:
/// - A colored left accent bar that gradients into the card
/// - The group icon in a tinted rounded container
/// - Group name + member count
/// - Up to 3 overlapping member avatars at the right
/// - An animated press-scale feedback
class _GroupListTile extends ConsumerStatefulWidget {
  const _GroupListTile({
    required this.group,
    required this.colorScheme,
    required this.isDark,
    required this.entranceController,
    required this.index,
  });

  final Group group;
  final ColorScheme colorScheme;
  final bool isDark;
  final AnimationController entranceController;
  final int index;

  @override
  ConsumerState<_GroupListTile> createState() => _GroupListTileState();
}

class _GroupListTileState extends ConsumerState<_GroupListTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  static const _accentColors = [
    AppColors.chartTeal,
    AppColors.chartBlue,
    AppColors.chartPurple,
    AppColors.chartOrange,
    AppColors.chartPink,
    AppColors.chartGreen,
  ];

  Color get _accent => _accentColors[widget.index % _accentColors.length];

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final cs = widget.colorScheme;
    final group = widget.group;
    final accent = _accent;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
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
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) => Transform.scale(
          scale: _press.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadius.radiusXxl,
            boxShadow:
                widget.isDark ? AppShadows.smDark : AppShadows.smLight,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusXxl,
            child: Row(
              children: [
                // ── Left accent bar ──────────────────────────────────────
                Container(
                  width: 5,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent,
                        accent.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                // ── Content ──────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        // Group icon container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: AppRadius.radiusMd,
                          ),
                          child: Icon(
                            Icons.groups_2_rounded,
                            color: accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Name + member count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                group.groupName,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 13,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Member avatar stack
                        _MiniAvatarRow(
                          members: group.members,
                          accent: accent,
                          surfaceColor: cs.surface,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini avatar row — compact overlapping avatars for the group tile
// ─────────────────────────────────────────────────────────────────────────────

class _MiniAvatarRow extends StatelessWidget {
  const _MiniAvatarRow({
    required this.members,
    required this.accent,
    required this.surfaceColor,
  });

  final List<GroupMember> members;
  final Color accent;
  final Color surfaceColor;

  static const _bgColors = [
    AppColors.chartBlue,
    AppColors.chartPurple,
    AppColors.chartTeal,
    AppColors.chartOrange,
    AppColors.chartPink,
    AppColors.chartGreen,
  ];

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    const maxAvatars = 3;
    final shown = members.take(maxAvatars).toList();
    final remaining = members.length - shown.length;
    const avatarSize = 26.0;
    const overlap = 16.0;

    return SizedBox(
      height: avatarSize,
      width: avatarSize + (shown.length - 1) * overlap +
          (remaining > 0 ? 32 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: _MiniAvatar(
                member: shown[i],
                size: avatarSize,
                ringColor: surfaceColor,
                bgColor: _bgColors[i % _bgColors.length],
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: shown.length * overlap,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: surfaceColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remaining',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({
    required this.member,
    required this.size,
    required this.ringColor,
    required this.bgColor,
  });

  final GroupMember member;
  final double size;
  final Color ringColor;
  final Color bgColor;

  String _initials() {
    final name = (member.displayName?.isNotEmpty == true
            ? member.displayName!
            : member.fullName)
        .trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        member.profilePicture != null && member.profilePicture!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                member.profilePicture!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsCircle(),
              ),
            )
          : _initialsCircle(),
    );
  }

  Widget _initialsCircle() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Group list tile skeleton — shimmer placeholder mimicking _GroupListTile
// ═════════════════════════════════════════════════════════════════════════════

class _GroupListTileSkeleton extends StatefulWidget {
  const _GroupListTileSkeleton({
    required this.colorScheme,
    required this.isDark,
  });

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  State<_GroupListTileSkeleton> createState() => _GroupListTileSkeletonState();
}

class _GroupListTileSkeletonState extends State<_GroupListTileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final base = cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final highlight = cs.surfaceContainerHighest.withValues(alpha: 0.9);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.radiusXxl,
        boxShadow: widget.isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXxl,
        child: Stack(
          children: [
            // ── Tile layout placeholder (mirrors _GroupListTile) ───────────
            Row(
              children: [
                // Left accent bar placeholder.
                Container(
                  width: 5,
                  height: 80,
                  color: base,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        // Group icon box placeholder.
                        _SkeletonBox(
                          width: 48,
                          height: 48,
                          color: base,
                          radius: AppRadius.radiusMd,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Name + member count placeholders.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SkeletonBox(width: 140, height: 14, color: base),
                              const SizedBox(height: 6),
                              _SkeletonBox(width: 90, height: 10, color: base),
                            ],
                          ),
                        ),
                        // Avatar placeholders.
                        SizedBox(
                          width: 28.0 + 2 * 18.0,
                          height: 28,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (int i = 0; i < 3; i++)
                                Positioned(
                                  left: i * 18.0,
                                  child: _SkeletonBox(
                                    width: 28,
                                    height: 28,
                                    color: base,
                                    radius: BorderRadius.circular(14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ── Shimmer sweep overlay ───────────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  final t = _shimmerController.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1 + 2 * t, 0),
                        end: Alignment(-1 + 2 * t + 0.5, 0),
                        colors: [
                          Colors.transparent,
                          highlight.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    required this.color,
    this.radius,
  });

  final double? width;
  final double? height;
  final Color color;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius ?? BorderRadius.circular(6),
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
