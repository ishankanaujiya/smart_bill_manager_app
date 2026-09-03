import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../domain/entities/group.dart';
import '../state/group_providers.dart';
import 'create_group_screen.dart';

/// Groups tab for the app shell.
///
/// Lists the groups the currently signed-in user belongs to (either as the
/// creator or as a member) in real time. The screen features a gradient
/// hero header with aggregate stats, rich group cards with member avatar
/// stacks, shimmer loading skeletons, and animated empty / error states.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen>
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

  void _openCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateGroupScreen()),
    );
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
          // ── Hero header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroHeader(
              entranceController: _entranceController,
              ambientController: _ambientController,
              colorScheme: colorScheme,
              isDark: isDark,
              groupsAsync: groupsAsync,
              onCreateGroup: _openCreateGroup,
            ),
          ),
          // ── Body ────────────────────────────────────────────────────────
          groupsAsync.when(
            data: (groups) => _buildBody(groups, colorScheme, isDark),
            loading: () => _buildLoadingState(colorScheme, isDark),
            error: (error, _) => _buildErrorState(colorScheme),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body states
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    List<Group> groups,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (groups.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    // Sort by most recently updated first so active groups surface to top.
    final sorted = [...groups]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final group = sorted[index];
            return StaggeredEntrance(
              animation: _entranceController,
              interval: Interval(
                0.25 + (index * 0.06),
                0.65 + (index * 0.06),
                curve: Curves.easeOutCubic,
              ),
              slideOffset: 32,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _GroupCard(
                  group: group,
                  color: _groupColor(index),
                  isDark: isDark,
                  onTap: () {
                    // TODO(group-detail): navigate to the group detail screen.
                  },
                ),
              ),
            );
          },
          childCount: sorted.length,
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _GroupCardSkeleton(colorScheme: colorScheme),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
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

  Widget _buildErrorState(ColorScheme colorScheme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: _ErrorState(
        entranceController: _entranceController,
        colorScheme: colorScheme,
        onRetry: () => ref.invalidate(groupsForCurrentUserProvider),
      ),
    );
  }

  /// Picks a deterministic accent color per group so the list stays
  /// visually varied but stable across rebuilds.
  Color _groupColor(int index) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.chartColorsDark
        : AppColors.chartColorsLight;
    return palette[index % palette.length];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Hero header — gradient banner with aggregate stats + create CTA
