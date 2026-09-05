import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../expenses/presentation/state/bill_providers.dart';
import '../../domain/entities/group.dart';
import '../state/group_providers.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter / sort enums
// ─────────────────────────────────────────────────────────────────────────────

enum _GroupFilter { all, owesYou, youOwe }

enum _GroupSort { recent, name }

// ─────────────────────────────────────────────────────────────────────────────
// Pattern types for decorative card backgrounds
// ─────────────────────────────────────────────────────────────────────────────

enum _CardPattern { dots, peaks, route, squareGrid, dotMatrix, circles }

// ═════════════════════════════════════════════════════════════════════════════
// Groups screen
// ═════════════════════════════════════════════════════════════════════════════

/// Groups tab for the app shell.
///
/// Redesigned to match the "My Groups" reference design: flat app bar,
/// 3-stat summary strip, filter chips + sort dropdown, 2-column group-card
/// grid with animated decorative patterns, and a "Create a new group" promo
/// card at the bottom.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final AnimationController _patternController;

  _GroupFilter _activeFilter = _GroupFilter.all;
  _GroupSort _activeSort = _GroupSort.recent;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();
    _patternController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _patternController.dispose();
    super.dispose();
  }

  void _openCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateGroupScreen()),
    );
  }

  List<Group> _applyFilterAndSort(List<Group> groups) {
    // No financial data on the Group entity yet → filter on member count as
    // a stand-in so the chips are functional (owes / owed shown via balance).
    var filtered = groups;
    switch (_activeFilter) {
      case _GroupFilter.all:
        filtered = groups;
      case _GroupFilter.owesYou:
        // Show groups with more than 1 member (placeholder logic)
        filtered = groups.where((g) => g.memberCount > 1).toList();
      case _GroupFilter.youOwe:
        filtered = groups.where((g) => g.memberCount == 1).toList();
    }

    final sorted = [...filtered];
    switch (_activeSort) {
      case _GroupSort.recent:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _GroupSort.name:
        sorted.sort((a, b) =>
            a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase()));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final groupsAsync = ref.watch(groupsForCurrentUserProvider);

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('groups_screen'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
              slideOffset: 20,
              child: _AppBar(
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ),
          ),

          // ── Stats row ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.1, 0.45, curve: Curves.easeOutCubic),
              slideOffset: 24,
              child: groupsAsync.when(
                data: (groups) {
                  final balanceAsync = ref.watch(userBalanceProvider);
                  return balanceAsync.when(
                    data: (balance) => _StatsRow(
                      groupCount: groups.length,
                      balance: balance,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    loading: () => _StatsRowSkeleton(
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    error: (_, __) => _StatsRow(
                      groupCount: groups.length,
                      balance: const UserBalance.zero(),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  );
                },
                loading: () => _StatsRowSkeleton(
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
              slideOffset: 20,
              child: _FilterBar(
                activeFilter: _activeFilter,
                activeSort: _activeSort,
                colorScheme: colorScheme,
                onFilterChanged: (f) => setState(() => _activeFilter = f),
                onSortChanged: (s) => setState(() => _activeSort = s),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          groupsAsync.when(
            data: (groups) {
              final filtered = _applyFilterAndSort(groups);
              if (groups.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    entranceController: _entranceController,
                    ambientController: _ambientController,
                    colorScheme: colorScheme,
                    onCreateGroup: _openCreateGroup,
                  ),
                );
              }
              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoResultsState(colorScheme: colorScheme),
                );
              }
              return _buildGrid(filtered, colorScheme, isDark);
            },
            loading: () => _buildLoadingGrid(colorScheme),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorState(
                entranceController: _entranceController,
                colorScheme: colorScheme,
                onRetry: () => ref.invalidate(groupsForCurrentUserProvider),
              ),
            ),
          ),

          // ── Create group promo card ───────────────────────────────────────
          SliverToBoxAdapter(
            child: groupsAsync.maybeWhen(
              data: (_) => StaggeredEntrance(
                animation: _entranceController,
                interval:
                    const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
                slideOffset: 20,
                child: _PromoCard(
                  colorScheme: colorScheme,
                  isDark: isDark,
                  onCreateGroup: _openCreateGroup,
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<Group> groups,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final group = groups[index];
            final color = _groupColor(index);
            final pattern = _CardPattern.values[index % _CardPattern.values.length];
            return StaggeredEntrance(
              animation: _entranceController,
              interval: Interval(
                0.28 + (index * 0.04).clamp(0.0, 0.4),
                0.60 + (index * 0.04).clamp(0.0, 0.4),
                curve: Curves.easeOutCubic,
              ),
              slideOffset: 28,
              child: _GroupCard(
                group: group,
                color: color,
                pattern: pattern,
                isDark: isDark,
                patternController: _patternController,
                onTap: () {
                  final uid = ref.read(currentUidProvider) ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GroupDetailsScreen(
                        group: group,
                        currentUserId: uid,
                      ),
                    ),
                  );
                },
              ),
            );
          },
          childCount: groups.length,
        ),
      ),
    );
  }

  Widget _buildLoadingGrid(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _GroupCardSkeleton(colorScheme: colorScheme),
          childCount: 6,
        ),
      ),
    );
  }

  Color _groupColor(int index) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.chartColorsDark
        : AppColors.chartColorsLight;
    return palette[index % palette.length];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// App bar — flat, white background with title + subtitle + icons
