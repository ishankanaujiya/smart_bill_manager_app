import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Home tab for the app shell.
///
/// Mirrors the provided design: greeting header, financial summary card,
/// quick stat tiles, active payments, groups list and a settle-up banner.
/// Every section is wrapped in a coordinated staggered entrance animation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _staggeredEntrance(
              _buildHeader(colorScheme),
              start: 0.0,
              end: 0.25,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _staggeredEntrance(
              _buildFinancialSummaryCard(colorScheme),
              start: 0.08,
              end: 0.32,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            _buildQuickStatsRow(colorScheme),
            const SizedBox(height: AppSpacing.xxxl),
            _buildActivePaymentsSection(colorScheme),
            const SizedBox(height: AppSpacing.xxxl),
            _buildYourGroupsSection(colorScheme),
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.person_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Ishan 👋',
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
  /// Uses the primary colour as the dominant background in **both** light and
  /// dark mode (`primary → tertiary` diagonal gradient).  All content is
  /// rendered in `AppColors.white` so it remains crisp and readable regardless
  /// of the theme — `colorScheme.onPrimary` in dark mode is dark navy and would
  /// vanish on the bright teal.
  ///
  /// Layered animations:
  /// 1.  Entrance — card scales + fades in.
  /// 2.  Pulsing glow blob — a soft white circle behind the wallet breathes.
  /// 3.  Floating wallet — the wallet illustration bobs up and down forever.
  /// 4.  Shimmer sweep — a subtle light streak sweeps across the card.
  /// 5.  Pulsing glow shadow — the card's teal shadow breathes.
  Widget _buildFinancialSummaryCard(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Colours resolved purely from design-system tokens ──────────────────
    //
    // In light mode we follow the colour scheme and let `onPrimary` be white.
    // In dark mode the card uses a dark primary-tinted surface, so all content
    // must be white for contrast — `onPrimary` in dark is dark navy and would
    // vanish against the dark teal.
    final contentColor = isDark ? AppColors.white : colorScheme.onPrimary;
    final contentSoft = contentColor.withValues(alpha: 0.85);
    final contentMuted = contentColor.withValues(alpha: isDark ? 0.60 : 0.65);
    final blobColor = isDark
        ? AppColors.white.withValues(alpha: 0.07)
        : colorScheme.onPrimary.withValues(alpha: 0.18);
    // Dark mode uses a slightly higher alpha for the pill and icon circle
    // so they read clearly against the bright teal gradient.
    final tagBg = contentColor.withValues(alpha: isDark ? 0.15 : 0.22);
    final tagFg = contentColor;
    final iconCircleBg = contentColor.withValues(alpha: isDark ? 0.18 : 0.2);

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

        // Pulsing glow — same technique as the sign-in button.
        // Dark mode uses a softer, more diffuse glow so the bright teal
        // doesn't overpower the surrounding dark surface.
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
                                  'Rs. 12,450',
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
                                    Icons.north_east_rounded,
                                    color: contentColor,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // "You're ahead" pill.
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
                                    Icons.check_circle_rounded,
                                    color: tagFg,
                                    size: 14,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    "You're ahead",
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
  ///
  /// **Light mode** uses the full-saturation `primary → tertiary` gradient for
  /// a vibrant, energetic feel.
  ///
  /// **Dark mode** uses a toned-down version of the same gradient — the
  /// primary and tertiary colours are blended with the dark surface so the
  /// card retains its teal identity without glowing too brightly against the
  /// surrounding dark theme.  All content stays white for crisp contrast.
  Widget _buildCardBackground(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark mode: blend 45% of the primary/tertiary into the dark surface.
    // This darkens the gradient while preserving the teal-to-green hue shift.
    if (isDark) {
      Color blend(Color c) => Color.alphaBlend(
            c.withValues(alpha: 0.45),
            colorScheme.surface,
          );
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              blend(colorScheme.primary),
              blend(colorScheme.tertiary),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
        ),
      ),
    );
  }

  /// A translucent vertical light band that sweeps left → right across the
  /// card.  Driven by the ambient controller so it loops forever.
  Widget _buildShimmerSweep(double t) {
    // `t` ranges from -0.3 → 1.3.  Map to a fraction of card width.
    final left = t * 1.0; // 0..1 of width
    return Positioned.fill(
      child: CustomPaint(
        painter: _ShimmerPainter(progress: left.clamp(-0.5, 1.5)),
      ),
    );
  }

  /// Wallet image with a continuous gentle bob after the entrance pop.
  Widget _buildFloatingWallet() {
    // Entrance pop (scale + fade).
    final pop = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.12, 0.42, curve: Curves.easeOutBack),
      ),
    );
    // Continuous float (±6px sine wave).
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

  Widget _buildQuickStatsRow(ColorScheme colorScheme) {
    const stats = [
      _QuickStat(
        label: 'Money Received',
        amount: 'Rs. 18,750',
        caption: 'from 5 people',
        icon: Icons.arrow_downward,
        iconColor: AppColors.chartTeal,
      ),
      _QuickStat(
        label: 'Money to Pay',
        amount: 'Rs. 6,300',
        caption: 'to 3 people',
        icon: Icons.arrow_upward,
        iconColor: AppColors.success,
      ),
      _QuickStat(
        label: 'Settled This Month',
        amount: 'Rs. 9,650',
        caption: 'across 12 payments',
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
  // Active payments section
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildActivePaymentsSection(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const payments = [
      _ActivePayment(
        name: 'Goa Trip',
        icon: Icons.beach_access_rounded,
        iconColor: AppColors.chartTeal,
        status: 'You owe',
        amount: 'Rs. 2,450',
        isOwed: true,
        progress: 0.5,
        fraction: '2/4 paid',
        memberColors: [
          AppColors.chartTeal,
          AppColors.chartOrange,
          AppColors.chartBlue,
          AppColors.chartPurple
        ],
      ),
      _ActivePayment(
        name: 'Office Dinner',
        icon: Icons.restaurant_rounded,
        iconColor: AppColors.chartOrange,
        status: 'You owe',
        amount: 'Rs. 1,200',
        isOwed: true,
        progress: 0.25,
        fraction: '1/4 paid',
        memberColors: [
          AppColors.chartOrange,
          AppColors.chartBlue,
          AppColors.chartPurple,
          AppColors.chartPink
        ],
      ),
      _ActivePayment(
        name: 'Weekend Retreat',
        icon: Icons.landscape_rounded,
        iconColor: AppColors.chartGreen,
        status: "You'll receive",
        amount: 'Rs. 850',
        isOwed: false,
        progress: 0.75,
        fraction: '3/4 paid',
        memberColors: [
          AppColors.chartGreen,
          AppColors.chartCyan,
          AppColors.chartYellow,
          AppColors.chartBlue
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredEntrance(
          _buildSectionHeader('Active Payments', colorScheme),
          start: 0.3,
          end: 0.45,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 200,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              return _staggeredEntrance(
                _ActivePaymentCard(
                  payment: payments[index],
                  colorScheme: colorScheme,
                  isDark: isDark,
                  entranceController: _entrance,
                ),
                start: 0.38 + (index * 0.06),
                end: 0.58 + (index * 0.06),
              );
            },
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Your groups section
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildYourGroupsSection(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const groups = [
      _GroupItem(
        name: 'Goa Trip',
        members: 4,
        icon: Icons.beach_access_rounded,
        iconColor: AppColors.chartTeal,
        amount: 'Rs. 2,450',
      ),
      _GroupItem(
        name: 'Flatmates',
        members: 5,
        icon: Icons.restaurant_rounded,
        iconColor: AppColors.chartOrange,
        amount: 'Rs. 1,800',
      ),
      _GroupItem(
        name: 'Office Team',
        members: 6,
        icon: Icons.work_rounded,
        iconColor: AppColors.chartBlue,
        amount: 'Rs. 3,200',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredEntrance(
          _buildSectionHeader('Your Groups', colorScheme),
          start: 0.45,
          end: 0.6,
        ),
        const SizedBox(height: AppSpacing.md),
        ...groups.indexed.map((e) {
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
        }),
      ],
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
            onPressed: () {},
            child: const Text('Settle Now'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: () {},
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

class _ActivePayment {
  const _ActivePayment({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.amount,
    required this.isOwed,
    required this.progress,
    required this.fraction,
    required this.memberColors,
  });

  final String name;
  final IconData icon;
  final Color iconColor;
  final String status;
  final String amount;
  final bool isOwed;
  final double progress;
  final String fraction;
  final List<Color> memberColors;
}

class _GroupItem {
  const _GroupItem({
    required this.name,
    required this.members,
    required this.icon,
    required this.iconColor,
    required this.amount,
  });

  final String name;
  final int members;
  final IconData icon;
  final Color iconColor;
  final String amount;
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
        // Subtle primary top accent — matches the auth step indicator.
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
          // Icon circle — surface fill with a stat-specific tinted border and
          // icon, plus a subtle glow in that same colour.
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
          // Label – may wrap to two lines (matches the design for long labels).
          Text(
            stat.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Amount – semi-bold, primary text colour.
          Text(
            stat.amount,
            style: AppTextStyles.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          // Caption.
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
// Active payment card
// ═════════════════════════════════════════════════════════════════════════════

class _ActivePaymentCard extends StatelessWidget {
  const _ActivePaymentCard({
    required this.payment,
    required this.colorScheme,
    required this.isDark,
    required this.entranceController,
  });

  final _ActivePayment payment;
  final ColorScheme colorScheme;
  final bool isDark;
  final AnimationController entranceController;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        payment.isOwed ? AppColors.chartOrange : AppColors.success;

    return Container(
      width: 170,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: payment.iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusLg,
                ),
                child: Icon(
                  payment.icon,
                  color: payment.iconColor,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            payment.name,
            style: AppTextStyles.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            payment.status,
            style: AppTextStyles.bodySmall.copyWith(
              color: statusColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            payment.amount,
            style: AppTextStyles.titleMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _buildProgressBar(
            progress: payment.progress,
            color: payment.iconColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildAvatarStack(payment.memberColors),
              const Spacer(),
              Text(
                payment.fraction,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required double progress,
    required Color color,
  }) {
    final progressAnimation = Tween<double>(begin: 0.0, end: progress).animate(
      CurvedAnimation(
        parent: entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: colorScheme.outlineVariant,
        borderRadius: AppRadius.radiusFull,
      ),
      child: AnimatedBuilder(
        animation: progressAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            widthFactor: progressAnimation.value.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: AppRadius.radiusFull,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarStack(List<Color> colors) {
    return SizedBox(
      height: 28,
      width: (colors.length - 1) * 18.0 + 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 18.0,
              child: _buildAvatar(colors[i], i),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, int index) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.surface,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          String.fromCharCode('A'.codeUnitAt(0) + index),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Group list tile
// ═════════════════════════════════════════════════════════════════════════════

class _GroupListTile extends StatelessWidget {
  const _GroupListTile({
    required this.group,
    required this.colorScheme,
    required this.isDark,
  });

  final _GroupItem group;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: group.iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusLg,
            ),
            child: Icon(
              group.icon,
              color: group.iconColor,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.members} members',
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'You owe',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.chartOrange,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                group.amount,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.chartOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shimmer painter — paints a soft diagonal light band that sweeps across the
// financial summary card.  Driven by the ambient animation controller.
// ═════════════════════════════════════════════════════════════════════════════

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  /// 0 = far left, 1 = far right.  Values outside [0, 1] keep the band
  /// off-card so the sweep fades in/out naturally.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // The band is ~25% of the card width.
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
    canvas.rotate(0.15); // slight diagonal tilt
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