// ═════════════════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.entranceController,
    required this.ambientController,
    required this.colorScheme,
    required this.isDark,
    required this.groupsAsync,
    required this.onCreateGroup,
  });

  final AnimationController entranceController;
  final AnimationController ambientController;
  final ColorScheme colorScheme;
  final bool isDark;
  final AsyncValue<List<Group>> groupsAsync;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.pageTop,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      child: StaggeredEntrance(
        animation: entranceController,
        interval: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
        slideOffset: 28,
        child: _GradientBanner(
          ambientController: ambientController,
          colorScheme: colorScheme,
          isDark: isDark,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title row ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.18),
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'My Groups',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: colorScheme.onPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    _CreateButton(
                      entranceController: entranceController,
                      colorScheme: colorScheme,
                      onPressed: onCreateGroup,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // ── Stats row ──────────────────────────────────────────────
                groupsAsync.when(
                  data: (groups) => _StatsRow(
                    entranceController: entranceController,
                    colorScheme: colorScheme,
                    totalGroups: groups.length,
                    totalMembers: _uniqueMemberCount(groups),
                  ),
                  loading: () => _StatsRow(
                    entranceController: entranceController,
                    colorScheme: colorScheme,
                    totalGroups: null,
                    totalMembers: null,
                  ),
                  error: (_, __) => _StatsRow(
                    entranceController: entranceController,
                    colorScheme: colorScheme,
                    totalGroups: 0,
                    totalMembers: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Counts unique members across all groups (a user in 3 groups counts once).
  int _uniqueMemberCount(List<Group> groups) {
    final ids = <String>{};
    for (final g in groups) {
      ids.addAll(g.memberIds);
    }
    return ids.length;
  }
}

/// Animated gradient banner with a slow-moving ambient sheen.
class _GradientBanner extends StatelessWidget {
  const _GradientBanner({
    required this.ambientController,
    required this.colorScheme,
    required this.isDark,
    required this.child,
  });

  final AnimationController ambientController;
  final ColorScheme colorScheme;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? AppColors.darkPrimaryGradient
        : AppColors.lightPrimaryGradient;

    return AnimatedBuilder(
      animation: ambientController,
      builder: (context, _) {
        // Slow horizontal sweep of a soft light band across the gradient.
        final t = ambientController.value;
        final sweepX = -0.3 + 1.6 * t;

        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusXxl,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradient.colors,
            ),
            boxShadow: isDark
                ? AppShadows.primaryGlowDark
                : AppShadows.primaryGlowLight,
          ),
          child: Stack(
            children: [
              // Ambient sheen overlay.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.radiusXxl,
                    gradient: LinearGradient(
                      begin: Alignment(sweepX, -0.8),
                      end: Alignment(sweepX + 0.4, 0.8),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white
                            .withValues(alpha: isDark ? 0.06 : 0.10),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Subtle dotted texture in the corner.
              Positioned(
                right: -20,
                top: -20,
                child: Opacity(
                  opacity: 0.12,
                  child: CustomPaint(
                    size: const Size(140, 140),
                    painter: _DotPatternPainter(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({
    required this.entranceController,
    required this.colorScheme,
    required this.onPressed,
  });

  final AnimationController entranceController;
  final ColorScheme colorScheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      animation: entranceController,
      interval: const Interval(0.15, 0.5, curve: Curves.easeOutBack),
      slideOffset: 16,
      child: Material(
        color: colorScheme.onPrimary.withValues(alpha: 0.22),
        borderRadius: AppRadius.radiusFull,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.radiusFull,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'New',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.entranceController,
    required this.colorScheme,
    required this.totalGroups,
    required this.totalMembers,
  });

  final AnimationController entranceController;
  final ColorScheme colorScheme;
  final int? totalGroups;
  final int? totalMembers;

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      animation: entranceController,
      interval: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
      slideOffset: 18,
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              icon: Icons.group_work_rounded,
              label: 'Groups',
              value: totalGroups,
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatPill(
              icon: Icons.people_alt_rounded,
              label: 'People',
              value: totalMembers,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final int? value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.14),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onPrimary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value == null ? '—' : value.toString(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
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

// ═════════════════════════════════════════════════════════════════════════════
// Group card — rich card with avatar, member stack, admin badge
// ═════════════════════════════════════════════════════════════════════════════

class _GroupCard extends StatefulWidget {
  const _GroupCard({
    required this.group,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final Group group;
  final Color color;
  final bool isDark;
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
    final group = widget.group;
    final isAdmin = group.createdBy.isNotEmpty &&
        group.groupAdmin.id == group.createdBy;

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
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadius.radiusXxl,
            boxShadow:
                widget.isDark ? AppShadows.smDark : AppShadows.smLight,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusXxl,
            child: Column(
              children: [
                // ── Top accent strip ───────────────────────────────────────
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // ── Body ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      _GroupAvatar(
                        group: group,
                        color: widget.color,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.groupName,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  _AdminBadge(color: widget.color),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(group.createdAt),
                                  style: AppTextStyles.caption.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                // ── Footer: member stack + count ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      _MemberAvatarStack(
                        members: group.members,
                        fallbackColor: widget.color,
                        surfaceColor: colorScheme.surface,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (group.groupPicture != null)
                        Icon(
                          Icons.photo_camera_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Leading avatar for a group card. Shows the group photo when available,
/// otherwise a gradient circle with the group's initial.
class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group, required this.color});

  final Group group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final picture = group.groupPicture;
    final initial = group.groupName.isNotEmpty
        ? group.groupName.characters.first.toUpperCase()
        : '';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: picture != null && picture.isNotEmpty
          ? Image.network(
              picture,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => _initialAvatar(initial),
            )
          : _initialAvatar(initial),
    );
  }

  Widget _initialAvatar(String initial) {
    return Center(
      child: initial.isEmpty
          ? const Icon(Icons.group_rounded, color: Colors.white, size: 26)
          : Text(
              initial,
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
    );
  }
}

/// Overlapping avatar stack showing up to 4 member profile pictures or
/// initials, with a "+N" overflow indicator.
class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({
    required this.members,
    required this.fallbackColor,
    required this.surfaceColor,
  });

  final List<GroupMember> members;
  final Color fallbackColor;
  final Color surfaceColor;

  static const double _avatarSize = 28.0;
  static const double _overlap = 18.0;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    final visible = members.take(4).toList();
    final overflow = members.length - visible.length;
    final stackWidth =
        (visible.length - 1) * _overlap + _avatarSize + (overflow > 0 ? _overlap : 0);

    return SizedBox(
      width: stackWidth,
      height: _avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * _overlap,
              child: _MemberAvatar(
                member: visible[i],
                index: i,
                surfaceColor: surfaceColor,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * _overlap,
              child: _OverflowAvatar(
                count: overflow,
                surfaceColor: surfaceColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.member,
    required this.index,
    required this.surfaceColor,
  });

  final GroupMember member;
  final int index;
  final Color surfaceColor;

  static const _avatarColors = [
    AppColors.chartTeal,
    AppColors.chartBlue,
    AppColors.chartPurple,
    AppColors.chartOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final picture = member.profilePicture;
    final initial = _memberInitial(member);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _avatarColors[index % _avatarColors.length],
        border: Border.all(color: surfaceColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: picture != null && picture.isNotEmpty
          ? Image.network(
              picture,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initial(initial),
            )
          : _initial(initial),
    );
  }

  Widget _initial(String initial) {
    return Center(
      child: Text(
        initial,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }

  String _memberInitial(GroupMember m) {
    final source = (m.displayName?.isNotEmpty ?? false)
        ? m.displayName!
        : (m.fullName.isNotEmpty ? m.fullName : m.email);
    return source.isNotEmpty ? source.characters.first.toUpperCase() : '?';
  }
}

class _OverflowAvatar extends StatelessWidget {
  const _OverflowAvatar({
    required this.count,
    required this.surfaceColor,
  });

  final int count;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: surfaceColor, width: 2),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: AppTextStyles.labelSmall.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.radiusFull,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            'Admin',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Loading skeleton
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
    final highlight = widget.colorScheme.surfaceContainerHighest
        .withValues(alpha: 0.9);

    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: AppRadius.radiusXxl,
        boxShadow: AppShadows.cardShadow(Theme.of(context).brightness),
        border: Border.all(
          color: widget.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.radiusXxl,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            final t = _shimmerController.value;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      _SkeletonBox(size: 56, radius: AppRadius.radiusLg, color: base),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBox(width: 160, height: 16, color: base),
                            const SizedBox(height: AppSpacing.sm),
                            _SkeletonBox(width: 100, height: 12, color: base),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Shimmer sweep.
                Positioned.fill(
                  child: DecoratedBox(
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
                  ),
                ),
              ],
            );
          },
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
          // Floating icon cluster.
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
          // Gentle independent float for each satellite icon.
          final floatA = math.sin(t * 2 * math.pi) * 8;
          final floatB = math.sin(t * 2 * math.pi + 1.2) * 6;
          final floatC = math.sin(t * 2 * math.pi + 2.4) * 7;
          final rotate = t * 2 * math.pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Central gradient disc.
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
              // Orbiting satellites.
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
              'Couldn\'t load groups',
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

// ═════════════════════════════════════════════════════════════════════════════
// Decorative dot pattern painter (for hero banner corner)
// ═════════════════════════════════════════════════════════════════════════════

class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 14.0;
    const dotRadius = 2.0;
    final paint = Paint()..color = color;

    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      color != oldDelegate.color;
}
