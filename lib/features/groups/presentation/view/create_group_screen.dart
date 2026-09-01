import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';

/// Create Group screen.
///
/// Lets the user start a new group by giving it a name, an optional photo,
/// and adding members. Designed to be pushed on top of the app shell.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with TickerProviderStateMixin {
  static const int _maxGroupNameLength = 30;
  static const int _maxMembers = 20;

  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  late final AnimationController _entrance;
  late final AnimationController _ambient;

  final List<_Member> _members = [
    _Member(
      name: 'Bikram Karki',
      phone: '9841 23\u2022\u2022\u2022\u2022',
      email: 'bikram.karki@email.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=Bikram+Karki',
      isCurrentUser: true,
      role: _MemberRole.admin,
    ),
    _Member(
      name: 'Anisha Malla',
      phone: '9812 34\u2022\u2022\u2022\u2022',
      email: 'anisha.malla@email.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=Anisha+Malla',
      role: _MemberRole.member,
    ),
    _Member(
      name: 'Sujan Rijal',
      phone: '9867 45\u2022\u2022\u2022\u2022',
      email: 'sujan.rijal@email.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=Sujan+Rijal',
      role: _MemberRole.member,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _entrance.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _removeMember(_Member member) {
    setState(() => _members.removeWhere((m) => m.name == member.name));
  }

  void _onCreateGroup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Create group action triggered.')),
    );
  }

  List<_Member> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _members;
    return _members.where((m) {
      return m.name.toLowerCase().contains(query) ||
          m.phone.contains(query) ||
          m.email.toLowerCase().contains(query);
    }).toList();
  }

  Widget _staggered(
    Widget child,
    double start,
    double end, {
    double slide = 24,
  }) {
    return StaggeredEntrance(
      animation: _entrance,
      interval: Interval(start, end, curve: Curves.easeOutCubic),
      slideOffset: slide,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _staggered(_buildHeader(colorScheme, isDark), 0.0, 0.14),
              const SizedBox(height: AppSpacing.xxl),
              _staggered(_buildPhotoPicker(colorScheme), 0.08, 0.22),
              const SizedBox(height: AppSpacing.sm),
              _staggered(_buildPhotoLabel(colorScheme), 0.12, 0.26),
              const SizedBox(height: AppSpacing.xxxl),
              _staggered(_buildGroupNameHeader(colorScheme), 0.24, 0.36),
              const SizedBox(height: AppSpacing.xs),
              _staggered(_buildGroupNameField(colorScheme), 0.28, 0.40),
              const SizedBox(height: AppSpacing.xs),
              _staggered(_buildNameHint(colorScheme), 0.32, 0.44),
              const SizedBox(height: AppSpacing.xxxl),
              _staggered(_buildMembersHeader(colorScheme), 0.40, 0.52),
              const SizedBox(height: AppSpacing.xs),
              _staggered(_buildSearchField(colorScheme), 0.44, 0.56),
              const SizedBox(height: AppSpacing.md),
              _buildMembersList(colorScheme, isDark),
              const SizedBox(height: AppSpacing.md),
              _staggered(_buildAddMoreCard(colorScheme), 0.74, 0.86),
              const SizedBox(height: AppSpacing.xxxl),
              _staggered(_buildCreateButton(colorScheme, isDark), 0.80, 0.92),
              const SizedBox(height: AppSpacing.md),
              _staggered(_buildCancelButton(colorScheme), 0.84, 0.96),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnimatedTapScale(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: isDark ? AppShadows.xsDark : AppShadows.xsLight,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: colorScheme.onSurface,
              size: 18,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Create Group',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Create a group and add members to get started',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildPhotoPicker(ColorScheme colorScheme) {
    return Center(
      child: _AnimatedTapScale(
        onTap: () {},
        child: SizedBox(
          width: 146,
          height: 146,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _DashedCircle(
                color: colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, child) {
                      final pulse =
                          1 + 0.02 * (1 - math.cos(math.pi * 2 * _ambient.value));
                      return Transform.scale(scale: pulse, child: child);
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group_outlined,
                        color: colorScheme.primary,
                        size: 44,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: colorScheme.onPrimary,
                    size: 12,
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoLabel(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Add Group Photo',
          style: AppTextStyles.titleMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          'Optional',
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGroupNameHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.group_outlined,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Group Name',
          style: AppTextStyles.labelLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupNameField(ColorScheme colorScheme) {
    return TextField(
      controller: _nameController,
      focusNode: _nameFocus,
      textInputAction: TextInputAction.done,
      maxLength: _maxGroupNameLength,
      decoration: InputDecoration(
        hintText: 'e.g. Trip to Pokhara',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (context, value, _) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${value.text.length}/$_maxGroupNameLength',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
        suffixIconConstraints: const BoxConstraints.tightFor(
          width: 64,
          height: 24,
        ),
        counter: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNameHint(ColorScheme colorScheme) {
    return Text(
      'Choose a name that helps everyone recognize the group.',
      style: AppTextStyles.bodySmall.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMembersHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.group_add_outlined,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Add Members',
          style: AppTextStyles.labelLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: AppRadius.radiusFull,
          ),
          child: Text(
            '${_members.length}/$_maxMembers',
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      textInputAction: TextInputAction.search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search by phone number or email',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
        suffixIcon: _AnimatedTapScale(
          onTap: () {},
          child: Center(
            child: Icon(
              Icons.perm_contact_calendar_outlined,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints.tightFor(
          width: 44,
          height: 44,
        ),
      ),
    );
  }

  Widget _buildMembersList(ColorScheme colorScheme, bool isDark) {
    final members = _filteredMembers;
    return Column(
      children: [
        for (var i = 0; i < members.length; i++)
          StaggeredEntrance(
            animation: _entrance,
            interval: Interval(
              0.52 + (i * 0.05),
              0.66 + (i * 0.05),
              curve: Curves.easeOutCubic,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.md,
              ),
              child: _buildMemberTile(members[i], colorScheme, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberTile(_Member member, ColorScheme colorScheme, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: AppSpacing.cardPaddingSymmetric,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.55),
                colorScheme.primaryContainer.withValues(alpha: 0.25),
              ],
            ),
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(member, colorScheme),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (member.isCurrentUser) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _Badge(
                            label: 'You',
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.primaryContainer,
                          ),
                        ],
                        if (!member.isCurrentUser) const SizedBox(width: 28),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildContactRow(
                      icon: Icons.phone,
                      text: member.phone,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildContactRow(
                      icon: Icons.email,
                      text: member.email,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Badge(
                label: member.isAdmin ? 'Admin' : 'Member',
                color: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
        if (!member.isAdmin)
          Positioned(
            top: -6,
            right: -6,
            child: _AnimatedTapScale(
              onTap: () => _removeMember(member),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: AppShadows.smLight,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(_Member member, ColorScheme colorScheme) {
    final url = member.avatarUrl;
    final initials = _initials(member.name);
    const double size = 52;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer gradient ring.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            // Inner photo / fallback.
            child: ClipOval(
              child: url != null && url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _AvatarFallback(
                          initials: initials,
                          colorScheme: colorScheme,
                        );
                      },
                    )
                  : _AvatarFallback(
                      initials: initials,
                      colorScheme: colorScheme,
                    ),
            ),
          ),
          // Admin crown badge — clean white circle with primary crown.
          if (member.isAdmin)
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.workspace_premium,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  Widget _buildAddMoreCard(ColorScheme colorScheme) {
    return _AnimatedTapScale(
      onTap: () {},
      child: _DashedRoundedBorder(
        color: colorScheme.primary.withValues(alpha: 0.55),
        radius: AppRadius.lg,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.55),
                colorScheme.primaryContainer.withValues(alpha: 0.25),
              ],
            ),
            borderRadius: AppRadius.radiusLg,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg + 4,
            vertical: AppSpacing.lg + 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Line 1: icon + title, centered.
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Add More Members',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Line 2: subtitle, centered.
              Text(
                'Search or invite more people to your group',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(ColorScheme colorScheme, bool isDark) {
    return _AnimatedTapScale(
      onTap: _onCreateGroup,
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (context, child) {
          final pulse = (1 - math.cos(math.pi * 2 * _ambient.value)) * 0.5;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusMd,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: 0.15 + 0.40 * pulse,
                  ),
                  blurRadius: 6 + 20 * pulse,
                  spreadRadius: 1 + 2 * pulse,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: AppRadius.radiusMd,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group,
                color: colorScheme.onPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Create Group',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(ColorScheme colorScheme) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: Text(
          'Cancel',
          style: AppTextStyles.button.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _Member {
  const _Member({
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl,
    this.isCurrentUser = false,
    this.role = _MemberRole.member,
  });

  final String name;
  final String phone;
  final String email;
  final String? avatarUrl;
  final bool isCurrentUser;
  final _MemberRole role;

  bool get isAdmin => role == _MemberRole.admin;
}

enum _MemberRole { admin, member }

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
    required this.colorScheme,
  });

  final String initials;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnimatedTapScale extends StatefulWidget {
  const _AnimatedTapScale({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<_AnimatedTapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: widget.child,
      ),
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({
    required this.child,
    required this.color,
  });

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedCirclePainter(color: color),
      child: child,
    );
  }
}

class _DashedRoundedBorder extends StatelessWidget {
  const _DashedRoundedBorder({
    required this.child,
    required this.color,
    required this.radius,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: color,
        radius: radius,
      ),
      child: child,
    );
  }
}

Path _dashPath(Path source, double dash, double gap) {
  final dest = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final length = math.min(dash, metric.length - distance);
      dest.addPath(metric.extractPath(distance, distance + length), Offset.zero);
      distance += dash + gap;
    }
  }
  return dest;
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    const strokeWidth = 1.5;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - strokeWidth / 2;
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final dashed = _dashPath(path, dash, gap);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color;
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.0;
    const gap = 3.0;
    const strokeWidth = 0.8;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dash, gap);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
