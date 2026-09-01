import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../auth/presentation/state/auth_providers.dart';
import '../../../users/domain/entities/app_user.dart';
import '../state/user_search_provider.dart';

/// Create Group screen.
///
/// Lets the user start a new group by giving it a name, an optional photo,
/// and adding members. Designed to be pushed on top of the app shell.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen>
    with TickerProviderStateMixin {
  static const int _maxGroupNameLength = 30;

  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  /// Path of the optional group photo picked from the gallery.
  String? _groupPhotoPath;

  /// Whether the photo is currently being picked / processed.
  bool _isPhotoLoading = false;

  late final AnimationController _entrance;
  late final AnimationController _ambient;

  /// The list of members currently added to the group.
  /// The current user is always the first entry (admin).
  final List<_Member> _members = [];

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
    _loadCurrentUser();
    _startEntrance();
  }

  /// Loads the currently signed-in user from Firestore and adds them as the
  /// admin member of the group.
  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final appUser =
          await ref.read(userRepositoryProvider).getUser(firebaseUser.uid);
      if (!mounted) return;

      setState(() {
        _members.insert(
          0,
          _Member.fromAppUser(
            appUser ??
                AppUser(
                  id: firebaseUser.uid,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  fullName: firebaseUser.displayName ?? '',
                  email: firebaseUser.email ?? '',
                  phoneNumber: null,
                  displayName: firebaseUser.displayName,
                  profilePicture: firebaseUser.photoURL,
                ),
            isCurrentUser: true,
            role: _MemberRole.admin,
          ),
        );
      });
    } catch (_) {
      // If Firestore fails, fall back to Firebase Auth data.
      if (!mounted) return;
      setState(() {
        _members.insert(
          0,
          _Member(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'You',
            phone: '—',
            email: firebaseUser.email ?? '',
            avatarUrl: firebaseUser.photoURL,
            isCurrentUser: true,
            role: _MemberRole.admin,
          ),
        );
      });
    }
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
    setState(() => _members.removeWhere((m) => m.id == member.id));
  }

  /// Opens the system gallery and lets the user pick a single image for the
  /// group photo. The selected file path is stored in [_groupPhotoPath] and
  /// the UI is rebuilt to display the image inside the picker card.
  ///
  /// The loading indicator is only shown **after** the user selects a photo
  /// — not while the gallery is open — so the "Uploading..." label matches
  /// the actual processing phase.
  Future<void> _pickGroupPhoto() async {
    if (_isPhotoLoading) return;

    final picker = ImagePicker();
    try {
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile == null) return; // user cancelled — no loading needed

      // Photo selected — now show the loading indicator while we process.
      if (!mounted) return;
      setState(() => _isPhotoLoading = true);

      // Brief processing delay so the loading animation is perceptible.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _groupPhotoPath = xFile.path;
        _isPhotoLoading = false;
      });
    } on Exception catch (_) {
      // Silently ignore — the picker may throw on devices without a gallery.
      if (!mounted) return;
      setState(() => _isPhotoLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the gallery. Please try again.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onCreateGroup() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Create group action triggered.')),
    );
  }

  /// Adds a searched [AppUser] to the members list if they aren't already
  /// added. Returns `true` if the member was added, `false` if they were
  /// already in the list.
  bool _addMember(AppUser user) {
    if (_members.any((m) => m.id == user.id)) return false;
    setState(() {
      _members.add(_Member.fromAppUser(user));
    });
    return true;
  }

  /// Whether the given user ID is already in the members list.
  bool _isMemberAdded(String userId) =>
      _members.any((m) => m.id == userId);

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
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _staggered(_buildHeader(colorScheme, isDark), 0.0, 0.14),
              const SizedBox(height: AppSpacing.xxl),
              _staggered(_buildPhotoPicker(colorScheme, isDark), 0.08, 0.22),
              const SizedBox(height: AppSpacing.xxxl),
              _staggered(_buildGroupNameHeader(colorScheme), 0.24, 0.36),
              const SizedBox(height: AppSpacing.xs),
              _staggered(_buildGroupNameField(colorScheme), 0.28, 0.40),
              const SizedBox(height: AppSpacing.xs),
              _staggered(_buildNameHint(colorScheme), 0.32, 0.44),
              const SizedBox(height: AppSpacing.xxl),
              _staggered(_buildMembersHeader(colorScheme), 0.40, 0.52),
              const SizedBox(height: AppSpacing.xs),
              _staggered(_buildSearchField(colorScheme), 0.44, 0.56),
              const SizedBox(height: AppSpacing.md),
              _buildSearchResults(colorScheme, isDark),
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

  Widget _buildPhotoPicker(ColorScheme colorScheme, bool isDark) {
    final pickerBg = colorScheme.primaryContainer.withValues(
      alpha: isDark ? 0.2 : 0.6,
    );
    final cardBg = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : colorScheme.primaryContainer.withValues(alpha: 0.3);

    final hasPhoto = _groupPhotoPath != null;
    final isLoading = _isPhotoLoading;

    return _AnimatedTapScale(
      onTap: isLoading ? null : _pickGroupPhoto,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: cardBg,
          borderRadius: AppRadius.radiusXxl,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left text content.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasPhoto ? Icons.check_circle_rounded : Icons.add,
                        color: hasPhoto
                            ? colorScheme.primary
                            : colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        hasPhoto ? 'Group Photo' : 'Add Group Photo',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    hasPhoto
                        ? 'Looking great! Tap to change the photo.'
                        : 'Add a photo to make your group more personal',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadius.radiusFull,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPhoto ? Icons.edit : Icons.auto_awesome,
                          color: colorScheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          hasPhoto ? 'Change' : 'Optional',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Right dashed circle picker.
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _DashedCircle(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    dash: 4.0,
                    gap: 3.0,
                    strokeWidth: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: ClipOval(
                          child: hasPhoto
                              ? Image.file(
                                  io.File(_groupPhotoPath!),
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: pickerBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.group_outlined,
                                    color: colorScheme.primary,
                                    size: 36,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Plus / edit badge.
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        hasPhoto ? Icons.edit : Icons.add,
                        color: colorScheme.onPrimary,
                        size: 14,
                      ),
                    ),
                  ),
                  // Camera badge.
                  Positioned(
                    bottom: -6,
                    right: 4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        hasPhoto ? Icons.camera_alt : Icons.camera_alt,
                        color: colorScheme.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  if (!hasPhoto) ...[
                    // Decorative image thumbnails on the right (only when
                    // no photo has been picked yet).
                    Positioned(
                      top: 18,
                      right: -28,
                      child: _buildThumbnail(colorScheme, isDark, size: 32),
                    ),
                    Positioned(
                      bottom: 12,
                      right: -22,
                      child: _buildThumbnail(colorScheme, isDark, size: 24),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
          // Loading overlay — covers the entire card with a frosted blur
          // and a centered animated indicator while the photo is being
          // picked / processed.
          if (isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppRadius.radiusXxl,
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 3,
                    sigmaY: 3,
                  ),
                  child: Container(
                    color: colorScheme.surface.withValues(alpha: 0.4),
                    alignment: Alignment.center,
                    child: _PhotoLoadingIndicator(
                      ambient: _ambient,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(
    ColorScheme colorScheme,
    bool isDark, {
    required double size,
  }) {
    return Transform.rotate(
      angle: (math.pi / 12) * (size == 32 ? 1 : -1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppRadius.radiusSm,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.3 : 0.6,
            ),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.radiusSm,
          child: Icon(
            Icons.image,
            color: colorScheme.primary.withValues(alpha: 0.5),
            size: size * 0.55,
          ),
        ),
      ),
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
          Icons.group_outlined,
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
        
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {});
        ref.read(userSearchProvider.notifier).search(value);
      },
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
        suffixIcon: _searchController.text.isNotEmpty
            ? _AnimatedTapScale(
                onTap: () {
                  _searchController.clear();
                  ref.read(userSearchProvider.notifier).reset();
                  setState(() {});
                },
                child: Center(
                  child: Icon(
                    Icons.close,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              )
            : _AnimatedTapScale(
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

  /// Builds the live search results panel that appears below the search
  /// field when the user types. Reads from the [userSearchProvider] and
  /// renders loading, empty, error, and success states.
  Widget _buildSearchResults(ColorScheme colorScheme, bool isDark) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return const SizedBox.shrink();

    final searchState = ref.watch(userSearchProvider);

    return switch (searchState) {
      UserSearchIdle() => const SizedBox.shrink(),
      UserSearchLoading() => _buildSearchLoading(colorScheme),
      UserSearchError(:final message) =>
        _buildSearchError(message, colorScheme),
      UserSearchSuccess(:final users) when users.isEmpty =>
        _buildSearchEmpty(colorScheme),
      UserSearchSuccess(:final users) =>
        _buildSearchResultList(users, colorScheme, isDark),
    };
  }

  Widget _buildSearchLoading(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Searching users...',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmpty(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 36,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No users found',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Try a different phone number or email',
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchError(String message, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.error,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultList(
    List<AppUser> users,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      children: [
        for (var i = 0; i < users.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildSearchResultTile(
              users[i],
              colorScheme,
              isDark,
              index: i,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultTile(
    AppUser user,
    ColorScheme colorScheme,
    bool isDark, {
    required int index,
  }) {
    final name = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : user.fullName;
    final initials = _initials(name);
    final isAdded = _isMemberAdded(user.id);

    return _AnimatedTapScale(
      onTap: isAdded ? null : () => _addMember(user),
      child: Container(
        padding: AppSpacing.cardPaddingSymmetric,
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : colorScheme.surface,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isAdded
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.2 : 0.5,
                  ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar — image or initials fallback.
            Container(
              width: 44,
              height: 44,
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
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: user.profilePicture != null &&
                        user.profilePicture!.isNotEmpty
                    ? Image.network(
                        user.profilePicture!,
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
            const SizedBox(width: AppSpacing.md),
            // Name + email.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Add / added status.
            if (isAdded)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Added',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 14,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Add',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(ColorScheme colorScheme, bool isDark) {
    final members = _members;
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
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
            color: isDark ? null : colorScheme.surface,
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.55),
                      colorScheme.primaryContainer.withValues(alpha: 0.25),
                    ],
                  )
                : null,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.25)
                  : colorScheme.outlineVariant,
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
    const double size = 56;

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
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl,
    this.isCurrentUser = false,
    this.role = _MemberRole.member,
  });

  /// Creates a [_Member] from an [AppUser] fetched from Firestore.
  factory _Member.fromAppUser(
    AppUser user, {
    bool isCurrentUser = false,
    _MemberRole role = _MemberRole.member,
  }) {
    final name = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : user.fullName;
    final phone = user.phoneNumber ?? '—';
    return _Member(
      id: user.id,
      name: name,
      phone: phone,
      email: user.email,
      avatarUrl: user.profilePicture,
      isCurrentUser: isCurrentUser,
      role: role,
    );
  }

  /// Firestore document ID — used to prevent duplicate members.
  final String id;
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

// ═════════════════════════════════════════════════════════════════════════════
// Photo loading indicator — a polished animated indicator shown while the
// group photo is being picked / processed.
// ═════════════════════════════════════════════════════════════════════════════

class _PhotoLoadingIndicator extends StatelessWidget {
  const _PhotoLoadingIndicator({
    required this.ambient,
    required this.colorScheme,
  });

  final AnimationController ambient;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Spinner rotation — driven by the shared ambient controller.
    final spin = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: ambient, curve: Curves.linear),
    );
    // Pulse — a gentle scale breathing effect.
    final pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: ambient, curve: Curves.easeInOutSine),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: ambient,
          builder: (context, child) {
            return Transform.scale(
              scale: pulse.value,
              child: Transform.rotate(
                angle: spin.value * 2 * math.pi,
                child: child,
              ),
            );
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(
              painter: _LoadingRingPainter(
                color: colorScheme.primary,
                trackColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Uploading...',
          style: AppTextStyles.labelSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Paints a circular loading ring with a 270° arc and rounded caps.
class _LoadingRingPainter extends CustomPainter {
  _LoadingRingPainter({
    required this.color,
    required this.trackColor,
  });

  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const startAngle = -math.pi / 2; // top
    const sweep = math.pi * 1.5; // 270°

    // Track (full circle, faint).
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Active arc.
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LoadingRingPainter old) =>
      old.color != color || old.trackColor != trackColor;
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
    this.dash = 6.0,
    this.gap = 4.0,
    this.strokeWidth = 1.5,
  });

  final Widget child;
  final Color color;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedCirclePainter(
        color: color,
        dash: dash,
        gap: gap,
        strokeWidth: strokeWidth,
      ),
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
  _DashedCirclePainter({
    required this.color,
    this.dash = 6.0,
    this.gap = 4.0,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
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
      old.color != color ||
      old.dash != dash ||
      old.gap != gap ||
      old.strokeWidth != strokeWidth;
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