// ═════════════════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget {
  const _AppBar({required this.colorScheme, required this.isDark});

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.lg,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: AppRadius.radiusMd,
              boxShadow: isDark
                  ? AppShadows.primaryGlowDark
                  : AppShadows.primaryGlowLight,
            ),
            child: Icon(
              Icons.groups_2_rounded,
              color: colorScheme.onPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'My Groups',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Manage, track & settle group expenses',
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Search icon
          _IconButton(
            icon: Icons.search_rounded,
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          // Bell icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconButton(
                icon: Icons.notifications_outlined,
                colorScheme: colorScheme,
                isDark: isDark,
                onTap: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.colorScheme,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: AppRadius.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            color: colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Stats row — Total Groups | You Owe | You're Owed
// ═════════════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.groupCount,
    required this.balance,
    required this.colorScheme,
    required this.isDark,
  });

  final int groupCount;
  final UserBalance balance;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.radiusXl,
          boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: Icons.groups_2_rounded,
                iconBg: colorScheme.primaryContainer,
                iconColor: colorScheme.primary,
                label: 'Total Groups',
                value: groupCount.toString(),
                subLabel: 'Groups',
                valueColor: colorScheme.onSurface,
                colorScheme: colorScheme,
              ),
            ),
            _VertDivider(colorScheme: colorScheme),
            Expanded(
              child: _StatCell(
                icon: Icons.account_balance_wallet_rounded,
                iconBg: AppColors.chartOrange.withValues(alpha: 0.12),
                iconColor: AppColors.chartOrange,
                label: 'You Owe',
                value: AppConstants.formatCurrency(
                  balance.youOwe,
                  withSymbol: true,
                ),
                subLabel:
                    'Across ${balance.youOweGroupCount} group${balance.youOweGroupCount == 1 ? '' : 's'}',
                valueColor: AppColors.chartOrange,
                colorScheme: colorScheme,
              ),
            ),
            _VertDivider(colorScheme: colorScheme),
            Expanded(
              child: _StatCell(
                icon: Icons.trending_up_rounded,
                iconBg: colorScheme.primaryContainer,
                iconColor: colorScheme.primary,
                label: "You're Owed",
                value: AppConstants.formatCurrency(
                  balance.youAreOwed,
                  withSymbol: true,
                ),
                subLabel:
                    'Across ${balance.youAreOwedGroupCount} group${balance.youAreOwedGroupCount == 1 ? '' : 's'}',
                valueColor: colorScheme.primary,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.valueColor,
    required this.colorScheme,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subLabel;
  final Color valueColor;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: AppRadius.radiusSm,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subLabel,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatsRowSkeleton extends StatefulWidget {
  const _StatsRowSkeleton({required this.colorScheme, required this.isDark});

  final ColorScheme colorScheme;
  final bool isDark;

  @override
  State<_StatsRowSkeleton> createState() => _StatsRowSkeletonState();
}

class _StatsRowSkeletonState extends State<_StatsRowSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
            color: base,
            borderRadius: AppRadius.radiusXl,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Filter bar — chips + sort dropdown
// ═════════════════════════════════════════════════════════════════════════════

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.activeFilter,
    required this.activeSort,
    required this.colorScheme,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final _GroupFilter activeFilter;
  final _GroupSort activeSort;
  final ColorScheme colorScheme;
  final ValueChanged<_GroupFilter> onFilterChanged;
  final ValueChanged<_GroupSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          // Scrollable filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Groups',
                    icon: Icons.grid_view_rounded,
                    isActive: activeFilter == _GroupFilter.all,
                    colorScheme: colorScheme,
                    onTap: () => onFilterChanged(_GroupFilter.all),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Owes You',
                    icon: Icons.arrow_downward_rounded,
                    isActive: activeFilter == _GroupFilter.owesYou,
                    colorScheme: colorScheme,
                    onTap: () => onFilterChanged(_GroupFilter.owesYou),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'You Owe',
                    icon: Icons.arrow_upward_rounded,
                    isActive: activeFilter == _GroupFilter.youOwe,
                    colorScheme: colorScheme,
                    onTap: () => onFilterChanged(_GroupFilter.youOwe),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Sort dropdown (fixed on right)
          _SortDropdown(
            activeSort: activeSort,
            colorScheme: colorScheme,
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.radiusFull,
        border: isActive
            ? null
            : Border.all(
                color: colorScheme.outlineVariant,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm - 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.activeSort,
    required this.colorScheme,
    required this.onChanged,
  });

  final _GroupSort activeSort;
  final ColorScheme colorScheme;
  final ValueChanged<_GroupSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showMenu<_GroupSort>(
          context: context,
          position: RelativeRect.fromLTRB(
            MediaQuery.sizeOf(context).width,
            80,
            AppSpacing.screenHorizontal,
            0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusMd,
          ),
          items: const [
            PopupMenuItem(value: _GroupSort.recent, child: Text('Recent')),
            PopupMenuItem(value: _GroupSort.name, child: Text('Name')),
          ],
        );
        if (result != null) onChanged(result);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm - 2,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: AppRadius.radiusFull,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeSort == _GroupSort.recent ? 'Recent' : 'Name',
              style: AppTextStyles.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Group card — 2-column grid card with animated decorative pattern
// ═════════════════════════════════════════════════════════════════════════════

class _GroupCard extends StatefulWidget {
  const _GroupCard({
    required this.group,
    required this.color,
    required this.pattern,
    required this.isDark,
    required this.patternController,
    required this.onTap,
  });

  final Group group;
  final Color color;
  final _CardPattern pattern;
  final bool isDark;
  final AnimationController patternController;
  final VoidCallback onTap;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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
    final group = widget.group;

    // Dummy balance data until financial layer is wired.
    // Odd-indexed groups show "You owe", even show "You're owed".
    final dummyIndex = group.groupName.codeUnits.fold(0, (a, b) => a + b);
    final isOwed = dummyIndex % 2 == 0;
    final balanceColor =
        isOwed ? colorScheme.primary : AppColors.chartOrange;
    final balanceLabel = isOwed ? "You're owed" : 'You owe';

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) => Transform.scale(
          scale: 1.0 - 0.025 * _pressController.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadius.radiusXl,
            boxShadow: widget.isDark ? AppShadows.smDark : AppShadows.smLight,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusXl,
            child: Stack(
              children: [
                // ── Tinted background wash on right side ────────────────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          widget.color.withValues(alpha: 0.0),
                          widget.color.withValues(alpha: 0.06),
                          widget.color.withValues(alpha: 0.10),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // ── Animated decorative pattern (right side) ───────────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 72,
                  child: AnimatedBuilder(
                    animation: widget.patternController,
                    builder: (context, _) => CustomPaint(
                      painter: _CardPatternPainter(
                        pattern: widget.pattern,
                        color: widget.color,
                        progress: widget.patternController.value,
                      ),
                    ),
                  ),
                ),
                // ── Card content ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group name
                      Text(
                        group.groupName,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Description placeholder
                      Text(
                        _groupSubtitle(group),
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Member count badge
                      _MemberBadge(
                        count: group.memberCount,
                        color: colorScheme.primary,
                        onPrimary: colorScheme.onPrimary,
                      ),
                      const Spacer(),
                      // Balance label
                      Text(
                        balanceLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: balanceColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Balance value + arrow
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Rs. 0.00',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: balanceColor,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
    );
  }

  String _groupSubtitle(Group group) {
    // Generate a friendly tagline from group name.
    final name = group.groupName.toLowerCase();
    if (name.contains('room') || name.contains('home') || name.contains('flat')) {
      return 'Home sweet home 🏠';
    } else if (name.contains('office') || name.contains('work') || name.contains('lunch')) {
      return 'Eat together, stay together 🍽';
    } else if (name.contains('trip') || name.contains('travel') || name.contains('vacation')) {
      return 'Memories & adventures 🏕';
    } else if (name.contains('family')) {
      return 'Making memories together ✈';
    } else if (name.contains('friend') || name.contains('college') || name.contains('school')) {
      return 'Good times & great people 🎉';
    } else if (name.contains('sport') || name.contains('team') || name.contains('football')) {
      return 'Play hard, win together ⚽';
    }
    return 'Split bills effortlessly 💸';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member count badge
// ─────────────────────────────────────────────────────────────────────────────

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({
    required this.count,
    required this.color,
    required this.onPrimary,
  });

  final int count;
  final Color color;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusFull,
      ),
      child: Text(
        '$count member${count == 1 ? '' : 's'}',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative pattern painter for group cards
// ─────────────────────────────────────────────────────────────────────────────

class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter({
    required this.pattern,
    required this.color,
    required this.progress,
  });

  final _CardPattern pattern;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    switch (pattern) {
      case _CardPattern.dots:
        _paintDots(canvas, size, paint);
      case _CardPattern.peaks:
        _paintPeaks(canvas, size, paint);
      case _CardPattern.route:
        _paintRoute(canvas, size, paint);
      case _CardPattern.squareGrid:
        _paintSquareGrid(canvas, size, paint);
      case _CardPattern.dotMatrix:
        _paintDotMatrix(canvas, size, paint);
      case _CardPattern.circles:
        _paintCircles(canvas, size, paint);
    }
  }

  void _paintDots(Canvas canvas, Size size, Paint paint) {
    // Animated floating bubbles — continuous upward drift, invisible on wrap
    final bubblePaint = Paint()
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // (x%, radius, speed, startOffset, swayPhase)
    // startOffset spreads bubbles across the cycle so they don't wrap together
    final bubbles = [
      (0.15, 7.0, 0.18, 0.00, 0.0),
      (0.45, 5.0, 0.22, 0.30, 1.2),
      (0.75, 8.0, 0.15, 0.55, 2.4),
      (0.30, 4.0, 0.25, 0.15, 0.8),
      (0.60, 6.0, 0.20, 0.70, 1.8),
      (0.85, 3.5, 0.24, 0.45, 3.0),
      (0.20, 5.5, 0.17, 0.85, 2.0),
      (0.50, 4.5, 0.26, 0.60, 0.5),
      (0.80, 6.5, 0.19, 0.10, 1.5),
    ];

    final t = progress * 2 * math.pi;

    for (final b in bubbles) {
      final bx = b.$1;
      final br = b.$2;
      final speed = b.$3;
      final startOffset = b.$4;
      final swayPhase = b.$5;

      // Continuous upward drift: y goes from 1.2 (below visible area)
      // to -0.2 (above visible area), then wraps. Total range = 1.4.
      final cycle = (progress * speed + startOffset) % 1.4;
      final yNorm = 1.2 - cycle; // starts at 1.2, moves up to -0.2

      // Gentle horizontal sway
      final xNorm = bx + 0.06 * math.sin(t * 0.4 + swayPhase);

      // Eased breathing scale
      final breathe = 0.88 + 0.12 * (0.5 + 0.5 * math.sin(t * 0.6 + swayPhase * 1.5));
      final r = br * breathe;

      final px = xNorm * size.width;
      final py = yNorm * size.height;

      // Smoothstep fade: fully invisible below y=0.0 and above y=1.0,
      // fades in over 0.0→0.12, fades out over 0.88→1.0.
      // This guarantees the wrap from -0.2→1.2 happens while invisible.
      final edgeFade = _bubbleFade(yNorm);

      // Soft fill
      final fillAlpha = 0.12 * edgeFade;
      bubblePaint.color = color.withValues(alpha: fillAlpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), r, bubblePaint);

      // Crisp ring
      final ringAlpha = 0.30 * edgeFade;
      ringPaint.color = color.withValues(alpha: ringAlpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), r, ringPaint);

      // Glossy highlight dot
      final highlightAlpha = 0.40 * edgeFade;
      canvas.drawCircle(
        Offset(px - r * 0.3, py - r * 0.3),
        r * 0.25,
        Paint()
          ..color = color.withValues(alpha: highlightAlpha.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );
    }
  }

  /// Smoothstep: 0 for y ≤ 0 or y ≥ 1, fades in over [0, 0.12],
  /// full opacity over [0.12, 0.88], fades out over [0.88, 1.0].
  double _bubbleFade(double y) {
    if (y <= 0.0 || y >= 1.0) return 0.0;
    if (y >= 0.12 && y <= 0.88) return 1.0;
    double t;
    if (y < 0.12) {
      t = y / 0.12;
    } else {
      t = (1.0 - y) / 0.12;
    }
    return t * t * (3 - 2 * t);
  }

  void _paintPeaks(Canvas canvas, Size size, Paint paint) {
    // Animated layered mountain peaks silhouette
    final peakPaint = Paint()
      ..style = PaintingStyle.fill;

    // Back layer — lighter, wider peaks
    final backPath = Path();
    backPath.moveTo(0, size.height);
    const backPeaks = 3;
    final backW = size.width / backPeaks;
    for (var i = 0; i < backPeaks; i++) {
      final xStart = i * backW;
      final xMid = xStart + backW / 2;
      final xEnd = xStart + backW;
      // Animated peak height with gentle breathing
      final baseH = size.height * 0.55;
      final animH = baseH +
          (size.height * 0.08) *
              math.sin(progress * 2 * math.pi + i * 0.7);
      backPath.lineTo(xStart, size.height * 0.7);
      backPath.lineTo(xMid, size.height - animH);
      backPath.lineTo(xEnd, size.height * 0.7);
    }
    backPath.lineTo(size.width, size.height);
    backPath.close();
    peakPaint.color = color.withValues(alpha: 0.12);
    canvas.drawPath(backPath, peakPaint);

    // Front layer — darker, sharper peaks
    final frontPath = Path();
    frontPath.moveTo(0, size.height);
    const frontPeaks = 4;
    final frontW = size.width / frontPeaks;
    for (var i = 0; i < frontPeaks; i++) {
      final xStart = i * frontW;
      final xMid = xStart + frontW / 2;
      final xEnd = xStart + frontW;
      final baseH = size.height * 0.38;
      final animH = baseH +
          (size.height * 0.06) *
              math.sin(progress * 2 * math.pi + i * 1.1 + 1.0);
      frontPath.lineTo(xStart, size.height * 0.5);
      frontPath.lineTo(xMid, size.height - animH);
      frontPath.lineTo(xEnd, size.height * 0.5);
    }
    frontPath.lineTo(size.width, size.height);
    frontPath.close();
    peakPaint.color = color.withValues(alpha: 0.22);
    canvas.drawPath(frontPath, peakPaint);

    // Snow cap dots on the front peaks
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < frontPeaks; i++) {
      final xMid = i * frontW + frontW / 2;
      final baseH = size.height * 0.38;
      final animH = baseH +
          (size.height * 0.06) *
              math.sin(progress * 2 * math.pi + i * 1.1 + 1.0);
      final peakY = size.height - animH;
      final dotAlpha = 0.35 + 0.20 * math.sin(progress * 2 * math.pi + i).abs();
      dotPaint.color = color.withValues(alpha: dotAlpha);
      canvas.drawCircle(Offset(xMid, peakY + 3), 2.0, dotPaint);
    }
  }

  void _paintRoute(Canvas canvas, Size size, Paint paint) {
    // Animated winding travel route with waypoint dots
    final routePaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    // Define a winding path that curves through the pattern area.
    final path = Path();
    const segments = 4;
    final segW = size.width / segments;

    // Animated dash offset for a "drawing" effect.
    final dashShift = progress * size.width;

    for (var s = 0; s <= segments; s++) {
      final x = s * segW;
      final yBase = size.height * 0.5;
      final y = yBase +
          (size.height * 0.28) *
              math.sin((s / segments) * 2 * math.pi +
                  progress * 2 * math.pi);

      if (s == 0) {
        path.moveTo(x, y);
      } else {
        // Use cubic curves for smooth winding.
        final prevX = (s - 1) * segW;
        final prevY = yBase +
            (size.height * 0.28) *
                math.sin(((s - 1) / segments) * 2 * math.pi +
                    progress * 2 * math.pi);
        final midX = (prevX + x) / 2;
        final cp1y = prevY + (y - prevY) * 0.5 + size.height * 0.12;
        final cp2y = prevY + (y - prevY) * 0.5 - size.height * 0.12;
        path.cubicTo(midX, cp1y, midX, cp2y, x, y);
      }

      // Draw waypoint dots at each segment point.
      final pulseAlpha = 0.30 + 0.25 * math.sin(progress * 2 * math.pi + s * 0.8).abs();
      dotPaint.color = color.withValues(alpha: pulseAlpha);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);

      // Outer ring on alternating waypoints for a "location pin" feel.
      if (s % 2 == 0) {
        final ringAlpha = 0.15 + 0.15 * math.sin(progress * 2 * math.pi + s).abs();
        canvas.drawCircle(
          Offset(x, y),
          7.0,
          Paint()
            ..color = color.withValues(alpha: ringAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Draw the path with a dashed effect for a "travel trail" look.
    _drawDashedPath(canvas, path, routePaint, dashWidth: 6, gapWidth: 4, offset: dashShift);
  }

  /// Draws a [path] on [canvas] with a dashed stroke pattern.
  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashWidth,
    required double gapWidth,
    required double offset,
  }) {
    final dashLen = dashWidth + gapWidth;
    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      final totalLen = metric.length;
      var start = offset % dashLen - dashLen;
      while (start < totalLen) {
        final end = (start + dashWidth).clamp(0.0, totalLen);
        if (start < totalLen && end > 0) {
          final extracted = metric.extractPath(start.clamp(0.0, totalLen), end);
          canvas.drawPath(extracted, paint);
        }
        start += dashLen;
      }
    }
  }

  void _paintSquareGrid(Canvas canvas, Size size, Paint paint) {
    // Animated pulsing square grid
    const cols = 3;
    const rows = 4;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final squarePaint = Paint()
      ..style = PaintingStyle.fill;

    for (var c = 0; c < cols; c++) {
      for (var r = 0; r < rows; r++) {
        final phase = (progress * 2 * math.pi) + (c + r) * 0.5;
        final alpha = 0.20 + 0.25 * math.sin(phase).abs();
        squarePaint.color = color.withValues(alpha: alpha);
        final cx = c * cellW + cellW / 2;
        final cy = r * cellH + cellH / 2;
        final side = cellW * 0.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: side,
              height: side,
            ),
            const Radius.circular(3),
          ),
          squarePaint,
        );
      }
    }
  }

  void _paintDotMatrix(Canvas canvas, Size size, Paint paint) {
    // Animated cascading dot matrix
    final dotPaint = Paint()..style = PaintingStyle.fill;
    const cols = 4;
    const rows = 5;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (var c = 0; c < cols; c++) {
      for (var r = 0; r < rows; r++) {
        final phase = (progress * 2 * math.pi) - (c + r) * 0.4;
        final alpha = 0.25 + 0.25 * math.sin(phase).abs();
        dotPaint.color = color.withValues(alpha: alpha);
        final cx = c * cellW + cellW / 2;
        final cy = r * cellH + cellH / 2;
        canvas.drawCircle(Offset(cx, cy), 3.5, dotPaint);
      }
    }
  }

  void _paintCircles(Canvas canvas, Size size, Paint paint) {
    // Animated expanding concentric circles
    final cx = size.width * 0.65;
    final cy = size.height * 0.4;
    const maxR = 50.0;
    const circleCount = 4;
    for (var i = 0; i < circleCount; i++) {
      final phase = (progress + i / circleCount) % 1.0;
      final r = maxR * phase;
      final alpha = (1 - phase) * 0.50;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter old) =>
      old.progress != progress || old.color != color || old.pattern != pattern;
}

