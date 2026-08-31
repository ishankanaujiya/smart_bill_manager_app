import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Profile tab for the app shell.
///
/// Displays the current user summary and profile settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
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
        key: const PageStorageKey('profile_screen'),
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
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Morgan',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'alex.morgan@example.com',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
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
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _menuItems[index];
                  return StaggeredEntrance(
                    animation: _entranceController,
                    interval: Interval(
                      0.1 + (index * 0.07),
                      0.6 + (index * 0.07),
                      curve: Curves.easeOut,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ProfileMenuTile(
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        onTap: () {},
                      ),
                    ),
                  );
                },
                childCount: _menuItems.length,
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

final List<Map<String, Object>> _menuItems = [
  {'icon': Icons.account_balance_wallet_rounded, 'label': 'Payment Methods'},
  {'icon': Icons.notifications_rounded, 'label': 'Notifications'},
  {'icon': Icons.lock_rounded, 'label': 'Privacy & Security'},
  {'icon': Icons.palette_rounded, 'label': 'Appearance'},
  {'icon': Icons.help_outline_rounded, 'label': 'Help & Support'},
  {'icon': Icons.logout_rounded, 'label': 'Sign Out'},
];

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: AppSpacing.listTilePadding,
        leading: Icon(
          icon,
          color: colorScheme.primary,
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
