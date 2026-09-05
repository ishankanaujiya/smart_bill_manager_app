import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/presentation/app_shell.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../users/domain/entities/app_user.dart';
import '../state/auth_providers.dart';
import '../widget/auth_header.dart';
import '../widget/auth_text_field.dart';
import '../widget/profile_photo_bottom_sheet.dart';
import '../widget/registration_step_indicator.dart';
import 'registration_done_screen.dart';

/// Registration step 3 — set up the user profile.
///
/// Allows picking an avatar colour, optionally uploading a photo, and setting
/// a display name that will be shown to other group members.
///
/// When the user presses "Finish setup", the Firebase Auth account is created
/// and the user data is stored in the Firestore "Users" collection.
class RegistrationProfileScreen extends ConsumerStatefulWidget {
  const RegistrationProfileScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.password,
    this.partialUser,
  });

  final String fullName;
  final String email;
  final String phoneNumber;

  /// Password from the Details screen. Required for email/password
  /// registration. `null` when completing a Google sign-in profile.
  final String? password;

  /// Partial user data from Google sign-in. When non-null, this screen is
  /// being used to complete a Google user's profile rather than a fresh
  /// email/password registration.
  final AppUser? partialUser;

  @override
  ConsumerState<RegistrationProfileScreen> createState() =>
      _RegistrationProfileScreenState();
}