// ═════════════════════════════════════════════════════════════════════════════
// Loading skeleton — grid cards
// ═════════════════════════════════════════════════════════════════════════════

class _GroupCardSkeleton extends StatefulWidget {
  const _GroupCardSkeleton({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  State<_GroupCardSkeleton> createState() => _GroupCardSkeletonState();
}

class _GroupCardSkeletonState extends State<_GroupCardSkeleton>
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
    final base =
        widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final highlight =
        widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final t = _shimmerController.value;
        return Container(
          decoration: BoxDecoration(
            color: widget.colorScheme.surface,
            borderRadius: AppRadius.radiusXl,
            border: Border.all(
              color: widget.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 100, height: 14, color: base),
                    const SizedBox(height: AppSpacing.xs),
                    _SkeletonBox(width: 70, height: 10, color: base),
                    const SizedBox(height: AppSpacing.sm),
                    _SkeletonBox(width: 60, height: 18, color: base),
                    const Spacer(),
                    _SkeletonBox(width: 50, height: 10, color: base),
                    const SizedBox(height: AppSpacing.xs),
                    _SkeletonBox(width: 80, height: 14, color: base),
                  ],
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.radiusXl,
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.width,
    this.height,
    required this.color,
  });

  final double? width;
  final double? height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Promo card — "Create a new group" with asset image
// ═════════════════════════════════════════════════════════════════════════════

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.colorScheme,
    required this.isDark,
    required this.onCreateGroup,
  });

  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.radiusXl,
          boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Illustration
              ClipRRect(
                borderRadius: AppRadius.radiusMd,
                child: Image.asset(
                  'assets/images/group_celebration.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: Icon(
                      Icons.celebration_rounded,
                      color: colorScheme.primary,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Create a new group',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add friends and start splitting\nexpenses easily.',
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // CTA button
              FilledButton.icon(
                onPressed: onCreateGroup,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Create\nGroup'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusLg,
                  ),
                  textStyle: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Empty state — animated floating illustration
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.entranceController,
    required this.ambientController,
    required this.colorScheme,
    required this.onCreateGroup,
  });

  final AnimationController entranceController;
  final AnimationController ambientController;
  final ColorScheme colorScheme;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.1, 0.5, curve: Curves.easeOutBack),
            slideOffset: 30,
            child: _FloatingIconCluster(
              ambientController: ambientController,
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
            slideOffset: 20,
            child: Text(
              'No groups yet',
              style: AppTextStyles.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.32, 0.65, curve: Curves.easeOutCubic),
            slideOffset: 20,
            child: Text(
              'Create your first group to start splitting\nbills with friends and flatmates.',
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
            interval: const Interval(0.42, 0.72, curve: Curves.easeOutBack),
            slideOffset: 20,
            child: FilledButton.icon(
              onPressed: onCreateGroup,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Group'),
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

class _FloatingIconCluster extends StatelessWidget {
  const _FloatingIconCluster({
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
          final floatA = math.sin(t * 2 * math.pi) * 8;
          final floatB = math.sin(t * 2 * math.pi + 1.2) * 6;
          final floatC = math.sin(t * 2 * math.pi + 2.4) * 7;
          final rotate = t * 2 * math.pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.group_rounded,
                  size: 44,
                  color: colorScheme.onPrimary,
                ),
              ),
              Transform.rotate(
                angle: rotate,
                child: Stack(
                  children: [
                    _Satellite(
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.chartOrange,
                      left: 4 + floatA,
                      top: 20,
                    ),
                    _Satellite(
                      icon: Icons.payments_rounded,
                      color: AppColors.chartBlue,
                      right: 4 + floatB,
                      top: 30,
                    ),
                    _Satellite(
                      icon: Icons.splitscreen_rounded,
                      color: AppColors.chartPurple,
                      left: 30 + floatC,
                      bottom: 4,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Satellite extends StatelessWidget {
  const _Satellite({
    required this.icon,
    required this.color,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  final IconData icon;
  final Color color;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// No-results state (filter returned empty)
// ═════════════════════════════════════════════════════════════════════════════

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.filter_list_off_rounded,
          size: 56,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'No groups match this filter',
          style: AppTextStyles.titleSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Try switching to "All Groups".',
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Error state
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.entranceController,
    required this.colorScheme,
    required this.onRetry,
  });

  final AnimationController entranceController;
  final ColorScheme colorScheme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.1, 0.5, curve: Curves.easeOutBack),
            slideOffset: 30,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
            slideOffset: 20,
            child: Text(
              "Couldn't load groups",
              style: AppTextStyles.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.32, 0.65, curve: Curves.easeOutCubic),
            slideOffset: 20,
            child: Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StaggeredEntrance(
            animation: entranceController,
            interval: const Interval(0.42, 0.72, curve: Curves.easeOutBack),
            slideOffset: 20,
            child: FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Retry'),
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

