import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/photo_preview.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../auth/presentation/view/welcome_screen.dart';
import 'appearance_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'payment_methods_screen.dart';

/// Profile tab — hero header card, user info, and settings rows.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.entrance});

  /// Optional entrance animation owned by the app shell.
  ///
  /// When provided, the shell drives the staggered content entrance and
  /// restarts it on every tab selection. When `null` the screen falls back to
  /// its own controller so it still animates when shown on its own.
  final Animation<double>? entrance;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  /// The entrance animation actually used by the staggered content. Prefers
  /// the shell-owned animation so tab switches replay the entrance.
  Animation<double> get _entrance => widget.entrance ?? _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    // When the shell owns the entrance animation it restarts it on each tab
    // selection, so the screen must not also drive its own controller.
    if (widget.entrance != null) return;
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(authActionProvider.notifier).signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentAppUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('profile_screen'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Page header label ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.screenHorizontal,
                  right: AppSpacing.screenHorizontal,
                  top: AppSpacing.pageTop,
                  bottom: AppSpacing.lg,
                ),
                child: Text(
                  'Profile',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),

          // ── Hero header card ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.05, 0.5, curve: Curves.easeOutCubic),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: userAsync.when(
                  loading: () => _HeaderCardSkeleton(isDark: isDark),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (user) => _ProfileHeaderCard(
                    fullName: user?.fullName ?? '',
                    displayName: user?.displayName,
                    email: user?.email ?? '',
                    phoneNumber: user?.phoneNumber,
                    profilePictureUrl: user?.profilePicture,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),

          // ── Account section ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
              child: _SectionLabel(label: 'Account'),
            ),
          ),
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.18, 0.63, curve: Curves.easeOutCubic),
              child: _SettingsGroup(
                isDark: isDark,
                colorScheme: colorScheme,
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Edit Profile',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                  _SettingsItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Payment Methods',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PaymentMethodsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── Preferences section ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
              child: _SectionLabel(label: 'Preferences'),
            ),
          ),
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.28, 0.73, curve: Curves.easeOutCubic),
              child: _SettingsGroup(
                isDark: isDark,
                colorScheme: colorScheme,
                items: [
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    label: 'Appearance',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AppearanceScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── Support section ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
              child: _SectionLabel(label: 'Support'),
            ),
          ),
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.38, 0.83, curve: Curves.easeOutCubic),
              child: _SettingsGroup(
                isDark: isDark,
                colorScheme: colorScheme,
                items: [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── Sign out ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              animation: _entrance,
              interval: const Interval(0.45, 0.9, curve: Curves.easeOutCubic),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  children: [
                    _SignOutTile(
                      isDark: isDark,
                      colorScheme: colorScheme,
                      onTap: _confirmSignOut,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // bottom breathing room
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero header card
// ─────────────────────────────────────────────────────────────────────────────

/// [Hero] tag shared by the header avatar and the full-screen photo preview so
/// the image flies between the two when the avatar is tapped.
const _profileAvatarHeroTag = 'profile-avatar-hero';

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.fullName,
    required this.email,
    required this.isDark,
    required this.colorScheme,
    this.displayName,
    this.phoneNumber,
    this.profilePictureUrl,
  });

  final String fullName;
  final String? displayName;
  final String email;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final bool isDark;
  final ColorScheme colorScheme;

  // Derive initials (up to 2 letters) from the full name.
  String get _initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool get _hasPhoto =>
      profilePictureUrl != null && profilePictureUrl!.isNotEmpty;

  /// Tapping the avatar opens the photo preview. When the user has no photo,
  /// the preview shows their initials instead.
  void _onAvatarTap(BuildContext context) {
    showPhotoPreview(
      context,
      imageUrl: profilePictureUrl,
      initials: _initials,
      heroTag: _hasPhoto ? _profileAvatarHeroTag : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? AppColors.darkPrimaryGradient
        : AppColors.lightPrimaryGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.radiusXxl,
        boxShadow: isDark
            ? AppShadows.primaryGlowDark
            : AppShadows.primaryGlowLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          // ── Avatar + name/email row ────────────────────────────────────────
          Row(
            children: [
              _Avatar(
                initials: _initials,
                profilePictureUrl: profilePictureUrl,
                isDark: isDark,
                heroTag: _profileAvatarHeroTag,
                onTap: () => _onAvatarTap(context),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName?.isNotEmpty == true
                          ? displayName!
                          : fullName,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withValues(alpha: 0.82),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        phoneNumber!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Divider ───────────────────────────────────────────────────────
          Container(
            height: 1,
            color: AppColors.white.withValues(alpha: 0.2),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Member since ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Tabora Member',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatefulWidget {
  const _Avatar({
    required this.initials,
    required this.isDark,
    this.profilePictureUrl,
    this.heroTag,
    this.onTap,
  });

  final String initials;
  final String? profilePictureUrl;
  final bool isDark;
  final Object? heroTag;
  final VoidCallback? onTap;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _pressed = false;

  bool get _hasPhoto =>
      widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    const size = 72.0;

    Widget content = _hasPhoto
        ? Image.network(
            widget.profilePictureUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _InitialsLabel(initials: widget.initials),
          )
        : _InitialsLabel(initials: widget.initials);

    // Only the photo participates in the Hero flight, so the thumbnail's
    // circular clip is handed to the preview's shuttle during the transition.
    if (_hasPhoto && widget.heroTag != null) {
      content = Hero(tag: widget.heroTag!, child: content);
    }

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.22),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.45),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (widget.onTap == null) return avatar;

    return Semantics(
      button: true,
      label: _hasPhoto ? 'View profile photo' : 'View profile',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: avatar,
        ),
      ),
    );
  }
}

class _InitialsLabel extends StatelessWidget {
  const _InitialsLabel({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.titleLarge.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header skeleton (loading state)
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCardSkeleton extends StatelessWidget {
  const _HeaderCardSkeleton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: AppRadius.radiusXxl,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings group card
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.items,
    required this.isDark,
    required this.colorScheme,
  });

  final List<_SettingsItem> items;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.35 : 0.6,
            ),
          ),
          boxShadow: AppShadows.cardShadow(
            isDark ? Brightness.dark : Brightness.light,
          ),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _SettingsRow(
                icon: items[i].icon,
                label: items[i].label,
                colorScheme: colorScheme,
                onTap: items[i].onTap ?? () {},
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpacing.screenHorizontal + 40,
                  endIndent: 0,
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.3 : 0.5,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign out tile — destructive styling, standalone
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: isDark ? 0.2 : 0.15),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusLg,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(
                      alpha: isDark ? 0.35 : 0.4,
                    ),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Sign Out',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.error.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
