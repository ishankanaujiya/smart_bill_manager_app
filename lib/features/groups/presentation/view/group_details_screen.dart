import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../expenses/domain/entities/bill.dart';
import '../../../expenses/presentation/state/bill_providers.dart';
import '../../../expenses/presentation/view/bill_details_screen.dart';
import '../../../expenses/presentation/view/create_bill_screen.dart';
import '../../domain/entities/group.dart';

/// Group details screen — shows the group's header, stats summary,
/// a real-time list of bills in the group, and a prominent CTA to
/// create a new bill.
///
/// When the group has no bills yet, an animated empty state with a
/// "Create Bill" button is shown instead of the list.
class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  final Group group;
  final String currentUserId;

  @override
  ConsumerState<GroupDetailsScreen> createState() =>
      _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _openCreateBill() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateBillScreen(
          group: widget.group,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _openBillDetails(Bill bill) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BillDetailsScreen(
          bill: bill,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final billsAsync = ref.watch(billsForGroupProvider(widget.group.id));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: billsAsync.when(
            data: (bills) => [
              // ── App bar with group info ────────────────────────────────
              SliverToBoxAdapter(
                child: _TopBar(
                  group: widget.group,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  entranceController: _entranceController,
                  ambientController: _ambientController,
                  onCreateBill: _openCreateBill,
                ),
              ),
              // ── Stats row ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StatsRow(
                  bills: bills,
                  currentUserId: widget.currentUserId,
                  entranceController: _entranceController,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
              // ── Bills section header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl,
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Bills',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CountPill(
                        count: bills.length,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
              // ── Bills list / empty state ────────────────────────────────
              bills.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _BillsEmptyState(
                        entranceController: _entranceController,
                        ambientController: _ambientController,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        onCreateBill: _openCreateBill,
                      ),
                    )
                  : _buildBillsList(bills, colorScheme, isDark),
              // ── Promo card ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _PromoCard(
                  entranceController: _entranceController,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onCreateBill: _openCreateBill,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
            loading: () => [
              SliverToBoxAdapter(
                child: _GroupDetailsSkeleton(
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
            ],
            error: (error, _) => [
              SliverToBoxAdapter(
                child: _TopBar(
                  group: widget.group,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  entranceController: _entranceController,
                  ambientController: _ambientController,
                  onCreateBill: _openCreateBill,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _BillsErrorState(
                  colorScheme: colorScheme,
                  onRetry: () => ref.invalidate(
                    billsForGroupProvider(widget.group.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bills list
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBillsList(
    List<Bill> bills,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final bill = bills[index];
            return StaggeredEntrance(
              animation: _entranceController,
              interval: Interval(
                0.3 + (index * 0.06),
                0.7 + (index * 0.06),
                curve: Curves.easeOutCubic,
              ),
              slideOffset: 28,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _BillCard(
                  bill: bill,
                  color: _billColor(index),
                  isDark: isDark,
                  currentUserId: widget.currentUserId,
                  onTap: () => _openBillDetails(bill),
                ),
              ),
            );
          },
          childCount: bills.length,
        ),
      ),
    );
  }

  /// Picks a deterministic accent color per bill.
  Color _billColor(int index) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.chartColorsDark
        : AppColors.chartColorsLight;
    return palette[index % palette.length];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Top bar
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.group,
    required this.colorScheme,
    required this.isDark,
    required this.entranceController,
    required this.ambientController,
    required this.onCreateBill,
  });

  final Group group;
  final ColorScheme colorScheme;
  final bool isDark;
  final AnimationController entranceController;
  final AnimationController ambientController;
  final VoidCallback onCreateBill;

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      animation: entranceController,
      interval: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      slideOffset: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.sm,
          AppSpacing.screenHorizontal,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: group name + animated create-bill button.
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.groupName,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _AnimatedCreateBillButton(
                  ambientController: ambientController,
                  colorScheme: colorScheme,
                  onTap: onCreateBill,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            // Row 2: member count text.
            Row(
              children: [
                Icon(
                  Icons.groups_2_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (group.members.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _TopBarAvatarStack(
                members: group.members,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Animated create-bill button — cycles between add icon and "Create Bill"
// ═════════════════════════════════════════════════════════════════════════════

class _AnimatedCreateBillButton extends StatelessWidget {
  const _AnimatedCreateBillButton({
    required this.ambientController,
    required this.colorScheme,
    required this.onTap,
  });

  final AnimationController ambientController;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientController,
      builder: (context, _) {
        final t = ambientController.value;
        final showText = t > 0.5;

        // Smooth progress values for animation.
        final expandProgress = showText
            ? ((t - 0.45) / 0.15).clamp(0.0, 1.0)
            : ((0.55 - t) / 0.15).clamp(0.0, 1.0);
        final collapseProgress = 1.0 - expandProgress;

        // Add icon fades and slides right as it disappears.
        final addOpacity = collapseProgress;
        final addSlideX = expandProgress * 0.5;

        // Content slides in from right + fades in.
        final contentOpacity = expandProgress;
        final contentSlideX = (1.0 - expandProgress) * 1.0;

        final scale = 1.0 + 0.06 * math.sin(t * 2 * math.pi);

        // Width animates from icon-only to full content.
        final iconWidth = 28.0;
        final contentWidth = 120.0;
        final width = iconWidth + (contentWidth - iconWidth) * expandProgress;

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRect(
            child: SizedBox(
              height: 36,
              width: width,
              child: Stack(
                alignment: Alignment.centerRight,
                clipBehavior: Clip.hardEdge,
                children: [
                  // Add icon (compact state) — anchored right, slides right as it exits.
                  Opacity(
                    opacity: addOpacity,
                    child: Transform.translate(
                      offset: Offset(addSlideX * 30, 0),
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.add_rounded,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Expanded content: arrow + Create Bill text — slides in from right.
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
                              'Create Bill',
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
}

// ═════════════════════════════════════════════════════════════════════════════
// Top bar avatar stack — max 3 circular member photos + overflow
// ═════════════════════════════════════════════════════════════════════════════

class _TopBarAvatarStack extends StatelessWidget {
  const _TopBarAvatarStack({
    required this.members,
    required this.colorScheme,
    required this.isDark,
  });

  final List<GroupMember> members;
  final ColorScheme colorScheme;
  final bool isDark;

  static const _avatarSize = 30.0;
  static const _overlap = 8.0;
  static const _maxVisible = 3;

  static const _avatarColors = [
    AppColors.chartTeal,
    AppColors.chartBlue,
    AppColors.chartPurple,
    AppColors.chartOrange,
    AppColors.chartPink,
    AppColors.chartCyan,
  ];

  @override
  Widget build(BuildContext context) {
    final visible = members.take(_maxVisible).toList();
    final overflow = members.length - visible.length;
    final ringColor = isDark ? AppColors.darkBackground : AppColors.white;
    final stackWidth = (visible.length * _avatarSize) -
        ((visible.length - 1) * _overlap) +
        (overflow > 0 ? _avatarSize - _overlap : 0);

    return SizedBox(
      height: _avatarSize,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (_avatarSize - _overlap),
              child: _TopBarAvatar(
                member: visible[i],
                color: _avatarColors[i % _avatarColors.length],
                ringColor: ringColor,
                size: _avatarSize,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (_avatarSize - _overlap),
              child: _TopBarOverflowChip(
                count: overflow,
                ringColor: ringColor,
                colorScheme: colorScheme,
                size: _avatarSize,
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBarAvatar extends StatelessWidget {
  const _TopBarAvatar({
    required this.member,
    required this.color,
    required this.ringColor,
    required this.size,
  });

  final GroupMember member;
  final Color color;
  final Color ringColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final picture = member.profilePicture;
    final name = (member.displayName?.isNotEmpty ?? false)
        ? member.displayName!
        : (member.fullName.isNotEmpty ? member.fullName : member.email);
    final initial =
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Tooltip(
      message: name,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: ringColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: picture != null && picture.isNotEmpty
            ? Image.network(
                picture,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initial,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      fontSize: 11,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initial,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    fontSize: 11,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TopBarOverflowChip extends StatelessWidget {
  const _TopBarOverflowChip({
    required this.count,
    required this.ringColor,
    required this.colorScheme,
    required this.size,
  });

  final int count;
  final Color ringColor;
  final ColorScheme colorScheme;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '+$count more',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: ringColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '+$count',
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              height: 1.0,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Stats row — Total Bills, Total Amount, Your Share
// ═════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.bills,
    required this.currentUserId,
    required this.entranceController,
    required this.colorScheme,
    required this.isDark,
  });

  final List<Bill> bills;
  final String currentUserId;
  final AnimationController entranceController;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalBills = bills.length;
    final totalAmount = bills.fold<double>(0, (sum, b) => sum + b.totalAmount);
    final yourShare = bills.fold<double>(
      0,
      (sum, b) => sum + b.shareFor(currentUserId),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: StaggeredEntrance(
        animation: entranceController,
        interval: const Interval(0.15, 0.50, curve: Curves.easeOutCubic),
        slideOffset: 24,
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long_rounded,
                label: 'Total Bills',
                value: '$totalBills',
                color: AppColors.chartBlue,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Total Amount',
                value: AppConstants.formatCurrency(
                  totalAmount,
                  withSymbol: true,
                ),
                color: AppColors.chartGreen,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.person_rounded,
                label: 'Your Share',
                value: AppConstants.formatCurrency(
                  yourShare,
                  withSymbol: true,
                ),
                color: AppColors.chartOrange,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.colorScheme,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: isDark ? AppShadows.xsDark : AppShadows.xsLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Count pill
// ═════════════════════════════════════════════════════════════════════════════

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.colorScheme});

  final int count;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: AppRadius.radiusFull,
      ),
      child: Text(
        '$count',
        style: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Bill card — surface card with colored accent strip
// ═════════════════════════════════════════════════════════════════════════════

class _BillCard extends StatefulWidget {
  const _BillCard({
    required this.bill,
    required this.color,
    required this.isDark,
    required this.currentUserId,
    required this.onTap,
  });

  final Bill bill;
  final Color color;
  final bool isDark;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  State<_BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<_BillCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bill = widget.bill;
    final date = bill.date ?? bill.createdAt;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - 0.02 * _pressController.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadius.radiusXl,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: widget.isDark
                ? AppShadows.xsDark
                : AppShadows.xsLight,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusXl,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Colored icon circle ───────────────────────────────────
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 22,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // ── Main content ──────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + payment status badge.
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bill.title,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _PaymentStatusBadge(
                              status: bill.paymentStatus,
                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Split mode + member count.
                        Row(
                          children: [
                            Icon(
                              bill.splitMode == BillSplitMode.equal
                                  ? Icons.people_alt_rounded
                                  : Icons.tune_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bill.splitMode == BillSplitMode.equal
                                  ? 'Equal Split'
                                  : 'Custom Split',
                              style: AppTextStyles.caption.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${bill.includedCount} member${bill.includedCount == 1 ? '' : 's'}',
                              style: AppTextStyles.caption.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Total + Date row.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  AppConstants.formatCurrency(
                                    bill.totalAmount,
                                    withSymbol: true,
                                  ),
                                  style: AppTextStyles.amountMedium.copyWith(
                                    color: widget.color,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Date',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _formatDate(date),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Payment status badge (surface card version)
// ═════════════════════════════════════════════════════════════════════════════

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({
    required this.status,
    required this.colorScheme,
  });

  final BillPaymentStatus status;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      BillPaymentStatus.paid => (
        'Paid',
        AppColors.success.withValues(alpha: 0.12),
        AppColors.success,
      ),
      BillPaymentStatus.partiallyPaid => (
        'Partial',
        AppColors.warning.withValues(alpha: 0.12),
        AppColors.warning,
      ),
      BillPaymentStatus.unpaid => (
        'Unpaid',
        AppColors.error.withValues(alpha: 0.12),
        AppColors.error,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.radiusFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.2,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Full-screen skeleton for group details loading state
// ═════════════════════════════════════════════════════════════════════════════

class _GroupDetailsSkeleton extends StatefulWidget {
  const _GroupDetailsSkeleton({required this.colorScheme, required this.isDark});

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  State<_GroupDetailsSkeleton> createState() => _GroupDetailsSkeletonState();
}

class _GroupDetailsSkeletonState extends State<_GroupDetailsSkeleton>
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
    final base = widget.colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.5);
    final highlight = widget.colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.9);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final t = _shimmerController.value;
        return Stack(
          children: [
            SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar skeleton.
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        _SkeletonCircle(size: 40, color: base),
                        const SizedBox(width: AppSpacing.md),
                        _SkeletonBox(
                            width: 120, height: 16, color: base),
                        const Spacer(),
                        _SkeletonCircle(size: 40, color: base),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Stats row skeleton.
                  Row(
                    children: [
                      Expanded(child: _StatCardSkeleton(color: base)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _StatCardSkeleton(color: base)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _StatCardSkeleton(color: base)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Bills header skeleton.
                  Row(
                    children: [
                      _SkeletonBox(width: 60, height: 18, color: base),
                      const SizedBox(width: AppSpacing.sm),
                      _SkeletonBox(width: 24, height: 18, color: base),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Bill card skeletons.
                  for (var i = 0; i < 4; i++) ...[
                    _BillCardSkeletonBox(color: base),
                    if (i < 3) const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            // Shimmer overlay.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * t, 0),
                      end: Alignment(-1 + 2 * t + 0.5, 0),
                      colors: [
                        Colors.transparent,
                        highlight.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(size: 28, radius: AppRadius.radiusSm, color: color),
          const SizedBox(height: AppSpacing.sm),
          _SkeletonBox(width: 50, height: 10, color: color),
          const SizedBox(height: 4),
          _SkeletonBox(width: 70, height: 14, color: color),
        ],
      ),
    );
  }
}

class _BillCardSkeletonBox extends StatelessWidget {
  const _BillCardSkeletonBox({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.radiusXl,
      ),
      child: Row(
        children: [
          _SkeletonBox(size: 44, radius: AppRadius.radiusMd, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SkeletonBox(
                          width: double.infinity, height: 16, color: color),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _SkeletonBox(width: 50, height: 14, color: color),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _SkeletonBox(width: 100, height: 11, color: color),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SkeletonBox(width: 80, height: 18, color: color),
                    _SkeletonBox(width: 70, height: 14, color: color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    required this.color,
    this.size,
    this.radius,
  });

  final double? width;
  final double? height;
  final double? size;
  final Color color;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? size,
      height: height ?? size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius ?? BorderRadius.circular(6),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Empty state — no bills yet
// ═════════════════════════════════════════════════════════════════════════════

class _BillsEmptyState extends StatelessWidget {
  const _BillsEmptyState({
    required this.entranceController,
    required this.ambientController,
    required this.colorScheme,
    required this.isDark,
    required this.onCreateBill,
  });

  final AnimationController entranceController;
  final AnimationController ambientController;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onCreateBill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating icon cluster.
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
            slideOffset: 30,
            child: _FloatingBillIcon(
              ambientController: ambientController,
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.28, 0.62, curve: Curves.easeOutCubic),
            slideOffset: 20,
            child: Text(
              'No bills yet',
              style: AppTextStyles.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.35, 0.68, curve: Curves.easeOutCubic),
            slideOffset: 20,
            child: Text(
              'This group doesn\'t have any bills.\nCreate the first one to start splitting.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.45, 0.75, curve: Curves.easeOutBack),
            slideOffset: 20,
            child: FilledButton.icon(
              onPressed: onCreateBill,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Bill'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBillIcon extends StatelessWidget {
  const _FloatingBillIcon({
    required this.ambientController,
    required this.colorScheme,
  });

  final AnimationController ambientController;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: ambientController,
        builder: (context, _) {
          final t = ambientController.value;
          final floatY = math.sin(t * 2 * math.pi) * 8;
          final rotate = math.sin(t * 2 * math.pi) * 0.05;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow disc.
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.18),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // Floating receipt icon.
              Transform.translate(
                offset: Offset(0, floatY),
                child: Transform.rotate(
                  angle: rotate,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: AppRadius.radiusLg,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: colorScheme.onPrimary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Error state
// ═════════════════════════════════════════════════════════════════════════════

class _BillsErrorState extends StatelessWidget {
  const _BillsErrorState({
    required this.colorScheme,
    required this.onRetry,
  });

  final ColorScheme colorScheme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Could not load bills',
            style: AppTextStyles.titleMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.radiusFull,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Promo card — celebration image with CTA
// ═════════════════════════════════════════════════════════════════════════════

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.entranceController,
    required this.colorScheme,
    required this.isDark,
    required this.onCreateBill,
  });

  final AnimationController entranceController;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onCreateBill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: StaggeredEntrance(
        animation: entranceController,
        interval: const Interval(0.40, 0.75, curve: Curves.easeOutCubic),
        slideOffset: 28,
        child: GestureDetector(
          onTap: onCreateBill,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusXl,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isDark
                    ? AppColors.darkPrimaryGradient.colors
                    : AppColors.lightPrimaryGradient.colors,
              ),
              boxShadow: isDark
                  ? AppShadows.primaryGlowDark
                  : AppShadows.primaryGlowLight,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.radiusXl,
              child: Stack(
                children: [
                  // Celebration image on the right.
                  Positioned(
                    right: -10,
                    top: -10,
                    bottom: -10,
                    width: 120,
                    child: Image.asset(
                      'assets/images/group_celebration.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                  // Content.
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Split a New Bill',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Create and share expenses\nwith your group members.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onPrimary
                                .withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // CTA pill.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppRadius.radiusFull,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Create Bill',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: colorScheme.onPrimary,
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
  }
}
