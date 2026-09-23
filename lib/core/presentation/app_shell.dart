import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/design_system.dart';
import '../../features/dashboard/presentation/view/home_screen.dart';
import '../../features/groups/presentation/view/create_group_screen.dart';
import '../../features/groups/presentation/view/groups_screen.dart';
import '../../features/profile/presentation/view/profile_screen.dart';

/// App shell shown after a successful sign-in.
///
/// Hosts the main content pages and renders a custom glass-morphism bottom
/// navigation bar that adapts to light and dark modes.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _entranceController;
  late final Animation<double> _barSlide;
  late final Animation<double> _barFade;

  static const _navHeight = 78.0;

  late final List<Widget> _pages = [
    HomeScreen(onNavigateToTab: _onTabSelected),
    GroupsScreen(),
    const SizedBox.shrink(),
    const ProfileScreen(),
  ];
  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );

    _barSlide = Tween<double>(begin: 64, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _barFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      _openCreateGroup();
      return;
    }
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _openCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateGroupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        isDark: isDark,
        colorScheme: colorScheme,
        slideAnimation: _barSlide,
        fadeAnimation: _barFade,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.colorScheme,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final ColorScheme colorScheme;
  final Animation<double> slideAnimation;
  final Animation<double> fadeAnimation;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: Listenable.merge([slideAnimation, fadeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, slideAnimation.value),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: bottomPadding + AppSpacing.sm,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            minWidth: 280,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.radiusFull,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                height: _AppShellState._navHeight - 6,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(
                    alpha: isDark ? 0.28 : 0.34,
                  ),
                  borderRadius: AppRadius.radiusFull,
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                    width: 1,
                  ),
                  boxShadow: isDark ? AppShadows.smDark : AppShadows.smLight,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _NavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_filled,
                      onTap: () => onTap(0),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    _NavItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.people_alt_outlined,
                      activeIcon: Icons.people_alt_rounded,
                      onTap: () => onTap(1),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    _NavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.add_to_photos_rounded,
                      activeIcon: Icons.group_add_rounded,
                      onTap: () => onTap(2),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    _NavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person_rounded,
                      onTap: () => onTap(3),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;

  bool get isSelected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: AnimatedScale(
          scale: isSelected ? 1.0 : 0.92,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: isSelected
                  ? BoxDecoration(
                      color: isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.18)
                          : colorScheme.onSurface.withValues(alpha: 0.10),
                      borderRadius: AppRadius.radiusFull,
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: iconColor,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

