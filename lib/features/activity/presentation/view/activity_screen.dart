import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Activity tab for the app shell.
///
/// Shows a chronological feed of recent bills, payments and group updates.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
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
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('activity_screen'),
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
                  'Recent Activity',
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
                  final activity = _sampleActivities[index];
                  return StaggeredEntrance(
                    animation: _entranceController,
                    interval: Interval(
                      0.1 + (index * 0.07),
                      0.6 + (index * 0.07),
                      curve: Curves.easeOut,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ActivityTile(
                        title: activity['title']! as String,
                        subtitle: activity['subtitle']! as String,
                        amount: activity['amount'] as String?,
                        icon: activity['icon']! as IconData,
                        iconColor: activity['iconColor']! as Color,
                        timeAgo: activity['timeAgo']! as String,
                      ),
                    ),
                  );
                },
                childCount: _sampleActivities.length,
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

final List<Map<String, Object?>> _sampleActivities = [
  {
    'title': 'Grocery Shopping',
    'subtitle': 'Roommates',
    'amount': '\$85.40',
    'icon': Icons.shopping_cart_rounded,
    'iconColor': AppColors.success,
    'timeAgo': '2h ago',
  },
  {
    'title': 'Team Lunch',
    'subtitle': 'Office Lunch',
    'amount': '\$42.00',
    'icon': Icons.restaurant_rounded,
    'iconColor': AppColors.chartOrange,
    'timeAgo': '5h ago',
  },
  {
    'title': 'Payment from Alex',
    'subtitle': 'Roommates',
    'amount': '\$45.00',
    'icon': Icons.payments_rounded,
    'iconColor': AppColors.chartTealLight,
    'timeAgo': '1d ago',
  },
  {
    'title': 'New member joined',
    'subtitle': 'Weekend Trip',
    'amount': null,
    'icon': Icons.person_add_alt_1_rounded,
    'iconColor': AppColors.chartBlue,
    'timeAgo': '2d ago',
  },
];

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    this.amount,
    required this.icon,
    required this.iconColor,
    required this.timeAgo,
  });

  final String title;
  final String subtitle;
  final String? amount;
  final IconData icon;
  final Color iconColor;
  final String timeAgo;

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
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: AppRadius.radiusLg,
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (amount != null)
              Text(
                amount!,
                style: AppTextStyles.amountSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            Text(
              timeAgo,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
