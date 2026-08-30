import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/design_system.dart';
import '../../../dashboard/presentation/view/home_screen.dart';
import '../widget/registration_step_indicator.dart';

/// Registration step 4 — success and final call-to-action.
///
/// Shows a large success checkmark, a verified phone number card, and
/// primary/secondary actions to either create a group or go to the dashboard.
class RegistrationDoneScreen extends StatefulWidget {
  const RegistrationDoneScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  final String fullName;
  final String email;
  final String phoneNumber;

  @override
  State<RegistrationDoneScreen> createState() => _RegistrationDoneScreenState();
}

class _RegistrationDoneScreenState extends State<RegistrationDoneScreen>
    with TickerProviderStateMixin {
  // ── Entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOut),
      ),
    );
    _checkScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.75, curve: Curves.elasticOut),
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
                      const RegistrationStepIndicator(currentStep: 3),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Content
                      SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Success checkmark
                              ScaleTransition(
                                scale: _checkScale,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 40,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 56,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxxl),

                              // Title
                              Text(
                                "You're all set, ${widget.fullName}",
                                textAlign: TextAlign.center,
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: colorScheme.onSurface,
                                  fontSize: 29,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Subtitle
                              Text(
                                'Your account is verified and ready. Create a group to start splitting expenses with the people you spend with.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxxl),

                              // Verified phone card
                              _VerifiedPhoneCard(
                                phoneNumber: widget.phoneNumber,
                              ),

                              const SizedBox(height: AppSpacing.xxxl),

                              // Create group button
                              _PrimaryActionButton(
                                label: 'Create your first group',
                                onPressed: () {
                                  // TODO(group): Navigate to create group
                                  _goToDashboard();
                                },
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Dashboard link
                              GestureDetector(
                                onTap: _goToDashboard,
                                child: Text(
                                  'Take me to dashboard',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
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

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}

/// Card showing the verified phone number.
class _VerifiedPhoneCard extends StatelessWidget {
  const _VerifiedPhoneCard({required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusLg,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: AppRadius.radiusLg,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$phoneNumber verified',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Friends can now find you by this number',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary action button with blurring glow.
class _PrimaryActionButton extends StatefulWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton>
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
          onPressed: widget.onPressed,
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
          child: Text(widget.label),
        ),
      ),
    );
  }
}