class _RegistrationProfileScreenState
    extends ConsumerState<RegistrationProfileScreen>
    with TickerProviderStateMixin {
  // ── Form state ──
  final _displayNameController = TextEditingController();
  final _displayNameFocus = FocusNode();
  final _displayNameFieldKey = GlobalKey<AuthTextFieldState>();

  // ── Avatar state ──
  final _colors = AppColors.chartColorsDark.sublist(0, 5);
  int _selectedColorIndex = 0;

  // ── Profile photo state ──
  String? _profilePhotoPath;
  bool _isPicking = false;

  // ── Entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
      ),
    );

    _displayNameController.text = widget.fullName;

    _startEntrance();
  }

  Future<void> _startEntrance() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _entranceController.forward();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _displayNameFocus.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _displayNameController.text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  Future<void> _onPickProfilePhoto() async {
    if (_isPicking) return;

    final option = await ProfilePhotoBottomSheet.show(
      context,
      showRemoveOption: _profilePhotoPath != null,
    );
    if (option == null || !mounted) return;

    switch (option) {
      case ProfilePhotoOption.remove:
        setState(() => _profilePhotoPath = null);
      case ProfilePhotoOption.camera:
      case ProfilePhotoOption.gallery:
        await _pickImageFromSource(option);
    }
  }

  Future<void> _pickImageFromSource(ProfilePhotoOption option) async {
    // Guard against concurrent picker invocations — Android only allows
    // one activity-result at a time. This flag is internal only and does
    // NOT drive any UI loading state; the picker has its own native UI.
    _isPicking = true;

    try {
      final source = option == ProfilePhotoOption.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      final xFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (xFile != null) {
        setState(() => _profilePhotoPath = xFile.path);
      }
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _onFinish() async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) {
      setState(() {});
      _displayNameFieldKey.currentState?.shake();
      _displayNameFocus.requestFocus();
      return;
    }

    final authAction = ref.read(authActionProvider.notifier);
    final displayName = name.isEmpty ? widget.fullName : name;

    // ── Google sign-in profile completion ──
    if (widget.partialUser != null) {
      final success = await authAction.completeGoogleProfile(
        partialUser: widget.partialUser!,
        fullName: widget.fullName,
        phoneNumber: widget.phoneNumber,
        displayName: displayName,
        profilePicturePath: _profilePhotoPath,
      );

      if (!mounted) return;

      if (success) {
        _navigateToDone(displayName);
      } else {
        _showError();
      }
      return;
    }

    // ── Email/password registration ──
    if (widget.password == null) {
      _showError('Missing password. Please restart registration.');
      return;
    }

    final success = await authAction.completeRegistration(
      fullName: widget.fullName,
      email: widget.email,
      password: widget.password!,
      phoneNumber: widget.phoneNumber,
      displayName: displayName,
      profilePicturePath: _profilePhotoPath,
    );

    if (!mounted) return;

    if (success) {
      _navigateToDone(displayName);
    } else {
      _showError();
    }
  }

  void _navigateToDone(String displayName) {
    if (widget.partialUser != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AppShell()),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegistrationDoneScreen(
          fullName: displayName,
          email: widget.email,
          phoneNumber: widget.phoneNumber,
        ),
      ),
    );
  }

  void _showError([String? message]) {
    final state = ref.read(authActionProvider);
    final errorMsg = message ??
        (state is AuthActionError ? state.message : 'Registration failed.');

    AppSnackBar.show(
      context,
      title: 'Could not finish setup',
      message: errorMsg,
      type: AppSnackBarType.error,
    );
    ref.read(authActionProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarColor = _colors[_selectedColorIndex];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.md),

                      // Step indicator
                      const RegistrationStepIndicator(currentStep: 1),

                      const SizedBox(height: AppSpacing.xxl),

                      // Content
                      SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthHeader(
                                animation: _entranceController,
                                title: 'Set up your profile',
                                subtitle:
                                    "This is how you'll appear inside your groups.",
                              ),

                              const SizedBox(height: AppSpacing.xxxl),

                              // Avatar with camera badge
                              Center(
                                child: _AvatarWithBadge(
                                  initials: _initials,
                                  color: avatarColor,
                                  photoPath: _profilePhotoPath,
                                  isUploading: ref.watch(authActionProvider)
                                      is AuthActionLoading,
                                  onTap: _onPickProfilePhoto,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Colour picker
                              _ColorPicker(
                                colors: _colors,
                                selectedIndex: _selectedColorIndex,
                                onSelect: (i) =>
                                    setState(() => _selectedColorIndex = i),
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Photo helper text
                              Center(
                                child: Text(
                                  'Or upload a photo using the camera icon above — you can always change this later.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxxl),

                              // Display name
                              Text(
                                'Display name',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              AuthTextField(
                                key: _displayNameFieldKey,
                                controller: _displayNameController,
                                focusNode: _displayNameFocus,
                                hint: 'Display name',
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.done,
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 22,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onChanged: () => setState(() {}),
                                onSubmitted: (_) => _onFinish(),
                              ),

                              const SizedBox(height: AppSpacing.sm),

                              Text(
                                'Shown on expenses and balances instead of your number',
                                style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxxl),

                              // Finish setup button
                              _FinishButton(
                                onPressed: _onFinish,
                                isLoading: ref.watch(authActionProvider)
                                    is AuthActionLoading,
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Skip for now
                              Center(
                                child: GestureDetector(
                                  onTap: _onFinish,
                                  child: Text(
                                    'Skip for now',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ]),
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

/// Large avatar placeholder with a small camera badge.
///
/// When [photoPath] is non-null, the selected image is displayed instead of
/// the initials and the avatar grows to a larger size to showcase the photo.
/// Tapping the avatar or badge opens the photo picker bottom sheet. A
/// loading overlay is shown only while the photo is being uploaded to
/// Cloudinary ([isUploading]).
class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({
    required this.initials,
    required this.color,
    this.photoPath,
    this.isUploading = false,
    this.onTap,
  });

  /// Avatar size used when no photo has been picked (initials only).
  static const double _compactSize = 100;

  /// Avatar size used once a photo has been picked.
  static const double _expandedSize = 140;

  /// Camera badge size — scales with the avatar.
  static const double _compactBadge = 36;
  static const double _expandedBadge = 42;

  final String initials;
  final Color color;
  final String? photoPath;
  final bool isUploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showOverlay = isUploading && photoPath != null;
    final hasPhoto = photoPath != null;
    final avatarSize = hasPhoto ? _expandedSize : _compactSize;
    final badgeSize = hasPhoto ? _expandedBadge : _compactBadge;

    Widget avatarContent;
    if (hasPhoto) {
      avatarContent = Image.file(
        File(photoPath!),
        width: avatarSize,
        height: avatarSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Initials(
          initials: initials,
          color: color,
          size: avatarSize,
        ),
      );
    } else {
      avatarContent = _Initials(
        initials: initials,
        color: color,
        size: avatarSize,
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: SizedBox(
        width: avatarSize + badgeSize / 2,
        height: avatarSize + badgeSize / 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Avatar
            GestureDetector(
              onTap: showOverlay ? null : onTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: hasPhoto ? null : color,
                  borderRadius: hasPhoto
                      ? AppRadius.radiusXxl
                      : AppRadius.radiusXl,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: hasPhoto ? 28 : 24,
                      offset: Offset(0, hasPhoto ? 10 : 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarContent,
              ),
            ),

            // Loading / uploading overlay
            if (showOverlay)
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: hasPhoto
                      ? AppRadius.radiusXxl
                      : AppRadius.radiusXl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Uploading…',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

            // Camera badge
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: showOverlay ? null : onTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isUploading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colorScheme.onSurface,
                            ),
                          )
                        : Icon(
                            hasPhoto
                                ? Icons.edit_outlined
                                : Icons.camera_alt,
                            size: hasPhoto ? 20 : 18,
                            color: colorScheme.onSurface,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Initials displayed when no profile photo has been picked.
class _Initials extends StatelessWidget {
  const _Initials({
    required this.initials,
    required this.color,
    required this.size,
  });

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color,
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.headlineLarge.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: size >= 130 ? 40 : 32,
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of circular colour swatches.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.colors,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Color> colors;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < colors.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: i == selectedIndex
                    ? Border.all(color: colorScheme.onSurface, width: 3)
                    : null,
                boxShadow: [
                  if (i == selectedIndex)
                    BoxShadow(
                      color: colors[i].withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-width "Finish setup" primary button with blurring background glow.
class _FinishButton extends StatefulWidget {
  const _FinishButton({required this.onPressed, this.isLoading = false});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  State<_FinishButton> createState() => _FinishButtonState();
}

class _FinishButtonState extends State<_FinishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blurController;
  late final Animation<double> _blur;

  @override
  void initState() {
    super.initState();
    _blurController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _blur = CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _blurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedBuilder(
        animation: _blur,
        builder: (context, child) {
          final pulse = (1 - math.cos(math.pi * 2 * _blur.value)) * 0.5;

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
        child: FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            textStyle: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: widget.isLoading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Text('Finish setup'),
        ),
      ),
    );
  }
}
