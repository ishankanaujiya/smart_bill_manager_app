import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_system.dart';
import '../../../../core/presentation/app_shell.dart';
import '../../../users/domain/entities/app_user.dart';
import '../state/auth_providers.dart';
import '../widget/auth_header.dart';
import '../widget/auth_text_field.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMsg),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
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
                      const RegistrationStepIndicator(currentStep: 2),

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
class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({
    required this.initials,
    required this.color,
  });

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.radiusXl,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
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
