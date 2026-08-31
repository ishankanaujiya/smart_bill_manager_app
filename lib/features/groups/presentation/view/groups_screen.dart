import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Groups tab for the app shell.
///
/// Lists the user's groups and provides a quick action to create a new one.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
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
    await Future.delayed(const Duration(milliseconds: 120));
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

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('groups_screen'),
        slivers: [
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entranceController,
              interval: const Interval(0.0, 0.55, curve: Curves.easeOut),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.pageTop,
                ),
                child: Text(
                  'My Groups',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = _sampleGroups[index];
                  return StaggeredEntrance(
                    animation: _entranceController,
                    interval: Interval(
                      0.1 + (index * 0.07),
                      0.6 + (index * 0.07),
                      curve: Curves.easeOut,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _GroupListTile(
                        name: group['name'] as String,
                        members: group['members'] as int,
                        total: group['total'] as String,
                        color: group['color'] as Color,
                      ),
                    ),
                  );
                },
                childCount: _sampleGroups.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 96),
          ),
        ],
      ),
    );
  }
}

final List<Map<String, Object>> _sampleGroups = [
  {
    'name': 'Roommates',
    'members': 4,
    'total': '\$1,250.00',
    'color': AppColors.chartTealLight,
  },
  {
    'name': 'Office Lunch',
    'members': 6,
    'total': '\$840.50',
    'color': AppColors.chartOrange,
  },
  {
    'name': 'Weekend Trip',
    'members': 3,
    'total': '\$2,100.00',
    'color': AppColors.chartBlue,
  },
  {
    'name': 'Football Team',
    'members': 8,
    'total': '\$320.00',
    'color': AppColors.chartPurple,
  },
];

class _GroupListTile extends StatelessWidget {
  const _GroupListTile({
    required this.name,
    required this.members,
    required this.total,
    required this.color,
  });

  final String name;
  final int members;
  final String total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: AppSpacing.listTilePadding,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: AppRadius.radiusLg,
          ),
          child: Icon(
            Icons.group_rounded,
            color: color,
          ),
        ),
        title: Text(
          name,
          style: AppTextStyles.bodyLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$members members',
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          total,
          style: AppTextStyles.amountSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
