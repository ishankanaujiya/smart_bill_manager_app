import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../widget/balance_summary_card.dart';
import '../widget/group_preview_card.dart';
import '../widget/quick_action_button.dart';
import '../widget/recent_activity_tile.dart';

/// Home tab for the app shell.
///
/// Shows the user's balance summary, quick actions, groups and recent activity.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('home_screen'),
        slivers: [
          _buildAppBar(theme, colorScheme),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                const SizedBox(height: AppSpacing.sm),
                const BalanceSummaryCard(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildQuickActions(colorScheme),
                const SizedBox(height: AppSpacing.xxxl),
                _buildMyGroupsSection(theme, colorScheme),
                const SizedBox(height: AppSpacing.xxxl),
                _buildRecentActivitySection(theme, colorScheme),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      floating: true,
      toolbarHeight: 64,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Smart Bill Manager',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Badge(
            smallSize: 8,
            backgroundColor: colorScheme.error,
            child: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () {},
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuickActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Add Bill',
          color: colorScheme.primary,
        ),
        QuickActionButton(
          icon: Icons.group_add_rounded,
          label: 'New Group',
          color: Colors.orange.shade700,
        ),
        QuickActionButton(
          icon: Icons.payments_rounded,
          label: 'Settle Up',
          color: Colors.green.shade600,
        ),
        QuickActionButton(
          icon: Icons.bar_chart_rounded,
          label: 'Reports',
          color: Colors.blue.shade600,
        ),
      ],
    );
  }

  Widget _buildMyGroupsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Groups',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              GroupPreviewCard(
                name: 'Roommates',
                memberCount: 4,
                totalExpenses: '\$1,250.00',
                color: colorScheme.primary,
                icon: Icons.home_rounded,
              ),
              const SizedBox(width: 12),
              GroupPreviewCard(
                name: 'Office Lunch',
                memberCount: 6,
                totalExpenses: '\$840.50',
                color: Colors.orange.shade700,
                icon: Icons.restaurant_rounded,
              ),
              const SizedBox(width: 12),
              GroupPreviewCard(
                name: 'Weekend Trip',
                memberCount: 3,
                totalExpenses: '\$2,100.00',
                color: Colors.teal.shade600,
                icon: Icons.flight_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                RecentActivityTile(
                  title: 'Grocery Shopping',
                  subtitle: 'Roommates',
                  amount: '\$85.40',
                  icon: Icons.shopping_cart_rounded,
                  iconBackgroundColor: Colors.green.shade600,
                  timeAgo: '2h ago',
                ),
                const Divider(height: 20),
                RecentActivityTile(
                  title: 'Team Lunch',
                  subtitle: 'Office Lunch',
                  amount: '\$42.00',
                  icon: Icons.restaurant_rounded,
                  iconBackgroundColor: Colors.orange.shade700,
                  timeAgo: '5h ago',
                ),
                const Divider(height: 20),
                RecentActivityTile(
                  title: 'Hotel Booking',
                  subtitle: 'Weekend Trip',
                  amount: '\$320.00',
                  icon: Icons.hotel_rounded,
                  iconBackgroundColor: Colors.blue.shade600,
                  timeAgo: '1d ago',
                ),
                const Divider(height: 20),
                RecentActivityTile(
                  title: 'Payment from Alex',
                  subtitle: 'Roommates',
                  amount: '\$45.00',
                  icon: Icons.payments_rounded,
                  iconBackgroundColor: colorScheme.primary,
                  isPositive: true,
                  timeAgo: '2d ago',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
