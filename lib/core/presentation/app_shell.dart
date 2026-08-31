import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/design_system.dart';
import '../../features/activity/presentation/view/activity_screen.dart';
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
  late final AnimationController _addPulseController;
  late final Animation<double> _barSlide;
  late final Animation<double> _barFade;

  static const _navHeight = 78.0;

  static const _pages = <Widget>[
    HomeScreen(),
    GroupsScreen(),
    CreateGroupScreen(),
    ActivityScreen(),
    ProfileScreen(),
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

    _addPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _addPulseController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
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
        addPulseAnimation: _addPulseController,
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
    required this.addPulseAnimation,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final ColorScheme colorScheme;
  final Animation<double> slideAnimation;
  final Animation<double> fadeAnimation;
  final Animation<double> addPulseAnimation;

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
                    _AddNavItem(
                      isSelected: currentIndex == 2,
                      onTap: () => onTap(2),
                      colorScheme: colorScheme,
                      pulseAnimation: addPulseAnimation,
                    ),
                    _NavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      hasNotification: true,
                      onTap: () => onTap(3),
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                    _NavItem(
                      index: 4,
                      currentIndex: currentIndex,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person_rounded,
                      hasNotification: true,
                      onTap: () => onTap(4),
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
    this.hasNotification = false,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool hasNotification;

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
              child: _NavIconWithDot(
                icon: isSelected ? activeIcon : icon,
                color: iconColor,
                hasNotification: hasNotification,
                isSelected: isSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconWithDot extends StatelessWidget {
  const _NavIconWithDot({
    required this.icon,
    required this.color,
    required this.hasNotification,
    required this.isSelected,
  });

  final IconData icon;
  final Color color;
  final bool hasNotification;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          color: color,
          size: 26,
        ),
        if (hasNotification)
          Positioned(
            right: -2,
            bottom: -1,
            child: _NotificationDot(animate: !isSelected),
          ),
      ],
    );
  }
}

class _AddNavItem extends StatefulWidget {
  const _AddNavItem({
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.pulseAnimation,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final Animation<double> pulseAnimation;

  @override
  State<_AddNavItem> createState() => _AddNavItemState();
}

class _AddNavItemState extends State<_AddNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _tapController.forward();
    await _tapController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.colorScheme.primary;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: widget.pulseAnimation,
        builder: (context, child) {
          final pulse =
              (1 - math.cos(math.pi * 2 * widget.pulseAnimation.value)) * 0.5;

          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primary,
                  AppColors.teal2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25 + 0.25 * pulse),
                  blurRadius: 14 + 10 * pulse,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _tapScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _tapScale.value,
                  child: child,
                );
              },
              child: Icon(
                Icons.add_rounded,
                size: 28,
                color: widget.colorScheme.onPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationDot extends StatefulWidget {
  const _NotificationDot({required this.animate});

  final bool animate;

  @override
  State<_NotificationDot> createState() => _NotificationDotState();
}

class _NotificationDotState extends State<_NotificationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NotificationDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _scale.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
